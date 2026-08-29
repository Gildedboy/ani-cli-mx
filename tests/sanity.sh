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
        continuous_worker_log_file="$tmp_dir/continuous-worker.log"
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

run_continuous_window_state_smoke() {
    printf 'Checking continuous mpv window-state handling...\n' >&2
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/window-functions.sh"
    sed -n '/^create_mpv_window_state_script()/,/^play_episode()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        mpv_window_state_file="$tmp_dir/window-state"
        mpv_window_state_script="$tmp_dir/window-state.lua"
        if command -v cygpath >/dev/null 2>&1; then
            mpv_window_state_player_file="$(cygpath -m "$mpv_window_state_file")"
            mpv_window_state_player_script="$(cygpath -m "$mpv_window_state_script")"
        else
            mpv_window_state_player_file="$mpv_window_state_file"
            mpv_window_state_player_script="$mpv_window_state_script"
        fi
        continuous_state_file="$tmp_dir/continuous-state"
        player_supports_continuous() { return 0; }
        continuous_enabled() { grep -qx '1' "$continuous_state_file"; }

        create_mpv_window_state_script
        grep -Fq "local state_path = [[$mpv_window_state_player_file]]" "$mpv_window_state_script"
        grep -q 'observe_property("fullscreen"' "$mpv_window_state_script"
        grep -q 'observe_property("window-maximized"' "$mpv_window_state_script"
        grep -q 'get_property_number("osd-width"' "$mpv_window_state_script"
        ! grep -q 'register_event("end-file", finalize_state)' "$mpv_window_state_script"
        grep -q 'if value ~= nil then state.fullscreen = value' "$mpv_window_state_script"
        ! grep -q 'os.rename' "$mpv_window_state_script"

        if command -v mpv >/dev/null 2>&1; then
            mpv_window_args='--vo=null'
            command -v cygpath >/dev/null 2>&1 && mpv_window_args='--force-window=yes'
            fullscreen_script="$tmp_dir/simulate-user-fullscreen.lua"
            printf '%s\n' \
                'mp.register_event("file-loaded", function() mp.set_property_native("fullscreen", true) end)' >"$fullscreen_script"
            # shellcheck disable=SC2086
            mpv --no-config --audio=no $mpv_window_args --really-quiet \
                --force-media-title='Mushoku Tensei Episode 7' \
                --script="$mpv_window_state_script" --script="$fullscreen_script" \
                'av://lavfi:testsrc=duration=1:size=320x180:rate=10'
            grep -qx 'fullscreen=yes' "$mpv_window_state_file"

            maximized_script="$tmp_dir/simulate-user-maximized.lua"
            printf '%s\n' \
                'mp.register_event("file-loaded", function() mp.set_property_native("window-maximized", true) end)' >"$maximized_script"
            : >"$mpv_window_state_file"
            # shellcheck disable=SC2086
            mpv --no-config --audio=no $mpv_window_args --really-quiet \
                --force-media-title='Mushoku Tensei Episode 7' \
                --script="$mpv_window_state_script" --script="$maximized_script" \
                'av://lavfi:testsrc=duration=1:size=320x180:rate=10'
            grep -qx 'maximized=yes' "$mpv_window_state_file"
        fi

        printf '%s\n' 1 >"$continuous_state_file"
        printf '%s\n' 'fullscreen=yes' 'maximized=no' 'geometry=1280x720' >"$mpv_window_state_file"
        prepare_mpv_window_state_flags
        [ "$mpv_window_script_flag" = "--script=$mpv_window_state_player_script" ]
        [ "$mpv_fullscreen_flag" = '--fullscreen=yes' ]
        [ "$mpv_maximized_flag" = '--window-maximized=no' ]
        [ "$mpv_geometry_flag" = '--geometry=1280x720' ]

        printf '%s\n' 'fullscreen=no' 'maximized=yes' 'geometry=1024x576' >"$mpv_window_state_file"
        prepare_mpv_window_state_flags
        [ "$mpv_fullscreen_flag" = '--fullscreen=no' ]
        [ "$mpv_maximized_flag" = '--window-maximized=yes' ]
        [ "$mpv_geometry_flag" = '--geometry=1024x576' ]
    )

    grep -q 'mpv_window_script_flag.*mpv_geometry_flag.*mpv_maximized_flag.*mpv_fullscreen_flag' ani-cli-mx-core
    rm -rf "$tmp_dir"
    printf 'Continuous mpv window-state handling passed.\n' >&2
}

