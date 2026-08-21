# ani-cli-mx

`ani-cli-mx` is a Spanish-first anime CLI for the terminal.

This is an independent community project. It is not affiliated with, maintained by, or endorsed by any other project or team.

This project prefers these sources in order:

1. JKAnime
2. AnimeAV1
3. AnimeFLV
4. AniDB as the maintained English fallback
5. AnimeX as the second English fallback, with multiple mirrors

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
<summary>Windows With Scoop (No WSL)</summary>

This is native Windows support through Git Bash. Git for Windows provides the
shell runtime, while mpv, fzf, and ani-cli-mx run as Windows applications. WSL
is not used.

Install Scoop if it is not already available:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

Install Git before adding buckets. Scoop buckets are Git repositories, so this
bootstrap step must happen before Scoop can clone `extras` or the ani-cli-mx
bucket:

```powershell
scoop install git
```

Add the required buckets and install ani-cli-mx:

```powershell
scoop bucket add extras
scoop bucket add ani-cli-mx https://github.com/Gildedboy/ani-cli-mx
scoop install ani-cli-mx
```

The package installs curl, grep, sed, OpenSSL, fzf, and mpv as declared runtime
dependencies. Git for Windows supplies the Bash runtime. Windows Terminal is
recommended; run ani-cli-mx from PowerShell or from its Git Bash profile:

```powershell
ani-cli-mx "blue lock"
```

Optional download and alternate-player tools:

```powershell
scoop install aria2 ffmpeg yt-dlp
scoop install vlc
```

The Windows launcher resolves Git for Windows explicitly and does not invoke
the legacy WSL `bash.exe`.

The standalone Git Bash window uses Mintty and may not interact correctly with
fzf. Prefer a Git Bash profile hosted by Windows Terminal when you want a Bash
prompt.

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
<summary>Windows With Scoop</summary>

```powershell
scoop update
scoop update ani-cli-mx
```

`ani-cli-mx -U` delegates to Scoop for a Scoop-managed Windows installation.

</details>

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
<summary>Windows With Scoop</summary>

```powershell
scoop uninstall ani-cli-mx
```

To remove the bucket registration as well:

```powershell
scoop bucket rm ani-cli-mx
```

If these applications were installed only for ani-cli-mx and are not used by
anything else, they can also be removed:

```powershell
scoop uninstall mpv fzf curl grep sed
```

Remove optional download tools or VLC only if you installed them specifically
for ani-cli-mx:

```powershell
scoop uninstall aria2 ffmpeg yt-dlp vlc
```

The `extras` bucket may also be removed when no other installed application
uses it:

```powershell
scoop bucket rm extras
```

If Scoop itself was installed exclusively for ani-cli-mx, Scoop's complete
uninstaller removes Scoop and every application it manages:

```powershell
scoop uninstall scoop
```

