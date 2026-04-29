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
        --source animeav1 -f -S 1 -e "13 14" "vinland saga season 2" >"$output_file" 2>&1
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

case "${1:-}" in
    --network)
        run_syntax_checks
        run_debug_smoke
        ;;
    "" | --syntax)
        run_syntax_checks
        ;;
    *)
        printf 'Usage: %s [--syntax|--network]\n' "$0" >&2
        exit 2
        ;;
esac