run_persistent_mpv_smoke() {
    printf 'Checking persistent mpv episode loading...\n' >&2
    command -v mpv >/dev/null 2>&1 || {
        printf 'Persistent mpv smoke skipped because mpv is unavailable.\n' >&2
        return 0
    }

    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/persistent-functions.sh"
    sed -n '/^create_mpv_window_state_script()/,/^play_episode()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"
    sed -n '/^select_quality()/,/^get_episode_url()/p' ani-cli-mx-core | sed '$d' >>"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        player_function='mpv --no-config'
        command -v cygpath >/dev/null 2>&1 || player_function='mpv --no-config --vo=null --audio=no'
        no_detach=0
        skip_intro=0
        continuous_state_file="$tmp_dir/continuous-state"
        mpv_window_state_file="$tmp_dir/window-state"
        mpv_window_state_script="$tmp_dir/window-state.lua"
        mpv_session_command_file="$tmp_dir/session-command"
        mpv_session_event_file="$tmp_dir/session-event"
        mpv_session_action_file="$tmp_dir/session-action"
        mpv_session_owner_file="$tmp_dir/session-owner"
        mpv_session_controller_script="$tmp_dir/session-controller.lua"
        if command -v cygpath >/dev/null 2>&1; then
            mpv_window_state_player_file="$(cygpath -m "$mpv_window_state_file")"
            mpv_window_state_player_script="$(cygpath -m "$mpv_window_state_script")"
            mpv_session_player_command_file="$(cygpath -m "$mpv_session_command_file")"
            mpv_session_player_event_file="$(cygpath -m "$mpv_session_event_file")"
            mpv_session_player_action_file="$(cygpath -m "$mpv_session_action_file")"
            mpv_session_player_owner_file="$(cygpath -m "$mpv_session_owner_file")"
            mpv_session_player_controller_script="$(cygpath -m "$mpv_session_controller_script")"
        else
            mpv_window_state_player_file="$mpv_window_state_file"
            mpv_window_state_player_script="$mpv_window_state_script"
            mpv_session_player_command_file="$mpv_session_command_file"
            mpv_session_player_event_file="$mpv_session_event_file"
            mpv_session_player_action_file="$mpv_session_action_file"
            mpv_session_player_owner_file="$mpv_session_owner_file"
            mpv_session_player_controller_script="$mpv_session_controller_script"
        fi
        player_supports_continuous() { return 0; }
        continuous_enabled() { return 1; }
        find_link_headers() { return 0; }
        find_link_subtitle() { return 0; }
        find_link_subtitles() { return 0; }
        find_link_site() { printf '%s\n' 'AnimeAV1'; }
        find_link_source() { printf '%s\n' 'HLS'; }
        describe_link_origin() { printf '%s / %s' "$1" "$2"; }
        close_tracked_player() {
            kill "$player_pid" 2>/dev/null || true
            wait "$player_pid" 2>/dev/null || true
        }

        : >"$mpv_session_owner_file"
        : >"$mpv_session_action_file"
        create_mpv_window_state_script
        create_mpv_session_controller
        grep -q 'local load_pending = false' "$mpv_session_controller_script"
        grep -q 'not load_pending and current_episode' "$mpv_session_controller_script"
        grep -q 'load_pending = true' "$mpv_session_controller_script"
        grep -q 'mp.register_event("file-loaded", function()' "$mpv_session_controller_script"
        grep -q 'load_pending = false' "$mpv_session_controller_script"
        grep -q 'mp.add_key_binding("N", "ani-cli-next"' "$mpv_session_controller_script"
        grep -q 'mp.add_key_binding("P", "ani-cli-previous"' "$mpv_session_controller_script"
        grep -q 'mp.add_key_binding("R", "ani-cli-replay"' "$mpv_session_controller_script"
        grep -q 'mp.add_key_binding("A", "ani-cli-continuous"' "$mpv_session_controller_script"

        zilla_header_fields='Origin:https://player.zilla-networks.com,Sec-Fetch-Dest:empty,Sec-Fetch-Mode:cors,Sec-Fetch-Site:same-origin'
        quality=best
        for regression_title in 'Mushoku Tensei' 'Yani Neko'; do
            links='970 >https://player.zilla-networks.com/m3u8/regression
referrer >https://player.zilla-networks.com/m3u8/regression>https://player.zilla-networks.com/play/regression
source >https://player.zilla-networks.com/m3u8/regression>HLS
site >https://player.zilla-networks.com/m3u8/regression>AnimeAV1'
            select_quality "$quality"
            [ "$generic_headers" = "$zilla_header_fields" ]
            [ "$headers_flag" = "--http-header-fields=$zilla_header_fields" ]
            media_title="$regression_title "
            ep_no=7
            player_pid=$$
            queue_persistent_mpv_episode
            grep -Fq '"headers":"Origin:https://player.zilla-networks.com,Sec-Fetch-Dest:empty,Sec-Fetch-Mode:cors,Sec-Fetch-Site:same-origin"' "$mpv_session_command_file"
        done

        ANI_CLI_MPV_SESSION_LOG="$tmp_dir/mpv.log"
        export ANI_CLI_MPV_SESSION_LOG
        start_persistent_mpv
        original_pid="$player_pid"

        links=""
        generic_refr=""
        generic_headers=""
        media_title='Persistent "mpv" Test '
        ep_no=1
        episode='av://lavfi:testsrc=duration=1:size=64x36:rate=10'
        queue_persistent_mpv_episode

        event_attempt=0
        while [ ! -s "$mpv_session_event_file" ] && [ "$event_attempt" -lt 300 ]; do
            sleep 0.1
            event_attempt=$((event_attempt + 1))
        done
        grep -qx '1' "$mpv_session_event_file"
        kill -0 "$original_pid"

        ep_no=2
        episode='av://lavfi:testsrc=duration=1:size=64x36:rate=10'
        queue_persistent_mpv_episode
        [ "$player_pid" = "$original_pid" ]
        event_attempt=0
        while { [ ! -s "$mpv_session_event_file" ] || ! grep -qx '2' "$mpv_session_event_file"; } && [ "$event_attempt" -lt 300 ]; do
            sleep 0.1
            event_attempt=$((event_attempt + 1))
        done
        grep -qx '2' "$mpv_session_event_file"
        kill -0 "$original_pid"

        ep_no=3
        episode='av://lavfi:testsrc=duration=3:size=64x36:rate=10'
        queue_persistent_mpv_episode
        sleep 0.2
        ep_no=4
        episode='av://lavfi:testsrc=duration=1:size=64x36:rate=10'
        queue_persistent_mpv_episode
        event_attempt=0
        while { [ ! -s "$mpv_session_event_file" ] || ! grep -qx '4' "$mpv_session_event_file"; } && [ "$event_attempt" -lt 300 ]; do
            sleep 0.1
            event_attempt=$((event_attempt + 1))
        done
        grep -qx '4' "$mpv_session_event_file"
        kill -0 "$original_pid"

        ep_no=5
        episode='av://lavfi:testsrc=duration=0.4:size=64x36:rate=10'
        queue_persistent_mpv_episode
        event_attempt=0
        while { [ ! -s "$mpv_session_event_file" ] || ! grep -qx '5' "$mpv_session_event_file"; } && [ "$event_attempt" -lt 100 ]; do
            sleep 0.1
            event_attempt=$((event_attempt + 1))
        done
        grep -qx '5' "$mpv_session_event_file"

        ep_no=6
        episode='av://lavfi:testsrc=duration=0.8:size=64x36:rate=10'
        queue_persistent_mpv_episode
        sleep 0.2
        [ ! -s "$mpv_session_event_file" ]
        kill -0 "$original_pid"

        event_attempt=0
        while { [ ! -s "$mpv_session_event_file" ] || ! grep -qx '6' "$mpv_session_event_file"; } && [ "$event_attempt" -lt 200 ]; do
            sleep 0.1
            event_attempt=$((event_attempt + 1))
        done
        grep -qx '6' "$mpv_session_event_file"

        kill "$original_pid" 2>/dev/null || true
        wait "$original_pid" 2>/dev/null || true
        ! kill -0 "$original_pid" 2>/dev/null
    )

    rm -rf "$tmp_dir"
    printf 'Persistent mpv episode loading passed.\n' >&2
}

