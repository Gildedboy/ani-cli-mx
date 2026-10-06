# PelisPlusHD slow mirror fix — 3.0.9

## Report

On Windows with 3.0.8, Elementary season 7 episode 2 loaded the episode page,
Embed69, and the difficulty-3 POW successfully. The Vidhide mirror request then
failed with curl 28 after approximately 15 seconds. Mirror fallback exhausted
without a playable result. The user reported that setting resolver and probe
limits to 45 seconds allowed Vidhide to respond and actual playback to start.

## Change

PelisPlusHD mirror pages and HLS manifests now default to a 45-second request
limit. PelisPlusHD first-frame probes also default to 45 seconds, including the
final selected-quality probe. Catalog/search limits and anime provider defaults
remain at their existing values. Explicit global timeout settings are respected;
PelisPlusHD-specific resolver/probe settings can override them.

A failed mirror-page request is rejected immediately and does not parse partial
output. It is attempted once before the resolver proceeds to another mirror;
the previous curl retries could repeat the entire timeout. HLS manifest requests
retain the final mirror-page referrer. Debug output identifies the mirror URL
and active timeout.

## Verification

- Local syntax and fixture regressions passed, including a simulated mirror that
  requires 30 seconds: the 15-second setting fails and the new 45-second setting
  yields valid HLS variants.
- Fixtures check failed requests, final referrer, global/specific overrides, and
  separate PelisPlusHD/anime probe deadlines.
- Live CLI resolution of Elementary s7e2 passed using default settings and
  decoded a frame in mpv before selecting Vidhide HLS.
- The full network suite stopped at its precondition: curl-impersonate is absent
  for AniDB. This run does not establish current live anime provider coverage.
- Actual Windows playback with the equivalent 45-second overrides was confirmed
  by the reporting user. General Windows launcher checks run in release CI.

A 45-second limit can still fail when a mirror is unreachable. This change fixes
the observed deadline; it does not establish how many other users were affected.
