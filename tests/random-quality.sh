#!/bin/sh
# Focused regressions for random episodes and the validated quality menu.
set -eu
repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$repo_dir"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
sed '/^# MAIN/,$d' ani-cli-mx-core >"$test_dir/functions.sh"
. "$test_dir/functions.sh"

(
    random_index() { printf '1\n'; }
    [ "$(random_from_catalog '1
__nav_home
1.5
__jk_next
3' 1)" = 1.5 ]
    [ "$(random_from_catalog 's1e1
s2e3' s1e1)" = s2e3 ]
    [ "$(random_from_catalog 1 1)" = 1 ]
    ! random_from_catalog '__nav_home' ''
    media_kind=movie
    ! random_episode_number movie ''
)

(
    media_kind=anime
    mkdir "$test_dir/jk"
    printf '%s\n' 0 21 token 3 10 ascending >"$test_dir/jk/meta"
    jkanime_current_dir() { printf '%s\n' "$test_dir/jk"; }
    random_index() { [ "$1" -eq 3 ] && printf '3\n' || printf '1\n'; }
    jkanime_catalog_page() {
        printf '%s\n' "$2" >>"$test_dir/pages"
        [ "$2" -eq 3 ] && printf '9.5\n10\n'
    }
    [ "$(random_episode_number '1
2' 2)" = 9.5 ]
    [ "$(cat "$test_dir/pages")" = 3 ]
    jkanime_catalog_page() { return 1; }
    ! random_episode_number '1
2' 2
)

(
    media_kind=series
    histfile="$test_dir/history"
    current_episode_file="$test_dir/current"
    ep_no=s1e1
    : >"$histfile"
    printf '%s\n' s1e1 >"$current_episode_file"
    id=pelisplus:series:south-park
    multi_selection_flag=+m
    navigation_context=search
    jkanime_current_dir() { return 1; }
    launcher() { awk '/Episodio aleatorio/ {print; exit}'; }
    [ "$(printf 's1e1\ns2e3\n' | choose_episode)" = s2e3 ]
)

quality_fixture() {
    cat <<'EOF'
pelisplus:series:south-park|s1e1
active >https://media.test/1080.m3u8>
1076 >https://media.test/1080.m3u8
720 >https://media.test/720.m3u8
480 >https://media.test/480.m3u8
resolution >https://media.test/1080.m3u8>1076
resolution >https://media.test/720.m3u8>720
resolution >https://media.test/480.m3u8>480
source >https://media.test/1080.m3u8>Vidhide
source >https://media.test/720.m3u8>Vidhide
source >https://media.test/480.m3u8>Vidhide
site >https://media.test/1080.m3u8>PelisPlusHD
site >https://media.test/720.m3u8>PelisPlusHD
site >https://media.test/480.m3u8>PelisPlusHD
language >https://media.test/1080.m3u8>LAT
language >https://media.test/720.m3u8>LAT
language >https://media.test/480.m3u8>LAT
referrer >https://media.test/720.m3u8>https://player.test/
headers >https://media.test/720.m3u8>Origin:https://player.test
validated >https://media.test/1080.m3u8>
EOF
}

(
    quality_cache_file="$test_dir/quality"
    current_episode_file="$test_dir/current"
    id=pelisplus:series:south-park
    ep_no=s1e1
    printf '%s\n' "$ep_no" >"$current_episode_file"
    quality_fixture >"$quality_cache_file"
    persistent_mpv_alive() { return 0; }
    pelisplus_probe_timeout=1
    probe_link_with_mpv() {
        printf '%s\n' "$1" >>"$test_dir/probes"
        [ "$1" = https://media.test/720.m3u8 ] || return 1
        [ "$2" = https://player.test/ ] && [ "$3" = Origin:https://player.test ]
    }
    prepare_quality_options
    quality_menu_available
    [ "$(validated_quality_links <"$quality_cache_file" | wc -l)" -eq 2 ]
    ! validated_quality_links <"$quality_cache_file" | grep -q '^480 '
    before="$(wc -l <"$test_dir/probes")"
    prepare_quality_options
    [ "$(wc -l <"$test_dir/probes")" -eq "$before" ]
    printf 's1e2\n' >"$current_episode_file"
    ! quality_menu_available
    printf 's1e1\n' >"$current_episode_file"
    sed '/validated >https:\/\/media.test\/720.m3u8>/d' "$quality_cache_file" >"$test_dir/only-one"
    mv "$test_dir/only-one" "$quality_cache_file"
    ! quality_menu_available
)

(
    links='970 >https://media.test/priority.m3u8
site >https://media.test/priority.m3u8>AnimeAV1
source >https://media.test/priority.m3u8>HLS'
    [ -z "$(find_link_quality "$links" https://media.test/priority.m3u8)" ]
    [ -z "$(quality_menu_entries "$links")" ]
)

(
    id=pelisplus:series:south-park
    ep_no=s1e1
    title='South Park'
    media_kind=series
    player_function=mpv
    player_pid=$$
    quality_cache_file="$test_dir/switch-cache"
    current_episode_file="$test_dir/switch-episode"
    mpv_session_command_file="$test_dir/switch-command"
    mpv_session_event_file="$test_dir/switch-event"
    pelisplus_probe_timeout=1
    printf '%s\n' "$ep_no" >"$current_episode_file"
    quality_fixture >"$quality_cache_file"
    printf 'validated >https://media.test/720.m3u8>\nprepared\n' >>"$quality_cache_file"
    persistent_mpv_alive() { return 0; }
    nth() { cat >/dev/null; printf 'https://media.test/720.m3u8\t720p\n'; }
    stop_continuous_worker() { : >"$test_dir/worker-stopped"; }
    start_continuous_worker_for_current_player() { return 0; }
    probe_link_with_mpv() { return 1; }
    quality=best
    ! change_quality_from_menu
    [ ! -f "$test_dir/worker-stopped" ]
    [ ! -f "$mpv_session_command_file" ]
    [ "$quality" = best ]
    ! quality_menu_available
    # A working selection queues the chosen URL with its own request metadata.
    printf 'validated >https://media.test/720.m3u8>\n' >>"$quality_cache_file"
    probe_link_with_mpv() { return 0; }
    change_quality_from_menu
    [ "$quality" = 720 ]
    [ "$selected_quality" = 720 ]
    grep -Fq '"url":"https://media.test/720.m3u8"' "$mpv_session_command_file"
    grep -Fq '"headers":"Origin:https://player.test"' "$mpv_session_command_file"
    grep -Fq '"referrer":"https://player.test/"' "$mpv_session_command_file"
    grep -Fq '"keep_position":true' "$mpv_session_command_file"
)
printf 'Random episodes, paginated catalogs and validated quality gating passed.\n'
