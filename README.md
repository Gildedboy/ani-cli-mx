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

- [Install](#install)
- [Update](#update)
- [Uninstall](#uninstall)
- [Dependencies](#dependencies)
  - [Optional Dependencies](#optional-dependencies)
  - [Ani-Skip](#ani-skip)
- [Usage](#usage)
- [FAQ](#faq)
- [Homies](#homies)
- [Docs](#docs)

## Install

Choose the distro path that already works for you.

The launcher in [ani-cli-mx](./ani-cli-mx) looks for the main script in these two places:

- `./ani-cli-mx-core`
- `../libexec/ani-cli-mx`
- `/usr/lib/ani-cli-mx/ani-cli-mx-core`

That means repository installs and distro packages use the `ani-cli-mx` launcher. The development Arch package keeps the separate `ani-cli-mx-git` command.

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
<summary>Arch-Based Distros With AUR</summary>

Stable package: `ani-cli-mx`

Command after install: `ani-cli-mx`

```sh
yay -S ani-cli-mx
paru -S ani-cli-mx
```

Development package: `ani-cli-mx-git`

Command after install: `ani-cli-mx-git`

```sh
yay -S ani-cli-mx-git
paru -S ani-cli-mx-git
```

</details>

<details>
<summary>Ubuntu-Based Distros With PPA</summary>

Command after install: `ani-cli-mx`

Add the PPA and install:

```sh
sudo add-apt-repository ppa:gilded30/ani-cli-mx
sudo apt update
sudo apt install ani-cli-mx
```

Optional packages:

- `aria2`
- `yt-dlp`
- `vlc`
- `ffmpeg`

</details>

<details>
<summary>WSL</summary>

Use the install path for your WSL distro of choice.

- for Arch-based WSL distros, use the AUR instructions above
- for Ubuntu-based WSL distros, use the PPA instructions above
- run `ani-cli-mx` from inside WSL, not from Windows PowerShell
- `mpv` works best with WSLg

</details>

### AUR

The published Arch packages for this project are:

- `ani-cli-mx`
- `ani-cli-mx-git`

Packaging notes:

- `ani-cli-mx` follows tagged stable releases
- `ani-cli-mx-git` follows the development branch and installs the `ani-cli-mx-git` command
- package recipes are maintained outside this source repository

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
- APT installs should update through `apt`, not by self-patching with `-U`

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
sudo pacman -Rns ani-cli-mx
sudo pacman -Rns ani-cli-mx-git
```

If you installed from APT:

```sh
sudo apt remove ani-cli-mx
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

- Yes. Stable releases use `ani-cli-mx`; development builds use `ani-cli-mx-git`.

Are Ubuntu-based distros supported right now?

- Yes. Add the PPA above, then install with `sudo apt install ani-cli-mx`.

Is WSL supported right now?

- Yes. Use your WSL distro of choice and follow the matching install path above.

Why `ani-cli-mx-git` instead of `ani-cli-mx` for Arch packaging?

- `ani-cli-mx-git` follows the development branch. Stable releases use `ani-cli-mx`.

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
