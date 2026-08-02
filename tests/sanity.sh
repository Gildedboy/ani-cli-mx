#!/bin/sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$repo_dir"

run_syntax_checks() {
    sh -n ani-cli-mx-core
    if command -v zsh >/dev/null 2>&1; then
        zsh -n ani-cli-mx-core
    fi
}

strip_ansi() {
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g'
}

run_debug_smoke() {
    output_file="$(mktemp)"
    clean_file="$(mktemp)"
    trap 'rm -f "$output_file" "$clean_file"' EXIT HUP INT TERM

    anidb_curl="${ANI_CLI_ANIDB_CURL:-}"
    if [ -z "$anidb_curl" ]; then
        for candidate in curl_firefox135 curl_chrome136 curl_chrome116 curl_ff117; do
            if command -v "$candidate" >/dev/null 2>&1; then
                anidb_curl="$(command -v "$candidate")"
                break
            fi
        done
    fi
    [ -n "$anidb_curl" ] || {
        printf 'Network playback smoke requires curl-impersonate for AniDB. Set ANI_CLI_ANIDB_CURL.\n' >&2
        return 1
    }

    for provider_case in 'jkanime:JKAnime' 'animeav1:AnimeAV1' 'animeflv:AnimeFLV' 'anidb:AniDB' 'animex:AnimeX'; do
        provider="${provider_case%%:*}"
        provider_label="${provider_case#*:}"
        timeout 120 env ANI_CLI_PLAYER=debug ANI_CLI_NO_DETACH=1 ANI_CLI_FAST_MODE=0 \
            ANI_CLI_PROBE_TIMEOUT=20 ANI_CLI_ANIDB_CURL="$anidb_curl" ./ani-cli-mx \
            --source "$provider" -S 1 -e 1 "one piece" >"$output_file" 2>&1 || {
            strip_ansi <"$output_file" >&2
            return 1
        }
        strip_ansi <"$output_file" >"$clean_file"
        grep -q "Fuente seleccionada:" "$clean_file"
        grep -q "$provider_label /" "$clean_file"
        grep -q "Enlace seleccionado:" "$clean_file"
        selected_url="$(sed -n '/^Enlace seleccionado:/{n;p;q;}' "$clean_file")"
        printf '%s\n' "$selected_url" | grep -qE '^https?://'
    done
}

run_continuous_toggle_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/continuous-functions.sh"
    played_file="$tmp_dir/played"
    sed -n '/^set_current_episode()/,/^toggle_close_previous_from_menu()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"

        current_episode_file="$tmp_dir/current-episode"
        continuous_state_file="$tmp_dir/continuous-state"
        continuous_worker_pid=""
        player_function="mpv"
        ep_list="1
2"
        ep_no="1"

        play_episode() {
            set_current_episode "$ep_no"
            printf '%s\n' "$ep_no" >>"$played_file"
            sleep 0.1 &
            player_pid=$!
        }

        set_current_episode "$ep_no"
        sleep 0.1 &
        player_pid=$!

        toggle_continuous_mode_from_menu >/dev/null 2>&1
        [ -n "$continuous_worker_pid" ]
        wait "$continuous_worker_pid"
        grep -qx "2" "$played_file"
    )

    rm -rf "$tmp_dir"
}

run_download_menu_smoke() {
    menu_options="$(sed -n '/^playback_menu_options()/,/^playback_menu_prompt()/p' ani-cli-mx-core)"
    printf '%s\n' "$menu_options" | grep -q 'descargar_episodio_actual'
    ! printf '%s\n' "$menu_options" | grep -q 'cambiar_calidad'
    ! grep -q '^[[:space:]]*cambiar_calidad)' ani-cli-mx-core
    grep -q 'download_dir="${ANI_CLI_DOWNLOAD_DIR:-$(default_download_dir)}"' ani-cli-mx-core
    grep -q "command -v yt-dlp" ani-cli-mx-core
}

