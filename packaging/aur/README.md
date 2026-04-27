## AUR Packaging Notes

If both packages install `/usr/bin/ani-cli-mx`, they must conflict.

To allow side-by-side installs:

- `ani-cli-mx` owns the canonical command: `ani-cli-mx`
- `ani-cli-mx-git` owns the development command: `ani-cli-mx-git`

That avoids file conflicts and also keeps separate state/history names for each package.

Tradeoff:

- existing `ani-cli-mx-git` users who currently expect the `ani-cli-mx` command would need to switch to `ani-cli-mx-git`

If you want the `-git` package to keep the canonical `ani-cli-mx` command instead, then `ani-cli-mx` and `ani-cli-mx-git` should explicitly conflict and cannot be installed together.

Before publishing the stable package:

1. cut a real release tag that matches `pkgver`
2. replace the stable package checksum with a real value
3. generate `.SRCINFO` for each AUR repo with `makepkg --printsrcinfo > .SRCINFO`

Recommended release tag format:

- Git tag: `v1.0.0`
- PKGBUILD `pkgver`: `1.0.0`

The stable PKGBUILD in this repository assumes that `v`-prefixed tag style.

Versioning recommendation:

- keep the implementation script's `version_number` aligned with this project's own release line
- tag stable releases in this repo with the same project-owned version, for example `v1.0.0`
- if you need a follow-up release, use a pacman-safe suffix such as `1.0.1` or `1.0.0.mx1`

This project is versioned independently. Do not mirror any outside project's release numbers in package metadata or user-facing `--version` output.
