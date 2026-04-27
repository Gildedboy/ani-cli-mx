# Contribution Guidelines

## Pull Requests

- Keep shell scripts executable.
- Update `version_number` in `ani-cli-mx-core` when a release-worthy user-facing change requires it.
- Update `README.md` and `ani-cli-mx.1` when behavior or flags change.
- Avoid adding dependencies unless they are clearly justified.
- Keep changes focused; unrelated cleanup should be split into a separate pull request.
- Test the paths you modified. For script changes, that usually means at least search, episode selection, and playback or debug-mode link output.

## Issues

- Use the issue templates.
- Include the exact command you ran, such as `ani-cli-mx` or `ani-cli-mx-git`.
- Include your version from `ani-cli-mx -V` or `ani-cli-mx-git -V`.
- Include your OS, shell, and the title/source involved when relevant.
- Add screenshots or terminal output when they help explain the problem.

## Other Ways To Help

- Test changes on your platform and report regressions clearly.
- Improve documentation when behavior, packaging, or install steps change.
- Help reproduce bugs and confirm fixes in issues or pull requests.