History is stored under `%LOCALAPPDATA%\ani-cli-mx`. Scoop does not remove that
user data automatically. Remove it only if the watch history is no longer
needed:

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\ani-cli-mx"
```

</details>

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
- a supported player, usually `mpv`

Platform notes:

- on Windows, Git for Windows supplies Bash and the required POSIX utilities;
  the official launcher avoids WSL
- on Windows, the default history directory is `%LOCALAPPDATA%\ani-cli-mx`
- `iina` is supported as a macOS player path
- `vlc` is supported with `--vlc`
### Optional Dependencies

- `curl-impersonate` (`curl_chrome116` or a compatible wrapper) for AniDB search and playback; AniDB currently rejects regular `curl` through Cloudflare
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

Use the maintained English source directly (requires `curl-impersonate`):

```sh
ani-cli-mx --source anidb "one piece"
```

`ANI_CLI_ANIDB_CURL` can point to a compatible curl-impersonate executable when its installed name is not one of the detected wrappers.

Use AnimeX directly (regular `curl` is sufficient):

```sh
ani-cli-mx --source animex "baki"
```

Automatic searches group the selector into contiguous `[ESPAÑOL]` results followed by `[ENGLISH]` results from AniDB and AnimeX.

By default, ani-cli-mx keeps using the chosen Spanish source for the rest of the session, falling back to the normal source search if it stops producing valid links:

```sh
ani-cli-mx "one piece"
```

Fast mode starts playback from the first Spanish source that produces a valid playable link, instead of waiting for every source to finish checking.

When an anime already exists in history, the episode selector marks the last watched episode with `*` and shows the legend in the prompt:

```text
Selecciona episodio (* ultimo visto):
1
2
3 *
4
```

Use the previous classic source search behavior:

```sh
ani-cli-mx --classic "one piece"
```

Start in continuous playback mode:

```sh
ani-cli-mx --continuous "one piece"
```

Detached interactive mpv playback reuses one player process and window for Next, Previous, Repeat, and episode selection. Each selected episode replaces the media in that window, so fullscreen, maximized state, window geometry, and volume remain unchanged naturally. Leaving the ani-cli-mx playback menu closes this managed mpv window. `--no-detach`, `--exit-after-play`, episode ranges, and `--skip` retain the separate-process behavior required by those modes.

Continuous mode requires mpv. With `--continuous`, ani-cli-mx starts playback and opens the playback menu with continuous mode already enabled. After a natural end-of-file event, it resolves and loads the next episode in the same mpv window. Manual Next, Previous, Repeat, and episode-selection actions replace the current media without being mistaken for automatic advancement. The menu can toggle continuous mode with `activar_modo_continuo` or `desactivar_modo_continuo`.

Restart the tracked player instead of reusing its window when opening another episode from the playback menu:

```sh
ani-cli-mx --close-previous "one piece"
```

You can also toggle this behavior from the playback menu with `activar_cerrar_reproductor_anterior` or `desactivar_cerrar_reproductor_anterior`.

Download episodes:

```sh
ani-cli-mx -d -e 1-3 "cyberpunk edgerunners"
```

The playback menu also includes `descargar_episodio_actual`. Missing download
tools are installed with the available system package manager. Downloads go to
the user's Downloads/Descargas folder by default.

More options are available in:

- `ani-cli-mx --help`

## FAQ

Is there an official AUR package right now?

- Yes. Stable releases use `ani-cli-mx`; development builds use `ani-cli-mx-git`.

Are Ubuntu-based distros supported right now?

- Yes. Add the PPA above, then install with `sudo apt install ani-cli-mx`.

Is WSL supported right now?

- Yes. Use your WSL distro of choice and follow the matching install path above.

Is Windows supported without WSL?

- Yes. Install the official Scoop package. Git for Windows supplies Bash, but
  playback and every dependency run directly on Windows.

Why `ani-cli-mx-git` instead of `ani-cli-mx` for Arch packaging?

- `ani-cli-mx-git` follows the development branch. Stable releases use `ani-cli-mx`.

Can I choose a different player?

- Yes. Use `--vlc` or set `ANI_CLI_PLAYER`.

Can I change the download directory?

- Yes. Set `ANI_CLI_DOWNLOAD_DIR`.

Can I change subtitle language or turn subtitles off?

- Most Spanish sources bake subtitles into the video. When AnimeX supplies external caption tracks, ani-cli-mx loads all of them into mpv automatically; mpv's normal subtitle controls can then switch, show, or hide them.

Can I change dub language?

- No. The project only switches between subbed and dubbed availability.

Can I change media source manually?

- Yes. Fast mode is the default, so ani-cli-mx keeps using the source you choose for later episodes in the same session. Use `--classic`, `--slow`, or `--no-fast` for the previous per-episode source search. You can also influence search/info with `--source`.

Can I adjust resolution?

- Yes. Use `-q`, for example `ani-cli-mx -q 1080 "blue lock"`.

How can I download?

- Use `-d` or choose `descargar_episodio_actual` from the playback menu. Files
  download into Downloads/Descargas unless `ANI_CLI_DOWNLOAD_DIR` is set.

How can I bulk download?

- Use `-d -e start-end`, for example `ani-cli-mx "one piece" -d -e 1-1000`.

## Docs

- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [hacking.md](./hacking.md)
- [disclaimer.md](./disclaimer.md)

## Important

This project accesses public-facing websites for its streaming and downloading capabilities and primarily acts as a Spanish-first anime terminal client. The developer(s) of this application have no affiliation with these content providers. This application hosts zero content and is intended for educational and personal use only. Use at your own risk.

[Read the Full Disclaimer](./disclaimer.md)