run_animex_subtitle_smoke() {
    printf 'Checking AnimeX external subtitle handling...\n' >&2
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/animex-functions.sh"
    sed -n '/^find_link_referrer()/,/^count_quality_links()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"
    sed -n '/^emit_annotated_link_entry()/,/^quality_menu_entries()/p' ani-cli-mx-core | sed '$d' >>"$funcs_file"
    sed -n '/^resolve_animex_provider()/,/^animex_proxy_url()/p' ani-cli-mx-core | sed '$d' >>"$funcs_file"
    sed -n '/^select_quality()/,/^get_episode_url()/p' ani-cli-mx-core | sed '$d' >>"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        curl() {
            printf '%s\n' '{"sources":[{"url":"https://video.animex.test/master.m3u8","quality":"auto","type":"video/mpegurl"}],"tracks":[{"id":"captions-1","url":"https://subs.animex.test/kaijuu-8-en.vtt","lang":"en","label":"English","kind":"captions","default":true},{"id":"captions-2","url":"https://subs.animex.test/kaijuu-8-es.vtt","lang":"es","label":"Spanish","kind":"captions","default":false}],"headers":{"Referer":"https://video.animex.test/"}}'
        }
        animex_proxy_url() { printf '%s\n' "$1"; }
        mode=sub
        ep_no=1
        agent=test
        animex_api=https://animex.test
        player_function=mpv
        quality=best
        zilla_header_fields=''

        links="$(resolve_animex_provider 'kaiju-no-8-bqnnd' beep)"
        printf '%s\n' "$links" | grep -q '^1080 >https://video.animex.test/master.m3u8>cc>$'
        printf '%s\n' "$links" | grep -q '^subtitle >https://video.animex.test/master.m3u8>https://subs.animex.test/kaijuu-8-en.vtt$'
        printf '%s\n' "$links" | grep -q '^subtitle >https://video.animex.test/master.m3u8>https://subs.animex.test/kaijuu-8-es.vtt$'
        [ "$(find_link_subtitles "$links" 'https://video.animex.test/master.m3u8')" = 'https://subs.animex.test/kaijuu-8-en.vtt
https://subs.animex.test/kaijuu-8-es.vtt' ]

        select_quality best
        [ "$episode" = 'https://video.animex.test/master.m3u8' ]
        [ "$subs_flag" = '--sub-file=https://subs.animex.test/kaijuu-8-en.vtt --sub-file=https://subs.animex.test/kaijuu-8-es.vtt ' ]
        [ "$iina_subs_flag" = '--mpv-sub-file=https://subs.animex.test/kaijuu-8-en.vtt --mpv-sub-file=https://subs.animex.test/kaijuu-8-es.vtt ' ]
    )

    rm -rf "$tmp_dir"
    printf 'AnimeX external subtitle handling passed.\n' >&2
}

