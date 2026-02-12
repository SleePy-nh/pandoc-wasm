# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.2] - 2026-02-12

### Fixed

- Fix redirect handling in downloader that prevented asset downloads from GitHub Releases (HTTP 302 not followed).

## [1.0.1] - 2026-02-10

### Fixed

- Downloader now explicitly returns `true` on success.
- README: fixed clone URL (NathanHimpens instead of SleePy-nh).
- README: updated project structure to include Ruby gem files.
- Added missing `LICENSE.txt` at project root.
- Added `rake` and `minitest` to Gemfile for development.

## [1.0.0] - 2025-01-01

### Added

- Initial release.
- `PandocWasm.run` -- execute pandoc via a WASI runtime.
- `PandocWasm.download_to_binary_path!` -- download the `.wasm` binary from GitHub Releases.
- `PandocWasm.available?` -- check if the binary exists.
- Configurable `binary_path` and `runtime`.
- Downloader with redirect handling and partial-file cleanup.
- Full test suite (Minitest).
