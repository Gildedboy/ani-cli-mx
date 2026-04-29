# ani-cli-mx

`ani-cli-mx` is a Spanish-first anime CLI for the terminal.

This is an independent community project. It is not affiliated with, maintained by, or endorsed by any other project or team.

This project prefers these sources in order:

1. AnimeFLV
2. JKAnime
3. AnimeAV1
4. an English fallback when Spanish sources fail

## Table of Contents

- [Install](#install)
- [Update](#update)
- [Uninstall](#uninstall)
- [Dependencies](#dependencies)
  - [Optional Dependencies](#optional-dependencies)
  - [Ani-Skip](#ani-skip)
- [Usage](#usage)
- [FAQ](#faq)
- [Docs](#docs)
- [Important](#important)

## Install

Choose the distro path that already works for you.

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

`ani-cli-mx-git` is the separate development version.

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
- `mpv` works best with WSLg. Install it on Windows with Scoop:

  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  scoop install mpv
  ```

</details>

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

## Update

<details>
<summary>Arch-Based Distros With AUR</summary>

```sh
yay -Syu ani-cli-mx
paru -Syu ani-cli-mx
```

For the development package:

```sh
yay -Syu ani-cli-mx-git
paru -Syu ani-cli-mx-git
```

</details>

<details>
<summary>Ubuntu-Based Distros With PPA</summary>

```sh
sudo apt update
sudo apt upgrade ani-cli-mx
```

</details>

<details>
<summary>Manual Install</summary>

For manual installs, pull the repo again and reinstall the files:

System-wide:

```sh
git pull
sudo install -Dm755 ani-cli-mx-core /usr/local/libexec/ani-cli-mx
sudo install -Dm755 ani-cli-mx /usr/local/bin/ani-cli-mx
sudo install -Dm644 ani-cli-mx.1 /usr/local/share/man/man1/ani-cli-mx.1
hash -r
```

User-local:

```sh
git pull
install -Dm755 ani-cli-mx-core "$HOME/.local/libexec/ani-cli-mx"
install -Dm755 ani-cli-mx "$HOME/.local/bin/ani-cli-mx"
install -Dm644 ani-cli-mx.1 "$HOME/.local/share/man/man1/ani-cli-mx.1"
hash -r
```

If you want `ani-cli-mx -U` to work for a manual install, set `ANI_CLI_UPDATE_URL` to this project's raw script URL:

```sh
export ANI_CLI_UPDATE_URL="https://raw.githubusercontent.com/Gildedboy/ani-cli-mx/main/ani-cli-mx-core"
```

Example:

```sh
ANI_CLI_UPDATE_URL=https://raw.githubusercontent.com/Gildedboy/ani-cli-mx/main/ani-cli-mx-core ani-cli-mx -U
```

`ani-cli-mx -U` is only for manual installs.

</details>

## Uninstall

<details>
<summary>Arch-Based Distros With AUR</summary>

Stable package:

```sh
yay -Rns ani-cli-mx
paru -Rns ani-cli-mx
```

Development package:

```sh
yay -Rns ani-cli-mx-git
paru -Rns ani-cli-mx-git
```

</details>

<details>
<summary>Ubuntu-Based Distros With PPA</summary>

```sh
sudo apt remove ani-cli-mx
sudo add-apt-repository --remove ppa:gilded30/ani-cli-mx
sudo apt update
```

</details>

<details>
<summary>Manual Install</summary>

System-wide:

```sh
sudo rm -f /usr/local/bin/ani-cli-mx
sudo rm -f /usr/local/libexec/ani-cli-mx
sudo rm -f /usr/local/share/man/man1/ani-cli-mx.1
hash -r
```

User-local:

```sh
rm -f "$HOME/.local/bin/ani-cli-mx"
rm -f "$HOME/.local/libexec/ani-cli-mx"
rm -f "$HOME/.local/share/man/man1/ani-cli-mx.1"
hash -r
```

Optional history cleanup:

```sh
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/ani-cli-mx"
```

Check whether another `ani-cli-mx` command is still earlier in your `PATH`:

```sh
command -v -a ani-cli-mx
```

</details>

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

Keep using the chosen Spanish source for the rest of the session, falling back to the normal source search if it stops producing valid links:

```sh
ani-cli-mx -f "one piece"
```

Download episodes:

```sh
ani-cli-mx -d -e 1-3 "cyberpunk edgerunners"
```

More options are available in:

- `ani-cli-mx --help`

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

- Yes. Use `-f` to keep using the source you choose for later episodes in the same session. You can also influence search/info with `--source`.

Can I adjust resolution?

- Yes. Use `-q`, for example `ani-cli-mx -q 1080 "blue lock"`.

How can I download?

- Use `-d`. Files download into the current directory unless `ANI_CLI_DOWNLOAD_DIR` is set.

How can I bulk download?

- Use `-d -e start-end`, for example `ani-cli-mx "one piece" -d -e 1-1000`.

## Docs

- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [hacking.md](./hacking.md)
- [disclaimer.md](./disclaimer.md)

## Important

This project accesses public-facing websites for its streaming and downloading capabilities and primarily acts as a Spanish-first anime terminal client. The developer(s) of this application have no affiliation with these content providers. This application hosts zero content and is intended for educational and personal use only. Use at your own risk.

[Read the Full Disclaimer](./disclaimer.md)
