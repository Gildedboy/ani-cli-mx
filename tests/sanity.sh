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

    env ANI_CLI_PLAYER=debug ANI_CLI_NO_DETACH=1 ./ani-cli-mx \
        -S 1 -e 1 "school rumble" >"$output_file" 2>&1
    strip_ansi <"$output_file" >"$clean_file"
    grep -q "Fuente seleccionada:" "$clean_file"
    grep -q "Enlace seleccionado:" "$clean_file"

    env ANI_CLI_PLAYER=debug ANI_CLI_NO_DETACH=1 ./ani-cli-mx \
        --source animeav1 -S 1 -e "13 14" "vinland saga season 2" >"$output_file" 2>&1
    strip_ansi <"$output_file" >"$clean_file"
    grep -q "Reproduciendo episodio 14" "$clean_file"
    grep -q "Fuente seleccionada:" "$clean_file"
    grep -q "AnimeAV1" "$clean_file"

    ep14_output="$(sed -n '/Reproduciendo episodio 14/,$p' "$clean_file")"
    printf '%s\n' "$ep14_output" | grep -q "AnimeAV1 HLS"
    ! printf '%s\n' "$ep14_output" | grep -q "AnimeAV1 1Fichier"
    ! printf '%s\n' "$ep14_output" | grep -q "AnimeAV1 UPNShare"
    ! printf '%s\n' "$ep14_output" | grep -q "AnimeFLV"
    ! printf '%s\n' "$ep14_output" | grep -q "JKAnime"
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

case "${1:-}" in
    --network)
        run_syntax_checks
        run_continuous_toggle_smoke
        run_debug_smoke
        ;;
    "" | --syntax)
        run_syntax_checks
        run_continuous_toggle_smoke
        ;;
    *)
        printf 'Usage: %s [--syntax|--network]\n' "$0" >&2
        exit 2
        ;;
esac