run_windows_compat_smoke() {
    tmp_dir="$(mktemp -d)"
    powershell_args_file="$tmp_dir/powershell-args"
    local_app_data="$tmp_dir/local-app-data"
    if command -v cygpath >/dev/null 2>&1; then
        local_app_data_env="$(cygpath -w "$local_app_data")"
    else
        local_app_data_env="$local_app_data"
    fi
    mkdir -p "$tmp_dir/bin"
    cp /dev/null "$tmp_dir/bin/powershell.exe"
    chmod +x "$tmp_dir/bin/powershell.exe"
    printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$*" >"$POWERSHELL_ARGS_FILE"' >"$tmp_dir/bin/powershell.exe"
    version_output="$(env ANI_CLI_WINDOWS=1 ANI_CLI_NAME=ani-cli-mx \
        ANI_CLI_STATE_NAME=ani-cli-mx LOCALAPPDATA="$local_app_data_env" \
        ANI_CLI_PLAYER=debug ./ani-cli-mx-core -V)"

    [ "$version_output" = "1.4.0" ]
    [ -f "$local_app_data/ani-cli-mx/ani-hsts" ]
    grep -q 'GIT_INSTALL_ROOT' ani-cli-mx.cmd
    grep -q 'ANI_CLI_PACKAGE_MANAGER=scoop' ani-cli-mx.cmd
    grep -q 'ANI_CLI_STATE_NAME=ani-cli-mx' ani-cli-mx.cmd
    ! grep -qi 'System32.*bash.exe' ani-cli-mx.cmd

    env PATH="$tmp_dir/bin:$PATH" ANI_CLI_WINDOWS=1 ANI_CLI_PACKAGE_MANAGER=scoop \
        ANI_CLI_STATE_NAME=ani-cli-mx LOCALAPPDATA="$local_app_data_env" ANI_CLI_PLAYER=debug \
        POWERSHELL_ARGS_FILE="$powershell_args_file" ./ani-cli-mx-core -U
    grep -q 'scoop update ani-cli-mx' "$powershell_args_file"

    rm -rf "$tmp_dir"
}

run_search_diagnostic_smoke() {
    tmp_dir="$(mktemp -d)"
    output_file="$tmp_dir/output"
    funcs_file="$tmp_dir/search-diagnostic-functions.sh"
    sed -n '/^probe_search_endpoint()/,/^extract_with_ytdlp()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    if (
        # shellcheck disable=SC1090
        . "$funcs_file"
        resolver_timeout=1
        agent=test
        animeflv_refr=https://animeflv.invalid
        animeav1_refr=https://animeav1.invalid
        jkanime_refr=https://jkanime.invalid
        curl() {
            printf 'curl: (6) Could not resolve host: test.invalid\n' >&2
            return 6
        }
        die() {
            printf '%s\n' "$1" >&2
            exit 1
        }
        diagnose_empty_search "one+piece"
    ) >"$output_file" 2>&1; then
        printf 'Expected the simulated network failure to exit non-zero\n' >&2
        cat "$output_file" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    if ! grep -q 'No se pudo consultar AnimeAV1' "$output_file" ||
        ! grep -q 'Could not resolve host' "$output_file" ||
        ! grep -q 'No se pudo consultar AnimeFLV' "$output_file" ||
        ! grep -q 'Revisa DNS, firewall, proxy, antivirus o certificados TLS' "$output_file"; then
        cat "$output_file" >&2
        rm -rf "$tmp_dir"
        return 1
    fi
    rm -rf "$tmp_dir"
}

run_search_query_candidates_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/search-query-functions.sh"
    sed -n '/^normalize_romanized_text()/,/^normalize_match_key()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        [ "$(search_query_candidates_from_text baki)" = "baki" ]
        [ "$(search_query_candidates_from_text 'boku no hero')" = "boku+no+hero" ]
    )

    rm -rf "$tmp_dir"
}

run_language_sections_smoke() {
    menu_output="$(printf '%b\n' \
        'jkanime:one-piece\tOne Piece\tOne Piece [JKAnime]' \
        'anidb:one-piece-3880\tOne Piece\tOne Piece [AniDB]' \
        'animex:one-piece-p8k27\tOne Piece\tOne Piece [AnimeX]' |
        sed -n '/./p' | awk -F '\t' '
            {
                label = ($3 != "" ? $3 : $2)
                language = ($1 ~ /^(anidb|animex):/ ? "[ENGLISH]" : "[ESPAÑOL]")
                printf "%d\t%s\t%s %s\n", NR, $1, language, label
            }
        ')"
    printf '%s\n' "$menu_output" | grep -q '\[ESPAÑOL\].*JKAnime'
    printf '%s\n' "$menu_output" | grep -q '\[ENGLISH\].*AniDB'
    printf '%s\n' "$menu_output" | grep -q '\[ENGLISH\].*AnimeX'
}