run_download_menu_smoke() {
    menu_options="$(sed -n '/^playback_menu_options()/,/^playback_menu_prompt()/p' ani-cli-mx-core)"
    printf '%s\n' "$menu_options" | grep -q 'descargar_episodio_actual'
    ! printf '%s\n' "$menu_options" | grep -q 'cambiar_calidad'
    ! grep -q '^[[:space:]]*cambiar_calidad)' ani-cli-mx-core
    grep -q 'download_dir="${ANI_CLI_DOWNLOAD_DIR:-$(default_download_dir)}"' ani-cli-mx-core
    grep -q "command -v yt-dlp" ani-cli-mx-core
}

run_playback_menu_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/playback-menu-functions.sh"
    sed -n '/^external_menu()/,/^die()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"
    sed -n '/^set_current_episode()/,/^# MAIN/p' ani-cli-mx-core | sed '$d' >>"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        continuous_state_file="$tmp_dir/continuous-state"
        current_episode_file="$tmp_dir/current-episode"
        close_previous_player=0
        navigation_context=search
        printf '%s\n' 1 >"$continuous_state_file"
        printf '%s\n' 2 >"$current_episode_file"

        selected_site=JKAnime
        persistent_options="$(playback_menu_options persistent)"
        printf '%s\n' "$persistent_options" | grep -q 'Siguiente episodio'
        printf '%s\n' "$persistent_options" | grep -q 'Episodio anterior'
        printf '%s\n' "$persistent_options" | grep -q 'Repetir episodio actual'
        printf '%s\n' "$persistent_options" | grep -q 'Elegir otro capitulo'
        printf '%s\n' "$persistent_options" | grep -q 'Descargar episodio actual'
        printf '%s\n' "$persistent_options" | grep -q 'Volver a resultados'
        printf '%s\n' "$persistent_options" | grep -q 'Buscar otro anime'
        printf '%s\n' "$persistent_options" | grep -q 'Volver al inicio'
        printf '%s\n' "$persistent_options" | grep -q 'desactivar_modo_continuo'
        ! printf '%s\n' "$persistent_options" | grep -q 'cerrar_reproductor_anterior'

        fallback_options="$(playback_menu_options)"
        printf '%s\n' "$fallback_options" | grep -q 'activar_cerrar_reproductor_anterior'

        selected_site=AnimeAV1
        animeav1_options="$(playback_menu_options)"
        case "$animeav1_options" in *'Descargar episodio actual'*) exit 1 ;; esac
        selected_site=AnimeX
        animex_options="$(playback_menu_options)"
        case "$animex_options" in *'Descargar episodio actual'*) : ;; *) exit 1 ;; esac
        selected_site=JKAnime

        title='Yani Neko'
        app_name=ani-cli-mx
        use_external_menu=0
        playback_menu_live=1
        fzf() {
            fzf_input="$(cat)"
            for fzf_arg in "$@"; do
                case "$fzf_arg" in --listen*) return 9 ;; esac
            done
            if [ ! -e "$tmp_dir/fzf-started" ]; then
                : >"$tmp_dir/fzf-started"
                sleep 5
                return 1
            fi
            printf '\n'
            printf '%s\n' "$fzf_input" | sed -n '1p'
        }
        (sleep 0.3; printf '%s\n' 3 >"$current_episode_file") &
        refreshed_selection="$(printf '1 Siguiente episodio\n2 Episodio anterior\n' | playback_launcher +m)"
        [ "$refreshed_selection" = '1 Siguiente episodio' ]
        [ "$(current_episode_number)" = 3 ]

        persistent_mpv_alive() { return 0; }
        fzf() {
            fzf_input="$(cat)"
            printf '\n'
            printf '%s\n' "$fzf_input" | grep -F "$fzf_selected_label" | sed -n '1p'
        }
        assert_playback_command() {
            fzf_selected_label="$1"
            expected_playback_command="$2"
            actual_playback_command="$(playback_command)"
            [ "$actual_playback_command" = "$expected_playback_command" ]
        }

        printf '%s\n' 0 >"$continuous_state_file"
        assert_playback_command 'Siguiente episodio' siguiente
        assert_playback_command 'Episodio anterior' anterior
        assert_playback_command 'Repetir episodio actual' repetir_episodio_actual
        assert_playback_command 'Elegir otro capitulo' elegir_episodio
        assert_playback_command 'Descargar episodio actual' descargar_episodio_actual
        assert_playback_command 'Activar modo continuo' activar_modo_continuo
        assert_playback_command 'Volver a resultados' volver_resultados
        assert_playback_command 'Buscar otro anime' buscar_otro_anime
        assert_playback_command 'Volver al inicio' volver_inicio
        assert_playback_command 'Salir' salir

        printf '%s\n' 1 >"$continuous_state_file"
        assert_playback_command 'Desactivar modo continuo' desactivar_modo_continuo
        ! playback_menu_prompt | grep -qi 'cerrar anterior'
    )

    ! grep -q '^playback_controller_command()' ani-cli-mx-core
    ! grep -q -- '--internal-playback-menu-watch' ani-cli-mx-core
    ! grep -q -- '--listen=0' ani-cli-mx-core
    grep -q 'continuous_worker_loop.*continuous_worker_log_file.*2>&1 &' ani-cli-mx-core
    rm -rf "$tmp_dir"
}

