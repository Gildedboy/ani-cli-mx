# ani-cli-mx

`ani-cli-mx` is a Spanish-first fork of upstream `ani-cli`.

This is an independent community fork. It is not affiliated with, maintained by, or endorsed by the upstream `ani-cli` team or project.

This fork prefers these sources in order:

1. AnimeFLV
2. JKAnime
3. AnimeAV1
4. the original English fallback when Spanish sources fail

Repository: <https://github.com/Gildedboy/ani-cli-mx>

## Table of Contents

- [Status](#status)
- [Install](#install)
  - [Run From Clone](#run-from-clone)
  - [Manual Install](#manual-install)
  - [Arch Packaging / AUR Prep](#arch-packaging--aur-prep)
- [Planned Packaging](#planned-packaging)
- [Update](#update)
- [Uninstall](#uninstall)
- [Dependencies](#dependencies)
  - [Optional Dependencies](#optional-dependencies)
  - [Ani-Skip](#ani-skip)
- [Usage](#usage)
- [FAQ](#faq)
- [Homies](#homies)
- [Docs](#docs)

## Status

- The command name for this fork is `ani-cli-mx`.
- `ani-cli-mx` is an independent project and should not be confused with the upstream `ani-cli` project or team.
- This repository does not currently publish official binaries or installers.
- This repository does not currently have a published AUR package.
- The repo now includes an Arch packaging scaffold for `ani-cli-mx-git`, which is the honest AUR target until tagged releases exist.

Available now:

- run from a clone
- manual install into `bin/` + `libexec/`
- local Arch packaging scaffold for `ani-cli-mx-git`

Planned:

- publish `ani-cli-mx-git` to AUR
- add a Scoop manifest for Windows
- add Debian packaging or an apt repository workflow
- later, if tagged releases exist, consider a stable `ani-cli-mx` package in addition to `ani-cli-mx-git`

## Install

The launcher in [ani-cli-mx](./ani-cli-mx) only looks for the main script in these two places:

- `./ani-cli`
- `../libexec/ani-cli-mx`

That means the supported install layouts are:

1. run directly from a clone
2. install `ani-cli-mx` into `bin/` and `ani-cli` into sibling `libexec/`

Commands like `apt install ani-cli`, `dnf install ani-cli`, `yay -S ani-cli`, or `scoop install ani-cli` do not install this fork.

### Run From Clone

```sh
git clone https://github.com/Gildedboy/ani-cli-mx.git
cd ani-cli-mx
./ani-cli-mx
```

### Manual Install

System-wide:

```sh
git clone https://github.com/Gildedboy/ani-cli-mx.git
cd ani-cli-mx
sudo install -Dm755 ani-cli /usr/local/libexec/ani-cli-mx
sudo install -Dm755 ani-cli-mx /usr/local/bin/ani-cli-mx
sudo install -Dm644 ani-cli-mx.1 /usr/local/share/man/man1/ani-cli-mx.1
```

User-local:

```sh
git clone https://github.com/Gildedboy/ani-cli-mx.git
cd ani-cli-mx
install -Dm755 ani-cli "$HOME/.local/libexec/ani-cli-mx"
install -Dm755 ani-cli-mx "$HOME/.local/bin/ani-cli-mx"
install -Dm644 ani-cli-mx.1 "$HOME/.local/share/man/man1/ani-cli-mx.1"
```

### Arch Packaging / AUR Prep

This repository now includes an Arch package scaffold at [packaging/aur/ani-cli-mx-git/PKGBUILD](./packaging/aur/ani-cli-mx-git/PKGBUILD).

Important:

- it is not published on AUR yet
- because the repo has no tags today, the realistic package name is `ani-cli-mx-git`, not a fake stable `ani-cli-mx`

To build it locally on Arch:

```sh
cd packaging/aur/ani-cli-mx-git
makepkg -si
```

Once the package is actually published to AUR, then `yay -S ani-cli-mx-git` would become a true install method.

## Planned Packaging

The packaging roadmap is tracked in [packaging/README.md](./packaging/README.md).

Near-term target:

- AUR as `ani-cli-mx-git`

Later targets:

- Scoop for Windows
- Debian/apt packaging

Those are not available yet, so the README should not advertise them as working install commands today.

## Update

If you are running from a clone:

```sh
git pull
```

If you installed manually, pull the repo again and reinstall the files.

If you want `ani-cli-mx -U` to work, set `ANI_CLI_UPDATE_URL` to this fork's raw script URL:

```sh
export ANI_CLI_UPDATE_URL="https://raw.githubusercontent.com/Gildedboy/ani-cli-mx/master/ani-cli"
```

Example:

```sh
ANI_CLI_UPDATE_URL=https://raw.githubusercontent.com/Gildedboy/ani-cli-mx/master/ani-cli ani-cli-mx -U
```

Important:

- `ani-cli-mx -U` is for clone/manual installs
- once AUR, Scoop, or apt packaging exists, packaged installs should update through their package manager instead of self-patching with `-U`

## Uninstall

If you ran it from a clone, remove the clone directory.

If you installed it manually:

System-wide:

```sh
sudo rm -f /usr/local/bin/ani-cli-mx
sudo rm -f /usr/local/libexec/ani-cli-mx
sudo rm -f /usr/local/share/man/man1/ani-cli-mx.1
```

User-local:

```sh
rm -f "$HOME/.local/bin/ani-cli-mx"
rm -f "$HOME/.local/libexec/ani-cli-mx"
rm -f "$HOME/.local/share/man/man1/ani-cli-mx.1"
```

## Dependencies

Required:

- `curl`
- `sed`
- `grep`
- `fzf`
- `openssl`
- a supported player, usually `mpv`

Platform notes:

- `iina` is supported as a macOS player path
- `vlc` is supported with `--vlc`
- on Termux, the `openssl` CLI lives in the `openssl-tool` package

### Optional Dependencies

- `aria2c` for direct-file download support
- `yt-dlp` for additional extractor coverage and download handling
- `ffmpeg` as the m3u8 download fallback
- `patch` for self-update via `-U`
- `ani-skip` for intro skipping

### Ani-Skip

`ani-skip` is optional and currently only useful with `mpv`.

Project: <https://github.com/synacktraa/ani-skip>

If skip detection misses a title, try `--skip-title <title>`.

## Usage

Search interactively:

```sh
ani-cli-mx
```

Play a specific show:

```sh
ani-cli-mx "blue lock"
```

Play a range:

```sh
ani-cli-mx -e 5-6 "blue lock"
```

Play dubbed if available:

```sh
ani-cli-mx --dub "one piece"
```

Download episodes:

```sh
ani-cli-mx -d -e 1-3 "cyberpunk edgerunners"
```

More options are available in:

- `ani-cli-mx --help`
- [ani-cli-mx.1](./ani-cli-mx.1)

## FAQ

Does this replace upstream `ani-cli`?

- No. This fork is meant to be installed and invoked as `ani-cli-mx`.

Is this part of the upstream `ani-cli` team or project?

- No. `ani-cli-mx` is an independent fork and is not maintained, endorsed, or officially supported by the upstream `ani-cli` team.

Is there an official AUR package right now?

- No. The repo only includes a local packaging scaffold for `ani-cli-mx-git` at the moment.

Are apt and Scoop supported right now?

- No. They are planned targets, not current install methods.

Why `ani-cli-mx-git` instead of `ani-cli-mx` for Arch packaging?

- Because this repo currently has no tagged releases, a `-git` package is the honest format.

Can I choose a different player?

- Yes. Use `--vlc` or set `ANI_CLI_PLAYER`.

Can I change the download directory?

- Yes. Set `ANI_CLI_DOWNLOAD_DIR`.

Can I change subtitle language or turn subtitles off?

- No. For these sources, subtitles are typically baked into the video.

Can I change dub language?

- No. The fork only switches between subbed and dubbed availability.

Can I change media source manually?

- Not as a stable playback picker. You can influence search/info with `--source`, but playback still follows the fork's source-selection logic.

Can I adjust resolution?

- Yes. Use `-q`, for example `ani-cli-mx -q 1080 "blue lock"`.

How can I download?

- Use `-d`. Files download into the current directory unless `ANI_CLI_DOWNLOAD_DIR` is set.

How can I bulk download?

- Use `-d -e start-end`, for example `ani-cli-mx "one piece" -d -e 1-1000`.

## Homies

- [animdl](https://github.com/justfoolingaround/animdl): lightweight anime CLI in Python
- [jerry](https://github.com/justchokingaround/jerry): anime streaming with AniList sync and Discord presence
- [anipy-cli](https://github.com/sdaqo/anipy-cli): a Python rewrite of `ani-cli`
- [mangal](https://github.com/metafates/mangal): manga reader/downloader with AniList sync
- [lobster](https://github.com/justchokingaround/lobster): terminal movies and series
- [mov-cli](https://github.com/mov-cli/mov-cli): terminal streaming framework in Python
- [dra-cla](https://github.com/CoolnsX/dra-cla): Korean drama equivalent of `ani-cli`
- [redqu](https://github.com/port19x/redqu): media-centric Reddit client
- [doccli](https://github.com/TowarzyszFatCat/doccli): anime CLI for Polish subtitles
- [GoAnime](https://github.com/alvarorichard/GoAnime): TUI anime browser/player/downloader in Go
- [Curd](https://github.com/Wraient/curd): anime CLI with AniList, Discord RPC, and skip support
- [FastAnime](https://github.com/Benex254/FastAnime): browser-like anime terminal experience
- [ani-skip](https://github.com/KilDesu/ani-skip): skip opening and ending sequences for IINA on macOS

## Docs

- [ani-cli-mx.1](./ani-cli-mx.1)
- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [hacking.md](./hacking.md)
- [disclaimer.md](./disclaimer.md)
