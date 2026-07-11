# Maintenance Policy

This repository is the public MBSifu-maintained fork of
[B3none/cs2-retakes](https://github.com/B3none/cs2-retakes).

## Branches and upstream changes

- The default branch contains reviewed MBSifu maintenance patches.
- The `upstream` source is `B3none/cs2-retakes:master`.
- The weekly `upstream-sync.yml` workflow may create a pull request, but it
  never merges or publishes upstream changes automatically.
- Keep upstream namespaces, assemblies, commands, and configuration paths stable
  unless a reviewed migration is required.

## Verification

Pull requests must pass:

1. The repository's .NET build and focused tests.
2. `scripts/package-release.sh <tag>`.
3. SHA-256, manifest, required-path, archive-root, and bundled-assembly checks in
   `scripts/validate-release.sh`.

## Releases

Reviewed tags use `v<project-version>-mbsifu.<revision>`. The Release workflow
builds from the tag, creates one Linux x86_64 archive rooted at `addons/`, and
publishes the archive, its SHA-256 file, and `plugin-manifest.json`.

A successful CI build is not production approval. MBSifu separately validates
the manifest and archive, builds a test image, and runs a server smoke test
before promotion.