run_history_menu_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/history-functions.sh"
    sed -n '/^process_hist_entry()/,/^last_watched_episode_for_current_anime()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        id='jkanime:yani-neko'
        title='Yani Neko (3 episodios)'
        ep_no=2
        pending_row="$(process_hist_entry)"
        printf '%s\n' "$pending_row" | awk -F '\t' '$1 == "jkanime:yani-neko" && $2 == "Yani Neko (3 episodios)" && $3 == 2 { found=1 } END { exit !found }'
        pending_menu="$(printf '%s\n' "$pending_row" | build_history_menu)"
        printf '%s\n' "$pending_menu" | grep -q 'Yani Neko \[JKAnime\]'
        ! printf '%s\n' "$pending_menu" | grep -q 'Ultimo visto'
        printf '%s\n' "$pending_menu" | grep -q 'Buscar anime'
        printf '%s\n' "$pending_menu" | grep -q 'Volver al inicio'

        id='animeav1:yani-neko'
        animeav1_row="$(process_hist_entry)"
        combined_menu="$(printf '%s\n%s\n' "$pending_row" "$animeav1_row" | build_history_menu)"
        printf '%s\n' "$combined_menu" | grep -q 'Yani Neko \[AnimeAV1\]'
    )

    rm -rf "$tmp_dir"
}

