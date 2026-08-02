# claude-code (RPM / container packaging)

This repo packages Anthropic's official [Claude Code](https://code.claude.com) CLI as:

- a Fedora **RPM** (`claude-code.spec`), and
- a **container image** built from that RPM (`Containerfile`), published to
  `ghcr.io/akdev1l/claude-code`.

It does not contain Claude Code's source — it downloads the official
pre-built `claude` binary for the target architecture and wraps it in
standard Fedora packaging.

## Layout

- `claude-code.spec` — RPM spec. Declares the current version and pulls the
  matching pre-built binary from `downloads.claude.ai` for `x86_64` or
  `aarch64`, then installs it to `/usr/bin/claude`. No compilation happens;
  the binary is installed as-is (debug package / stripping disabled).
- `Containerfile` — multi-stage build: stage one uses `fedpkg` to build the
  RPM from the spec inside `fedora-minimal`, stage two installs that RPM
  into a fresh `fedora-minimal` image. `ENTRYPOINT` runs `/usr/bin/claude`.
- `build.sh` — builds the container image locally with `podman build`,
  tagging it `claude-code:latest` and `claude-code:<version>` (version read
  from the spec file). Respects `FEDORA_RELEASE` (default `44`).
- `claude` — wrapper shell script to `podman run` the built image, mounting
  `~/.config/claude` (as `/root/.claude` and `/root/.claude.json`) and the
  current directory (as `/project`) into the container, so Claude Code's
  config/auth persists across runs and operates on the local project.
- `ci/claude.metadata.sh` — standalone helper (not used by the RPM/container
  build) that queries `downloads.claude.ai` for the latest Claude Code
  version, manifest, and per-architecture checksums, and prints them as
  JSON.
- `ci/claude.versionbump.sh` — runs `claude.metadata.sh` and, if a newer
  version is available, updates `Version:` in `claude-code.spec`, the
  checksums in `SOURCES`, and adds a `%changelog` entry (using the spec's
  existing `Release` number — bumping `Release` itself is a manual,
  spec-revision-only step).
- `SOURCES` — recorded SHA256 checksums of the downloaded per-arch binaries.
- `.github/workflows/build.yml` — CI: on push to `f44` or `rawhide`, builds
  the image via `build.sh` and pushes `latest`, `<version>`, and a date tag
  to GHCR.

## Usage

Build the image:

```sh
./build.sh
```

Run Claude Code from the built image against the current directory:

```sh
./claude
```

## Updating the packaged version

```sh
./ci/claude.versionbump.sh
```

This fetches the latest metadata, and — if it's newer than the version
currently in `claude-code.spec` — updates `Version:`, `SOURCES`, and the
`%changelog`. Then rebuild with `./build.sh`.
