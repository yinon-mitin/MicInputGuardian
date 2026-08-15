# Contributing

Thank you for helping improve Mic Input Guardian.

## Development setup

1. Use macOS 13 or later with Xcode 15 or later.
2. Fork and clone the repository.
3. Run `swift test`.
4. Run `./script/build_and_run.sh --verify` to build and smoke-test the app bundle.

## Pull requests

- Keep changes focused and explain the user-visible behavior.
- Add or update tests for policy decisions.
- Preserve the dependency-free CoreAudio implementation unless a dependency has a clear benefit.
- Run `swift test` before opening a pull request.
- Update the README when behavior, requirements, or installation steps change.

## Reporting bugs

Include the macOS version, hardware type, affected audio-device names, the selected policy, and reliable reproduction steps. Do not include private system logs without reviewing them first.