run_anime_preview_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/preview-functions.sh"
    preview_file="$tmp_dir/preview-data"
    output_file="$tmp_dir/output"
    curl_log="$tmp_dir/curl-log"
    preview_query_log="$tmp_dir/preview-query-log"
    mkdir -p "$tmp_dir/bin" "$tmp_dir/cache"

    sed -n '/^normalize_romanized_text()/,/^normalize_info_source()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"
    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        resolver_timeout=5
        id=''
        mpv_json_escape() {
            printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
        }
        info_source_label() {
            case "$1" in
                jkanime) printf '%s\n' JKAnime ;;
                animex) printf '%s\n' AnimeX ;;
                *) printf '%s\n' "$1" ;;
            esac
        }
        curl() {
            printf '%s\n' "$*" >"$PREVIEW_QUERY_LOG"
            case "$*" in
                *'One Piece'*)
                    printf '%s\n' '{"data":{"m0":{"id":21,"title":{"romaji":"ONE PIECE","english":"ONE PIECE"},"coverImage":{"extraLarge":"https:\/\/img.example\/one-piece.jpg"},"format":"TV","status":"RELEASING","episodes":null,"seasonYear":1999}}}'
                    ;;
                *)
                    printf '%s\n' '{"data":{"Page":{"media":[{"id":207141,"title":{"romaji":"Yani Neko","english":"Chainsmoker Cat"},"coverImage":{"extraLarge":"https:\/\/img.example\/yani-xl.jpg"},"format":"TV","status":"RELEASING","episodes":null,"seasonYear":2026}]}}}'
                    ;;
            esac
        }
        preview_results="$(printf 'jkanime:yani-neko\tYani Neko\tYani Neko [JKAnime]\nanimex:yani-neko\tYani Neko\tYani Neko [AnimeX]\nanimeav1:super-no-ura-de-yani\tSuper no Ura de Yani Suu Hanashi\tSuper no Ura de Yani Suu Hanashi [AnimeAV1]\n')"
        generated_preview_file="$(PREVIEW_QUERY_LOG="$preview_query_log" prepare_anime_preview_file "$preview_results")"
        [ "$(wc -l <"$generated_preview_file")" -eq 3 ]
        grep -q 'Media(search:\\"Yani Neko\\"' "$preview_query_log"
        grep -q 'Media(search:\\"Super no Ura de Yani Suu Hanashi\\"' "$preview_query_log"
        [ "$(grep -o 'Media(search:\\"Yani Neko\\"' "$preview_query_log" | wc -l)" -eq 1 ]
        awk -F '\t' '$1 == 1 && $2 == "JKAnime" && $3 == "Yani Neko" && $4 == 207141 && $7 == "https://img.example/yani-xl.jpg" && $11 == 2026 { found=1 } END { exit !found }' "$generated_preview_file"
        awk -F '\t' '$1 == 2 && $2 == "AnimeX" && $3 == "Yani Neko" && $4 == 207141 && $6 == "Chainsmoker Cat" { found=1 } END { exit !found }' "$generated_preview_file"
        awk -F '\t' '$1 == 3 && $3 == "Super no Ura de Yani Suu Hanashi" && $4 == "" && $7 == "" { found=1 } END { exit !found }' "$generated_preview_file"
        rm -f "$generated_preview_file"

        one_piece_results="$(printf 'jkanime:one-piece\tOne Piece\tOne Piece [JKAnime]\nanimex:one-piece\tOne Piece\tOne Piece [AnimeX]\n')"
        generated_preview_file="$(PREVIEW_QUERY_LOG="$preview_query_log" prepare_anime_preview_file "$one_piece_results" 'one+p')"
        grep -q 'Media(search:\\"One Piece\\"' "$preview_query_log"
        ! grep -q 'one+p' "$preview_query_log"
        [ "$(grep -o 'Media(search:\\"One Piece\\"' "$preview_query_log" | wc -l)" -eq 1 ]
        awk -F '\t' '$1 == 1 && $3 == "One Piece" && $4 == 21 && $7 == "https://img.example/one-piece.jpg" && $11 == 1999 { found=1 } END { exit !found }' "$generated_preview_file"
        awk -F '\t' '$1 == 2 && $3 == "One Piece" && $4 == 21 && $7 == "https://img.example/one-piece.jpg" { found=1 } END { exit !found }' "$generated_preview_file"
        rm -f "$generated_preview_file"
    )

    printf '%s\n' \
        '1	JKAnime	Yani Neko	207141	Yani Neko	Chainsmoker Cat	https://img.example/yani.jpg	TV	RELEASING		2026' \
        >"$preview_file"
    printf '%s\n' \
        '#!/bin/sh' \
        'output_file=""' \
        'while [ "$#" -gt 0 ]; do' \
        '    if [ "$1" = "-o" ]; then output_file="$2"; shift 2; else shift; fi' \
        'done' \
        'printf "downloaded\n" >>"$PREVIEW_CURL_LOG"' \
        'printf "image-data\n" >"$output_file"' \
        >"$tmp_dir/bin/curl"
    printf '%s\n' \
        '#!/bin/sh' \
        'printf "%s\n" "$*" >"$PREVIEW_CHAFA_LOG"' \
        'for argument in "$@"; do image_path="$argument"; done' \
        'printf "IMAGE:%s\n" "${image_path##*/}"' \
        >"$tmp_dir/bin/chafa"
    chmod +x "$tmp_dir/bin/curl" "$tmp_dir/bin/chafa"

    env PATH="$tmp_dir/bin:$PATH" PREVIEW_CURL_LOG="$curl_log" \
        PREVIEW_CHAFA_LOG="$tmp_dir/chafa-log" FZF_PREVIEW_COLUMNS=72 FZF_PREVIEW_LINES=40 \
        ANI_CLI_PREVIEW_CACHE_DIR="$tmp_dir/cache" \
        ./ani-cli-mx-core --internal-preview "$preview_file" 1 >"$output_file"
    grep -q '^IMAGE:207141.extra-large.cover$' "$output_file"
    grep -q 'PORTADA' "$output_file"
    grep -q 'INFORMACIÓN' "$output_file"
    grep -q 'Yani Neko' "$output_file"
    grep -q 'Fuente: JKAnime' "$output_file"
    grep -q 'Inglés: Chainsmoker Cat' "$output_file"
    grep -q 'Año: 2026' "$output_file"
    grep -q 'Estado: RELEASING' "$output_file"
    grep -q -- '--scale=max' "$tmp_dir/chafa-log"
    grep -q -- '--work=9' "$tmp_dir/chafa-log"
    grep -q -- '--size=68x26' "$tmp_dir/chafa-log"
    grep -q -- '--view-size=68x26' "$tmp_dir/chafa-log"
    grep -q -- '--align=top,center' "$tmp_dir/chafa-log"
    [ -s "$tmp_dir/cache/207141.extra-large.cover" ]

    env PATH="$tmp_dir/bin:$PATH" PREVIEW_CURL_LOG="$curl_log" WT_SESSION=test-session \
        PREVIEW_CHAFA_LOG="$tmp_dir/chafa-log" \
        ANI_CLI_PREVIEW_CACHE_DIR="$tmp_dir/cache" \
        ./ani-cli-mx-core --internal-preview "$preview_file" 1 >/dev/null
    [ "$(wc -l <"$curl_log")" -eq 1 ]
    grep -q -- '--format=sixels' "$tmp_dir/chafa-log"
    grep -q -- '--passthrough=none' "$tmp_dir/chafa-log"

    printf '%s\n' \
        '1	JKAnime	Sin portada					TV	FINISHED	12	2024' \
        >"$preview_file"
    env PATH="$tmp_dir/bin:$PATH" FZF_PREVIEW_COLUMNS=72 FZF_PREVIEW_LINES=40 \
        ANI_CLI_PREVIEW_CACHE_DIR="$tmp_dir/cache" \
        ./ani-cli-mx-core --internal-preview "$preview_file" 1 >"$output_file"
    grep -q 'PORTADA' "$output_file"
    grep -q 'Sin portada disponible.' "$output_file"
    grep -q 'INFORMACIÓN' "$output_file"
    grep -q 'Episodios: 12' "$output_file"
    [ "$(wc -l <"$curl_log")" -eq 1 ]

    rm -rf "$tmp_dir"
}

