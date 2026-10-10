---
name: maintain-ani-cli-providers
description: Diagnose, repair, add, or validate ani-cli-mx anime providers and playback mirrors. Use for missing search results, slow episode discovery, source fallback bugs, scraper markup changes, mpv not opening or exiting, HTTP 403 media failures, new Spanish source integrations, provider regression tests, and provider-related patch releases in this repository.
---

# Maintain ani-cli Providers

Work in `ani-cli-mx-core`; keep `tests/sanity.sh`, `README.md`, `ani-cli-mx.1`, and Windows version assertions synchronized when behavior or versions change.

## Diagnose end to end

Inspect the affected layer before editing. Use only the diagnostic steps relevant to the reported failure:

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
- Keep provider references prefixed (`animeav1:`, `jkanime:`, `animex:`) so authoritative episode catalogs and fast-mode reuse remain source-aware.
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

## Proportionate testing

Choose the smallest set of checks that can detect a plausible regression in
the changed behavior. Briefly connect each test group to the behavior or risk
it covers; a higher test count is not an objective.

- Documentation or wording-only changes need review and `git diff --check`,
  not provider requests or playback tests. For small shell edits, use `sh -n`
  on affected scripts plus a focused behavioral check when needed.
- Prefer existing focused tests. Add a regression only for a meaningful bug,
  edge case, or new behavior that lacks coverage; avoid implementation-mirroring
  assertions and redundant tests for trivial reversible changes.
- For a parser/provider fix, check the affected fixture and provider/title.
  For playback, headers, or fallback fixes, exercise the affected mirror and
  verify decoded playback when necessary; a successful manifest alone is insufficient.
- Run broader checks for shared selection/network/player changes, several
  affected providers, dependency/packaging changes, unexplained failures, or
  an explicit request. Publishing alone does not require unrelated live sweeps.
- `tests/sanity.sh --syntax` also runs local regressions; it is not just a
  syntax check. The script currently has no per-test filter. Use the full
  local suite when shared behavior warrants it or a trustworthy focused
  check is impractical; do not invent filtering flags. Run `--network` only
  when its broader live coverage is justified.
- Once relevant checks pass, stop testing unless a new edit, failure, or
  unresolved concern warrants another run. Reuse results for unchanged code;
  do not rerun a successful build solely to repeat tests.
- Keep successful logs out of the conversation. Report a short result and
  meaningful limitations; inspect failure details only as needed. Shell test
  execution does not itself consume model tokens, but log ingestion does.

## Verify and release

Always review the diff, and select tests using the policy above:

```sh
git diff --check
```

When regression coverage is warranted, cover the observed title, provider,
mirror sequence, or player arguments. Verify real playback in attached mode
for player bugs. Summarize what was checked and why broader tests were unnecessary
or remain pending when that distinction matters.

For a release-worthy change:

1. Bump `version_number` and synchronize `tests/sanity.sh` plus `.github/workflows/windows.yml`.
2. Incorporate any automated package-manifest commit already on `origin/main` before committing.
3. Commit and push intentionally.
4. Publish the matching GitHub release. The release event dispatches the packaging repository.
5. Confirm the `Dispatch packaging release` workflow succeeds; fetch and fast-forward any automated Scoop manifest update.
