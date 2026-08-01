---
name: maintain-ani-cli-providers
description: Diagnose, repair, add, or validate ani-cli-mx anime providers and playback mirrors. Use for missing search results, slow episode discovery, source fallback bugs, scraper markup changes, mpv not opening or exiting, HTTP 403 media failures, new Spanish source integrations, provider regression tests, and provider-related patch releases in this repository.
---

# Maintain ani-cli Providers

Work in `ani-cli-mx-core`; keep `tests/sanity.sh`, `README.md`, `ani-cli-mx.1`, and Windows version assertions synchronized when behavior or versions change.

## Diagnose end to end

Test each layer separately before editing:

1. Fetch the live search endpoint and run the exact parser pipeline from the script.
2. Run the CLI with `ANI_CLI_PLAYER=debug ANI_CLI_NO_DETACH=1` to inspect IDs, mirrors, referrers, source labels, and the selected URL.
3. Run `sh -x` and filter for the relevant provider functions when valid parser output disappears inside the CLI.
4. Reproduce player failures with `ANI_CLI_NO_DETACH=1` and a timeout. Detached mode suppresses mpv errors and can make an immediate 403 exit look like mpv never opened.
5. Distinguish provider failure from mirror failure. Exhaust valid mirrors for the selected provider before falling back to another provider.

Use a concrete title and episode supplied by the user. Preserve the exact title spelling in the regression test.

## Validate search and episode discovery

- Do not assume a short query is the problem. Print the final requested URL; shell command substitutions can concatenate outputs that lack terminating newlines.
- Compare live markup with the parser’s structural assumptions and split records before applying greedy `sed` expressions.
- Prefer stable public JSON endpoints when HTML search is cached or ignores query parameters.
- Keep provider references prefixed (`animeflv:`, `animeav1:`, `jkanime:`) so authoritative episode catalogs and fast-mode reuse remain source-aware.
- For paginated catalogs, parallelize independent page requests and reject the aggregate if a page fails; do not silently accept an incomplete episode list.

## Validate mirrors as mpv will use them

An HTTP 200 playlist is not proof of playback. Validate at least one decoded frame with `probe_link_with_mpv` when a host can protect segments separately from its manifest.

Preserve per-link requirements through selection and launch:

- Referrer: emit or recover `referrer >URL>VALUE` metadata.
- Source and site: retain `source >URL>VALUE` and `site >URL>VALUE`.
- Required HTTP headers: pass the same fields during both validation and final player launch.

For `player.zilla-networks.com`, segment access currently requires same-origin fetch fields in addition to the player referrer:

```text
Origin:https://player.zilla-networks.com,Sec-Fetch-Dest:empty,Sec-Fetch-Mode:cors,Sec-Fetch-Site:same-origin
```

Keep this value centralized in `zilla_header_fields`. Pass it through mpv’s `--http-header-fields` and IINA’s corresponding `--mpv-` option. Verify with an attached mpv run; browser success alone is insufficient because browsers may add headers, JavaScript state, or challenge cookies.

Do not accept a URL merely because `yt-dlp --get-url` returned text. Some unsupported embed pages are returned unchanged. Probe the resulting direct URL with its embed referrer before marking the mirror valid.

## Add or restore a provider

Integrate a Spanish provider at every peer-source boundary:

- `normalize_info_source`, `info_source_label`, `site_name_from_ref`, `source_key_from_label`, and `is_spanish_source`
- search variants and `search_anime_for_source`
- automatic search aggregation
- episode-list dispatch and automatic episode fallback
- `resolve_spanish_source_links` and `store_spanish_links_for_source`
- `available_site_entries`, `set_links_for_site`, and `pick_spanish_source_links`
- fast-mode source seeding and disabling
- help, man page, README, diagnostics, and tests

Do not replace or rename an existing provider while adding another peer. Keep provider-specific base URLs separate even when old variable names are misleading; refactor shared names only with coverage for every consumer.

## Verify and release

Run:

```sh
./tests/sanity.sh --syntax
./tests/sanity.sh --network
git diff --check
```

Add a focused regression that fails for the observed title, provider, mirror sequence, or player arguments. Verify real playback in attached mode for player bugs.

For a release-worthy change:

1. Bump `version_number` and synchronize `tests/sanity.sh` plus `.github/workflows/windows.yml`.
2. Incorporate any automated package-manifest commit already on `origin/main` before committing.
3. Commit and push intentionally.
4. Publish the matching GitHub release. The release event dispatches the packaging repository.
5. Confirm the `Dispatch packaging release` workflow succeeds; fetch and fast-forward any automated Scoop manifest update.