run_main_menu_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/menu-functions.sh"
    sed -n '/^main_menu_options()/,/^nth()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        use_external_menu=0
        app_name=ani-cli-mx
        menu_entries="$(main_menu_options)"
        printf '%s\n' "$menu_entries" | awk -F '\t' '$1 == 1 && $2 == "search" && $3 == "Buscar anime" { found=1 } END { exit !found }'
        printf '%s\n' "$menu_entries" | awk -F '\t' '$1 == 2 && $2 == "history" && $3 == "Continuar viendo" { found=1 } END { exit !found }'
        fzf() {
            printf '%s\n' 'yani neko' '' 'Escribe el titulo y presiona Enter'
        }
        [ "$(search_query_menu)" = 'yani neko' ]
    )

    rm -rf "$tmp_dir"
}

run_navigation_history_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/navigation-functions.sh"
    sed -n '/^external_menu()/,/^die()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"
    sed -n '/^build_anime_menu()/,/^normalize_info_source()/p' ani-cli-mx-core | sed '$d' >>"$funcs_file"
    sed -n '/^last_watched_episode_for_current_anime()/,/^download()/p' ani-cli-mx-core | sed '$d' >>"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        use_external_menu=0
        app_name=ani-cli-mx
        multi_selection_flag=-m

        fzf() { cat >/dev/null; printf '%s\n' esc; }
        if printf '1 Choice\n' | launcher '' 'Test: '; then
            exit 1
        else
            [ "$?" -eq 10 ]
        fi

        fzf() { cat >/dev/null; printf '%s\n' ctrl-c; }
        if printf '1 Choice\n' | launcher '' 'Test: '; then
            exit 1
        else
            [ "$?" -eq 130 ]
        fi

        anime_menu="$(printf '%s\n' 'jkanime:yani-neko	Yani Neko	Yani Neko [JKAnime]' | build_anime_menu)"
        printf '%s\n' "$anime_menu" | grep -q '__nav_search.*Buscar de nuevo'
        printf '%s\n' "$anime_menu" | grep -q '__nav_home.*Volver al inicio'
        printf '%s\n' "$anime_menu" | grep -q '__nav_exit.*Salir'

        histfile="$tmp_dir/history"
        : >"$histfile"
        id='jkanime:yani-neko'
        navigation_context=search
        launcher() { cat >/dev/null; printf '%s\n' '3 Volver a resultados'; }
        [ "$(printf '%s\n' 1 2 | select_episode)" = '__nav_back' ]

        printf '%s\n' \
            '1	animeav1:yani-neko	Yani Neko (4 episodios)' \
            '2	jkanime:yani-neko	Yani Neko (4 episodios)' >"$histfile"
        id='jkanime:yani-neko'
        title='Yani Neko (4 episodios)'
        ep_no=3
        update_history
        [ "$(sed -n '1p' "$histfile")" = '3	jkanime:yani-neko	Yani Neko (4 episodios)' ]
        [ "$(awk -F '\t' '$2 == "jkanime:yani-neko" { count++ } END { print count + 0 }' "$histfile")" -eq 1 ]
        [ "$(sed -n '2p' "$histfile" | cut -f2)" = 'animeav1:yani-neko' ]
    )

    rm -rf "$tmp_dir"
}

