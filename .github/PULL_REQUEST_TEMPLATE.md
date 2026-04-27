# Pull Request Template

## Type of change

- [ ] Bug fix
- [ ] Feature
- [ ] Documentation update

## Description

*ramble here*

## Checklist

- [ ] tested the main user path affected by this change
- [ ] bumped `version_number` in `ani-cli-mx-core` if a release-facing version change is needed
---
- [ ] next, prev and replay work
- [ ] `-c` history and continue work
- [ ] `-d` downloads work
- [ ] `-s` syncplay works
- [ ] `-q` quality works
- [ ] `-v` vlc works
- [ ] `-e` (select episode) aka `-r` (range selection) works
- [ ] `-S` select index works
- [ ] `--skip` ani-skip works
- [ ] `--skip-title` ani-skip title argument works
- [ ] `--no-detach` no detach works
- [ ] `--exit-after-play` auto exit after playing works
- [ ] `--nextep-countdown` countdown to next ep works
- [ ] `--dub` and regular (sub) mode both work
- [ ] modified providers return links as expected (use debug mode if needed)
---
- [ ] `-h` help info is up to date
- [ ] README is up to date
- [ ] Man page is up to date

## Additional Test Cases

- The safe bet: One Piece
- Episode 0: Saenai Heroine no Sodatekata ♭
- Unicode: Saenai Heroine no Sodatekata ♭
- Non-whole episodes: Tensei shitara slime datta ken (ep. 24.5, ep. 24.9)
- Multi-provider checks: use a title that exercises the providers you changed
- The examples of the help text
