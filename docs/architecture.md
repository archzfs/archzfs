# ArchZFS Architecture

This document describes the currently deployed ArchZFS system. Proposed release
channels and unfinished infrastructure are tracked in the
[project roadmap](roadmap.md), not in this current-state reference.

## Repository Responsibilities

`archzfs/archzfs` is the production control repository. It owns the package
templates, version and hash inputs, build orchestration, signing integration,
and GitHub Actions workflows that publish the Pacman repository.

The package repositories referenced in `.gitmodules` are generated outputs, not
independent sources of build policy. Stable package generation is driven by:

- `conf.sh`: OpenZFS versions, source hashes, and shared build settings.
- `src/kernels/*.sh`: Arch kernel package discovery and package metadata.
- `src/zfs/`, `src/zfs-dkms/`, and `src/zfs-utils/`: PKGBUILD and install-file
  templates, patches, hooks, and related package inputs.
- `build.sh` and `lib.sh`: package generation and clean-chroot orchestration.

`build.sh ... update` writes generated package files into submodule worktrees
under `packages/`. Stable GitHub-hosted package repositories cover utilities,
DKMS, and the standard, LTS, hardened, and zen Arch kernels. Git, RC, archiso,
and VFIO package paths remain in the source tree but are not part of the normal
production build.

## Production Build

`.github/workflows/release.yml` runs on relevant pushes to `master` and on a
daily schedule. It builds `build-container/`, mounts the checkout at `/src`,
and runs the container with `--privileged` so clean chroots can be used.

The container performs the following sequence:

1. Import the private release key when supplied and retrieve the public ArchZFS
   release key.
2. Download and verify the signed repository database from the mutable
   `failover` release.
3. Recreate the clean build chroot and generate stable PKGBUILDs.
4. Build `zfs-utils` and `zfs-dkms`; either failure aborts the release.
5. Build modules for LTS, standard, hardened, and zen kernels.
6. When an individual kernel build fails, reuse matching packages from
   `failover` only after verifying their detached signatures.
7. Collect packages into `repo/`, sign packages when a private key is present,
   and create the Pacman database with `repo-add`.

Kernel fallback is intentionally independent for each package family. The
expected case is that an Arch kernel advances beyond the compatibility range of
the current OpenZFS release while other kernels remain buildable. The failed
family then retains its previously signed package while compatible families can
advance. The implementation responds to build failure; it does not itself prove
that kernel incompatibility caused the failure. Utilities and DKMS are mandatory
builds and do not use this fallback.

The mounted checkout is recursively assigned to the container's `buildbot`
user. A local container run is therefore privileged and mutates both generated
files and checkout ownership; it is not a hermetic read-only test.

## Publication and Release Names

Production publication first uploads all assets to the temporary
`_experimental` release. After upload succeeds, the workflow removes the old
`experimental` release, renames the temporary release, force-moves the
`experimental` tag, and replaces assets in `failover`.

This create-then-promote process was introduced by
[PR #611](https://github.com/archzfs/archzfs/pull/611) for two related reasons.
It reduces the chance that a failed upload replaces the working repository, and
it resolves [issue #592](https://github.com/archzfs/archzfs/issues/592): GitHub
does not refresh the displayed release date when assets are updated in place.
Creating a new release before renaming it gives users a meaningful publication
date. Future fixed-name channels need to preserve both properties or replace
them deliberately; the current sequence reduces risk but is not fully atomic.

The fixed names are channels rather than immutable versions:

- `experimental`: current signed public Pacman repository.
- `failover`: signed prior/current package pool used to keep a repository
  publishable when an individual kernel-module build fails.
- `testing`: unsigned mutable output of the pull-request workflow.

Consumers must verify repository and package signatures rather than treating a
release tag's Git commit as permanent artifact identity.

## Related Repositories

### archzfs-testing

`archzfs/archzfs-testing` is a staging fork for release-infrastructure changes.
Its `master` branch is intended to start unrelated experiments at the same
source commit as production, then diverge only for the active test. Watcher,
selective-build, or update-automation work may run there before being proposed
for production.

Source synchronization does not copy repository settings, credentials,
environments, releases, tags, or workflow enabled state. Testing releases are
staging artifacts and are not interchangeable with signed releases from this
repository. The destructive synchronization and verification procedure is
documented in [staging.md](staging.md).

### archzfs-keyring

`archzfs/archzfs-keyring` contains the intended Pacman web-of-trust key material
for ArchZFS. Production currently signs with the release key represented there,
but an installable keyring package is not yet part of the production release.
User documentation must not imply that keyring-package deployment is complete.

### archzfs-mirror

`archzfs/archzfs-mirror` is intended to provide reusable tooling that
synchronizes GitHub Releases to mirrors. Its implementation is not part of this
repository's production publication path. The
[Computer-Assisted Research and Teaching Laboratory](https://cart.uni-plovdiv.net/)
at the [University of Plovdiv](https://uni-plovdiv.bg/) separately hosts a
[public mirror](https://mirrors.uni-plovdiv.net/archzfs/). The replacement
synchronization tooling is not deployed, so automatic freshness is not assured;
the endpoint's availability does not make unfinished reusable mirror tooling
production code.

### Generated package repositories

Repositories such as `zfs-utils`, `zfs-dkms`, `zfs-linux`, `zfs-linux-lts`,
`zfs-linux-hardened`, and `zfs-linux-zen` receive generated package source from
this repository. Changes to their generated files should originate in this
repository unless a task explicitly concerns submodule publication history.

### archzfs-ci and old deployment code

`archzfs/archzfs-ci` contains the former Buildbot deployment. Root scripts and
documentation in this repository also retain WebFaction, Jenkins, Packer/QEMU,
and custom archiso assumptions. These are historical references, not alternate
supported production pipelines.

The supported production surface includes the code reached transitively from
the GitHub workflow through `build-container/entrypoint.sh`, `build.sh`,
`lib.sh`, package templates, and kernel definitions. A file's age or legacy
comments do not prove that it is unused. Conversely, executable-looking code is
not a supported path merely because it remains in the repository.

## Validation Boundaries

The workflow named `Test` builds package artifacts in the same privileged
container and publishes a shared mutable prerelease. It verifies that package
generation and clean-chroot builds complete, subject to release-token
permissions. It does not run an automated OpenZFS filesystem, boot, upgrade, or
data-integrity test suite.

The older `testing/` harness requires root, KVM/QEMU, Packer, NFS, and hard-coded
host resources. Its guest setup is destructive and its acceptance checks are
unfinished. It must not be treated as a supported CI-equivalent command.

## Security Boundaries

Production signing material is supplied through the GitHub `Release`
environment. It must never be committed or exposed to shell tracing. The
builder deliberately imports it before enabling command tracing.

Failover reuse depends on both the signed repository database and detached
package signatures. Release changes must preserve those checks and the rule
that utilities and DKMS packages cannot silently fall back after failed builds.