run_anidb_provider_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/anidb-functions.sh"
    sed -n '/^find_anidb_curl_exe()/,/^pick_animeflv_language()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"

        show_ref_value_for_site() {
            case "$1" in
                "$2":*) printf '%s\n' "${1#"$2:"}" ;;
                *) return 1 ;;
            esac
        }
        emit_annotated_link_entry() {
            entry_url="$(printf '%s' "$1" | cut -d'>' -f2)"
            printf '%s\n' "$1"
            printf 'source >%s>%s\n' "$entry_url" "$2"
            printf 'site >%s>%s\n' "$entry_url" "$3"
        }
        anidb_fixture_curl() {
            for fixture_arg; do fixture_url="$fixture_arg"; done
            case "$fixture_url" in
                */browse*) printf '%s\n' '<a href="/anime/one-piece-3880"><img alt="One Piece">' ;;
                */anime/3880/episodes) printf '%s\n' '{"episodes":[{"id":3512,"number":1},{"id":3513,"number":2}]}' ;;
                */episode/3512/languages) printf '%s\n' '{"languages":[{"code":"jpn","embed_url":"https:\/\/anidb.test\/embed\/one"}]}' ;;
                */embed/one) printf "%s\n" "sources: [{ file: 'https://hls.anidb.test/master.m3u8', type: 'hls' }]" ;;
                */master.m3u8) printf '%s\n' '#EXTM3U' '#EXT-X-STREAM-INF:RESOLUTION=1920x1080,BANDWIDTH=1' 'https://hls.anidb.test/1080.m3u8' ;;
                *) return 1 ;;
            esac
        }

        anidb_curl_exe=anidb_fixture_curl
        anidb_agent=test
        anidb_refr=https://anidb.test
        resolver_timeout=1
        mode=sub
        id=anidb:one-piece-3880
        anidb_selected_ref=""
        anidb_selected_ref_key=""

        search_result="$(search_anidb_catalog one+piece)"
        [ "$search_result" = "one-piece-3880	One Piece" ]
        [ "$(anidb_episode_maps "$id" 'One Piece' | cut -f2)" = "1
2" ]
        links="$(resolve_anidb_episode 'One Piece' 1)"
        printf '%s\n' "$links" | grep -q '^1080 >https://hls.anidb.test/1080.m3u8$'
        printf '%s\n' "$links" | grep -q '^source >https://hls.anidb.test/1080.m3u8>HLS$'
        printf '%s\n' "$links" | grep -q '^site >https://hls.anidb.test/1080.m3u8>AniDB$'
        printf '%s\n' "$links" | grep -q '^referrer >https://hls.anidb.test/1080.m3u8>https://anidb.test$'
    )

    rm -rf "$tmp_dir"
}

run_fast_link_selection_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/link-functions.sh"
    sed -n '/^link_is_probably_broken()/,/^extract_streamtape_link()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        find_link_referrer() {
            printf '%s\n' 'https://video.example/player'
        }
        find_link_source() {
            printf '%s\n' 'HLS'
        }
        find_link_site() {
            printf '%s\n' 'AnimeAV1'
        }
        find_link_headers() {
            return 0
        }
        probe_link_with_mpv() {
            return 1
        }
        links='970 >https://video.example/first.m3u8
referrer >https://video.example/first.m3u8>https://video.example/player
source >https://video.example/first.m3u8>HLS
site >https://video.example/first.m3u8>AnimeAV1'

        selected="$(filter_playable_links "$links" first)"
        printf '%s\n' "$selected" | grep -q '^970 >https://video.example/first.m3u8$' || {
            printf 'Fast mode did not accept the first resolved stream\n' >&2
            return 1
        }
        printf '%s\n' "$selected" | grep -q '^referrer >https://video.example/first.m3u8>https://video.example/player$' || {
            printf 'Fast mode did not preserve stream metadata\n' >&2
            return 1
        }

        [ -z "$(filter_playable_links "$links")" ] || {
            printf 'Classic mode bypassed the player probe\n' >&2
            return 1
        }
    )

    rm -rf "$tmp_dir"
}

case "${1:-}" in
    --network)
        run_syntax_checks
        run_continuous_toggle_smoke
        run_download_menu_smoke
        run_windows_compat_smoke
        run_search_diagnostic_smoke
        run_search_query_candidates_smoke
        run_language_sections_smoke
        run_anidb_provider_smoke
        run_fast_link_selection_smoke
        run_debug_smoke
        ;;
    "" | --syntax)
        run_syntax_checks
        run_continuous_toggle_smoke
        run_download_menu_smoke
        run_windows_compat_smoke
        run_search_diagnostic_smoke
        run_search_query_candidates_smoke
        run_language_sections_smoke
        run_anidb_provider_smoke
        run_fast_link_selection_smoke
        ;;
    *)
        printf 'Usage: %s [--syntax|--network]\n' "$0" >&2
        exit 2
        ;;
esac
