# ani-cli-mx

`ani-cli-mx` is a Spanish-first anime CLI for the terminal.

This is an independent community project. It is not affiliated with, maintained by, or endorsed by any other project or team.

This project prefers these sources in order:

1. AnimeFLV
2. JKAnime
3. AnimeAV1
4. an English fallback when Spanish sources fail

Repository: <https://github.com/Gildedboy/ani-cli-mx>

## Table of Contents

- [Status](#status)
- [Install](#install)
  - [Run From Clone](#run-from-clone)
  - [Manual Install](#manual-install)
  - [AUR](#aur)
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

- The command name for this project is `ani-cli-mx`.
- This repository does not currently publish official binaries or installers.
- This project now has a published AUR package: `ani-cli-mx-git`.

Available now:

- run from a clone as `ani-cli-mx`
- manual install into `bin/` + `libexec/` as `ani-cli-mx`
- AUR install through the current development package

Planned:

- add a Scoop manifest for Windows
- add Debian packaging or an apt repository workflow
- publish stable `ani-cli-mx` releases

## Install

Choose the install path that matches how you want to run it.

The launcher in [ani-cli-mx](./ani-cli-mx) looks for the main script in these two places:

- `./ani-cli-mx-core`
- `../libexec/ani-cli-mx`

That means clone/manual installs use the `ani-cli-mx` launcher. The current AUR development package uses a separate command so it can coexist with future stable packaging.

<details>
<summary>Run From Clone</summary>

Command: `./ani-cli-mx`

```sh
git clone https://github.com/Gildedboy/ani-cli-mx.git
cd ani-cli-mx
./ani-cli-mx
```

</details>

<details>
<summary>Manual Install</summary>

Command after install: `ani-cli-mx`

System-wide:

```sh
git clone https://github.com/Gildedboy/ani-cli-mx.git
cd ani-cli-mx
sudo install -Dm755 ani-cli-mx-core /usr/local/libexec/ani-cli-mx
sudo install -Dm755 ani-cli-mx /usr/local/bin/ani-cli-mx
sudo install -Dm644 ani-cli-mx.1 /usr/local/share/man/man1/ani-cli-mx.1
```

User-local:

```sh
git clone https://github.com/Gildedboy/ani-cli-mx.git
cd ani-cli-mx
install -Dm755 ani-cli-mx-core "$HOME/.local/libexec/ani-cli-mx"
install -Dm755 ani-cli-mx "$HOME/.local/bin/ani-cli-mx"
install -Dm644 ani-cli-mx.1 "$HOME/.local/share/man/man1/ani-cli-mx.1"
```

</details>

<details>
<summary>AUR With yay</summary>

Package: `ani-cli-mx-git`  
Command after install: `ani-cli-mx-git`

```sh
yay -S ani-cli-mx-git
```

</details>

<details>
<summary>AUR With paru</summary>

Package: `ani-cli-mx-git`  
Command after install: `ani-cli-mx-git`

```sh
paru -S ani-cli-mx-git
```

</details>

<details>
<summary>apt (Future)</summary>

Not available yet.

Planned target:

- a stable package that would install the `ani-cli-mx` command

</details>

<details>
<summary>Scoop (Future)</summary>

Not available yet.

Planned target:

- a stable package that would install the `ani-cli-mx` command

</details>

### AUR

The published Arch package for this project is:

- `ani-cli-mx-git`

Why `ani-cli-mx-git` instead of `ani-cli-mx`?

- because this repo does not currently publish tagged releases
- for a Git-tracking Arch package, the `-git` suffix is the correct format
- stable `ani-cli-mx` packaging makes sense once this project adopts tagged releases

## Planned Packaging

Later targets:

- Scoop for Windows
- Debian/apt packaging

This repository now includes draft Arch packaging files under [packaging/aur](./packaging/aur).

Those are not available yet, so the README should not advertise them as working install commands today.

## Update

If you are running from a clone:

```sh
git pull
```

If you installed manually, pull the repo again and reinstall the files.

If you want `ani-cli-mx -U` to work, set `ANI_CLI_UPDATE_URL` to this project's raw script URL:

```sh
export ANI_CLI_UPDATE_URL="https://raw.githubusercontent.com/Gildedboy/ani-cli-mx/master/ani-cli-mx-core"
```

Example:

```sh
ANI_CLI_UPDATE_URL=https://raw.githubusercontent.com/Gildedboy/ani-cli-mx/master/ani-cli-mx-core ani-cli-mx -U
```

Important:

- `ani-cli-mx -U` is for clone/manual installs
- AUR installs should update through `yay`, `paru`, or `pacman` tooling, not by self-patching with `-U`
- once Scoop or apt packaging exists, those installs should update through their package manager too

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

If you installed from AUR:

```sh
sudo pacman -Rns ani-cli-mx-git
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

If you installed from the current AUR development package, replace `ani-cli-mx` in the examples below with `ani-cli-mx-git`.

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

Is there an official AUR package right now?

- Yes. The current AUR package name is `ani-cli-mx-git`.

Are apt and Scoop supported right now?

- No. They are planned targets, not current install methods.

Why `ani-cli-mx-git` instead of `ani-cli-mx` for Arch packaging?

- Because this repo currently has no tagged releases, a `-git` package is the honest format, and giving it the `ani-cli-mx-git` command leaves `ani-cli-mx` available for a future stable package.

Can I choose a different player?

- Yes. Use `--vlc` or set `ANI_CLI_PLAYER`.

Can I change the download directory?

- Yes. Set `ANI_CLI_DOWNLOAD_DIR`.

Can I change subtitle language or turn subtitles off?

- No. For these sources, subtitles are typically baked into the video.

Can I change dub language?

- No. The project only switches between subbed and dubbed availability.

Can I change media source manually?

- Not as a stable playback picker. You can influence search/info with `--source`, but playback still follows the project's source-selection logic.

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