run_mpv_action_worker_smoke() {
    tmp_dir="$(mktemp -d)"
    funcs_file="$tmp_dir/action-worker-functions.sh"
    played_file="$tmp_dir/played"
    messages_file="$tmp_dir/messages"
    sed -n '/^set_current_episode()/,/^toggle_close_previous_from_menu()/p' ani-cli-mx-core | sed '$d' >"$funcs_file"

    (
        # shellcheck disable=SC1090
        . "$funcs_file"
        current_episode_file="$tmp_dir/current-episode"
        continuous_state_file="$tmp_dir/continuous-state"
        mpv_session_action_file="$tmp_dir/session-action"
        mpv_session_event_file="$tmp_dir/session-event"
        ep_list='1
2
3'
        ep_no=2
        episode=''

        play_episode() {
            set_current_episode "$ep_no"
            printf '%s\n' "$ep_no" >>"$played_file"
        }
        queue_persistent_mpv_message() {
            printf '%s\n' "$1" >>"$messages_file"
        }
        wait_for_play_count() {
            expected_count="$1"
            wait_attempt=0
            while [ "$(wc -l <"$played_file" 2>/dev/null || printf 0)" -lt "$expected_count" ] && [ "$wait_attempt" -lt 100 ]; do
                sleep 0.05
                wait_attempt=$((wait_attempt + 1))
            done
            [ "$(wc -l <"$played_file")" -ge "$expected_count" ]
        }

        : >"$played_file"
        printf '%s\n' 0 >"$continuous_state_file"
        set_current_episode 2
        sleep 10 &
        watched_pid=$!
        persistent_playback_worker_loop "$watched_pid" >"$tmp_dir/worker.log" 2>&1 &
        worker_pid=$!

        printf '%s\n' next >"$mpv_session_action_file"
        wait_for_play_count 1
        [ "$(tail -n1 "$played_file")" = 3 ]

        printf '%s\n' previous >"$mpv_session_action_file"
        wait_for_play_count 2
        [ "$(tail -n1 "$played_file")" = 2 ]

        printf '%s\n' replay >"$mpv_session_action_file"
        wait_for_play_count 3
        [ "$(tail -n1 "$played_file")" = 2 ]

        printf '%s\n' toggle-continuous >"$mpv_session_action_file"
        toggle_attempt=0
        while ! grep -qx 1 "$continuous_state_file" && [ "$toggle_attempt" -lt 100 ]; do
            sleep 0.05
            toggle_attempt=$((toggle_attempt + 1))
        done
        grep -qx 1 "$continuous_state_file"

        printf '%s\n' 2 >"$mpv_session_event_file"
        wait_for_play_count 4
        [ "$(tail -n1 "$played_file")" = 3 ]

        kill "$watched_pid" 2>/dev/null || true
        wait "$watched_pid" 2>/dev/null || true
        wait "$worker_pid"
    )

    rm -rf "$tmp_dir"
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

    [ "$version_output" = "2.1.0" ]
    [ -f "$local_app_data/ani-cli-mx/ani-hsts" ]
    grep -q 'GIT_INSTALL_ROOT' ani-cli-mx.cmd
    grep -q 'ANI_CLI_PACKAGE_MANAGER=scoop' ani-cli-mx.cmd
    grep -q 'ANI_CLI_STATE_NAME=ani-cli-mx' ani-cli-mx.cmd
    grep -q 'GIT_INSTALL_ROOT' ani-cli-mx.ps1
    grep -q 'ANI_CLI_STATE_NAME' ani-cli-mx.ps1
    grep -q '\$bashExe \$corePath @args' ani-cli-mx.ps1
    ! grep -q 'ANI_CLI_PREVIEW_EXEC' ani-cli-mx-core
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
        find_link_subtitles() {
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
        run_continuous_window_state_smoke
        run_persistent_mpv_smoke
        run_animex_subtitle_smoke
        run_download_menu_smoke
        run_playback_menu_smoke
        run_history_menu_smoke
        run_main_menu_smoke
        run_navigation_history_smoke
        run_mpv_action_worker_smoke
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
        run_continuous_window_state_smoke
        run_persistent_mpv_smoke
        run_animex_subtitle_smoke
        run_download_menu_smoke
        run_playback_menu_smoke
        run_history_menu_smoke
        run_main_menu_smoke
        run_navigation_history_smoke
        run_mpv_action_worker_smoke
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
