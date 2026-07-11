# ArchZFS Agent Instructions

## Repository Role

- This is the production control repository for ArchZFS package generation,
  builds, signing, and GitHub Releases publication.
- Treat current workflows and scripts as authoritative over the old wiki,
  `TODO.rst`, and legacy deployment comments.
- `archzfs-testing` is the staging fork for release-infrastructure changes.
  Check whether work there has reached this repository before describing it as
  production behavior.

## Source and Generated Files

- Run repository scripts from the repository root. Some paths are resolved
  relative to the working directory rather than the script location.
- Edit `conf.sh`, `src/kernels/*.sh`, and templates under `src/zfs*` to change
  generated packages. Do not hand-edit `packages/*/*` as the source of truth.
- `packages/*/*` are Git submodules populated by `build.sh ... update`. Most
  point to generated repositories in the ArchZFS organization; VFIO submodules
  point to the AUR.
- Initialize submodules before inspecting generated package repositories or
  preparing submodule updates. Most remotes require GitHub SSH access.
- Treat `repo/`, `repo-tmp/`, package archives, `.SRCINFO`, build logs,
  `archiso/{work,out}/`, and `testing/files/packer_work/` as generated output.
- `build.sh -U` rewrites initcpio hashes in `conf.sh`; review those changes as
  release inputs rather than incidental formatting.

## Builds and Checks

- The closest local equivalent to CI is:

  ```sh
  docker build -t archzfs-builder build-container
  docker run -e FAILOVER_RELEASE_NAME --privileged --rm \
    -v "$(pwd):/src" archzfs-builder
  ```

- The container is privileged, uses nested clean chroots, recursively changes
  ownership in the mounted checkout, and requires network access. Do not run it
  as a lightweight or side-effect-free check.
- Production adds `GPG_KEY_DATA` and `GPG_KEY_ID`; never expose signing material
  in commands, logs, fixtures, or commits.
- CI generates stable recipes with `sudo bash build.sh -s -d -u all update`,
  then builds `utils`, `dkms`, `lts`, `std`, `hardened`, and `zen` in that order.
  `utils` and `dkms` must succeed; kernel packages may come from signed
  `failover` assets when their builds fail.
- `all` excludes `iso` and `vfio`. `-s` excludes Git and RC package variants.
- Direct `build.sh` use requires root, Arch package tooling,
  `clean-chroot-manager`, network access, and the configured non-root
  `buildbot` account.
- Although listed in `build.sh --help`, `test` and `update-test` are parsed but
  have no execution path. Do not report them as validation.
- The Actions workflow named `Test` performs an unsigned package build and
  updates the shared mutable `testing` release. It does not run the legacy
  QEMU tests or an OpenZFS runtime/data-integrity suite.
- For shell-only changes, at minimum run `bash -n` on each changed Bash script
  and `git diff --check`. The initcpio hook declares ash/dash compatibility, so
  Bash syntax alone is insufficient for changes to that file.

## Operational Safety

- Do not run `build.sh -R`: it executes `git reset --hard` inside selected
  package submodules.
- Do not run `repo.sh`, `push.sh`, `mirror.sh`, signing commands, remote rsync,
  or release workflows without explicit authorization and environment review.
  These paths can move, delete, sign, commit, push, or publish artifacts.
- Do not run `testing/test.sh` on an unreviewed environment. Its VM setup erases
  `/dev/vda`, depends on hard-coded NFS resources, and has unfinished acceptance
  checks.
- Releases and tags named `testing`, `experimental`, and `failover` are mutable
  and may be force-moved. Do not use their tag commits as immutable provenance.
- Preserve create-then-promote publication for fixed-name release channels. In
  addition to reducing exposure to incomplete uploads, creating a fresh release
  updates the date shown by GitHub; updating assets in place does not.
- Preserve failover database/package signature verification when changing the
  builder. A downloaded package is not eligible for reuse merely because its
  filename matches.

## Commits and Pull Requests

- Only commit, push, or open pull requests when explicitly requested.
- When asked to do so, write concise, review-oriented commit messages, pull
  request descriptions, and substantive review comments. Explain the motivation,
  operational impact, validation, risks, and non-obvious tradeoffs or rejected
  alternatives when relevant.
- Keep descriptions proportional to the change. Do not restate the diff,
  document details already clear from the code, or overwhelm reviewers with
  exploratory narration.
- Call out generated files, release behavior, signing implications, destructive
  operations, and validation that could not be performed.

## Historical Boundaries

- GitHub Actions and GitHub Releases are the supported production path.
  Buildbot, WebFaction, Jenkins, old `archzfs.com` deployment, Packer/QEMU, and
  custom archiso material remain for historical context unless a task
  explicitly targets them.
- Before changing or removing legacy-looking code, trace whether the current
  workflow reaches it through `build-container/entrypoint.sh`, `build.sh`,
  `lib.sh`, package templates, or kernel definitions. Old comments do not prove
  that code is unused, and presence in the tree does not make a path supported.
- Do not revive settings such as `webfaction`, `/home/jalvarez`, or the short
  key ID in `conf.sh` for current release work. Current production signing uses
  the GitHub `Release` environment and the full ArchZFS release-key fingerprint
  referenced by `build-container/entrypoint.sh`.
- Read `docs/architecture.md` before changing package ownership, release
  publication, signing, failover, or cross-repository behavior.
