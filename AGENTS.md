# ArchZFS Agent Instructions

## Repository Identity

- These instructions are canonical in `archzfs/archzfs` and may be copied
  unchanged into the disposable `archzfs-testing` fork. Identify the current
  GitHub repository before release or synchronization work.
- In `archzfs/archzfs`, this tree is the production control repository for
  package generation, builds, signing, and GitHub Releases publication.
- In `archzfs/archzfs-testing`, `master`, experiment branches, tags, and releases
  are staging resources. They remain mutating shared infrastructure and still
  require explicit authorization before reset, publication, or deletion.
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

## Local and External Package Evidence

- Treat locally installed packages, files, caches, and Pacman databases as
  presumptively untrusted, mutable observations for discovery or corroboration,
  not authoritative package evidence.
- Before relying on local content, record the package name,
  epoch/version/release, architecture, any reported or claimed origin, and
  whether that exact generation is under investigation. A version or source
  mismatch normally ends that local file's relevance to exact-content claims
  about the generation; matching versions alone do not establish identical
  files.
- `pacman -Qo` reports ownership recorded by the local package database, and
  `pacman -Qkk` is only a preliminary comparison against local package metadata.
  Neither independently proves provenance or pristine contents. Presume files
  under `/etc`, Pacman backup files, hooks, and other configuration surfaces may
  have been modified locally until shown otherwise.
- Do not infer current official Arch package availability, ownership, or
  repository membership only from configured local mirrors or Pacman databases;
  they may be stale or include third-party repositories. Use current
  `archlinux.org` package metadata, official repository databases, official file
  lists, or another current source with comparable official provenance that is
  identified in the evidence record.
- Match evidence to the claim. Intended ArchZFS policy comes from source files
  such as `conf.sh`, `src/kernels/*.sh`, and templates under `src/zfs*`;
  generated recipes come from output regenerated from a recorded
  control-repository commit; published contents come from exact package
  archives, repository databases, and detached signatures; upstream behavior
  comes from source pinned to the generation under review, such as an archive
  matching the hash recorded in `conf.sh` or a release tag or commit whose
  upstream provenance has been verified and recorded. Account for downstream
  patches and configure options. Upstream source does not prove what a
  downstream package shipped, and a package archive does not prove current
  source policy.
- Establish artifact identity and authenticity independently of the installed
  file before relying on its contents. For published production ArchZFS
  artifacts, verify repository database and package signatures against the full
  release-key fingerprint referenced by `build-container/entrypoint.sh`. For
  official Arch packages, use current official Arch keyring and trust metadata
  obtained through an authoritative path. A digest identifies exact bytes for
  comparison; it does not authenticate their source. A cached archive remains
  eligible evidence when these checks succeed and its identity matches the
  generation under review.
- For mutable fixed-name releases, do not treat the release tag commit as
  immutable provenance; see **Operational Safety**. Identify signed assets by
  filename, package version, digest, and verified signature. Tie unsigned
  `testing` assets to their source commit and workflow run as well as their
  filename, version, and digest. Record whether each was built by that run or
  reused from signed `failover`. For reused assets, record the verified failover
  identity; they do not validate candidate package contents. Unsigned assets do
  not validate production signing or published production contents.
- Record package identities and versions, artifact names and URLs, signature
  verification, digests, commits or tags, and discrepancies in durable task
  evidence and in any applicable pull request or review. Preserve conflicting
  evidence rather than hiding or silently reconciling it.
- For exact package-content claims, including package boundaries, dependencies,
  and initramfs inputs, inspect the verified archive's `.PKGINFO`, `.BUILDINFO`,
  `.MTREE`, file boundaries, scripts, and ELF objects as applicable. Compare
  local files against that archive or pinned source rather than extrapolating
  from the host. Treat existing `packages/*/*` worktrees and `repo/` output as
  mutable local generation results until they are regenerated or otherwise tied
  to the recorded commit.
- Validate proposed package contents by regenerating the intended recipe,
  obtaining a clean-chroot build artifact, and inspecting that archive. Review
  **Builds and Checks** before running a local build; its privileged container,
  network access, and checkout-ownership changes are not lightweight side
  effects.
- For boot, initramfs, kernel-module, pool-availability, and data-integrity
  decisions, require verified artifacts and safe tests in a clean or disposable
  environment. No supported runtime or data-integrity harness currently exists
  in this repository, and `testing/test.sh` is not one; see **Operational
  Safety**. Build success and local-only evidence are insufficient. If safe
  runtime evidence cannot be obtained, report the gap and do not close the
  safety gate.
- If authoritative evidence is unavailable, label the result as a local
  observation, retain the uncertainty, and do not use it alone to close a
  correctness or safety gate.

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
- Long package-build checks may run automatically for changes that cannot affect
  their workflow, inputs, or outputs. After inspecting the changed paths and
  relevant workflow dependencies, do not wait synchronously merely for such a
  check to complete. Confirm that the run reached its expected long-running
  step, report its pending status and URL, and do not claim that it passed or
  cancel it.
- Wait for or investigate a check when the change can affect it, when it fails
  unexpectedly, or when its result is required for a requested merge, release,
  or readiness decision. Documentation-only changes commonly qualify for
  non-blocking treatment, but file type alone is not sufficient; verify the
  dependency boundary first.
- For shell-only changes, at minimum run `bash -n` on each changed Bash script
  and `git diff --check`. The initcpio hook declares ash/dash compatibility, so
  Bash syntax alone is insufficient for changes to that file.

## Operational Safety

- Do not run `build.sh -R`: it executes `git reset --hard` inside selected
  package submodules.
- Do not run `repo.sh`, `push.sh`, `mirror.sh`, signing commands, remote rsync,
  or release workflows without explicit authorization and environment review.
  These paths can move, delete, sign, commit, push, or publish artifacts.
- Do not run `testing/test.sh` on an unreviewed environment. Guest setup wipes
  the test VM's `/dev/vda`, depends on hard-coded NFS resources, and has
  unfinished acceptance checks.
- Do not force-sync `archzfs-testing` until active work is preserved and
  mutating workflows are disabled. `gh repo sync --force` hard-resets its target
  branch; follow `docs/staging.md` and verify the destination repository.
- Releases and tags named `testing`, `experimental`, and `failover` are mutable
  and may be force-moved. Do not use their tag commits as immutable provenance.
- Preserve create-then-promote publication for fixed-name release channels. In
  addition to reducing exposure to incomplete uploads, creating a fresh release
  updates the date shown by GitHub; updating assets in place does not.
- While fixed-name package publication uses delete-then-rename promotion, its
  release-mutating critical section must not be canceled. The current workflow
  protects the whole run as a containment measure; make build work cancellable
  only after separating it from publication and pinning failover inputs to a
  complete generation.
- Keep release-body publication metadata-only. It must read the body from the
  current trusted default branch and must not replace assets, move tags, enter
  the signing environment, use signing material, or share package-release
  concurrency.
- Preserve release-body reconciliation after package-release completion. An
  older package-workflow checkout must not permanently restore stale notes.
- `_experimental` is mutable temporary publication state. An interrupted run
  may leave a temporary release or tag; inspect it and clean it up safely before
  reuse.
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

## Documentation Coordination

- When package, release, signing, mirror, repository-role, or user-facing
  behavior changes, review this repository's README, `docs/`, and applicable
  `ci/releases/body-*.md` files, the public [ArchZFS organization `.github`
  repository](https://github.com/archzfs/.github), and the ArchZFS Wiki for
  affected claims.
- The organization `.github` repository is a separate Git repository, not the
  `.github/` directory in this checkout. GitHub does not copy its profile or
  default community files into repository clones. Inspect it through GitHub or
  a separately cloned checkout, and verify that checkout's remote before use.
- Do not place repository-critical operational instructions only in the
  organization `.github` repository.
- Update source-controlled documentation in the same change when practical.
  Cross-repository documentation requires separate linked PRs; state
  dependencies and merge order explicitly.
- GitHub Wiki changes have no normal pull-request path. Prepare them in a local
  Wiki clone on a named branch, commit the proposed pages, and provide the diff
  and summary for review. Verify new or changed link targets before publication
  and check rendered links afterward. If a target intentionally depends on
  unmerged work, add an explicit dependency notice and tracked cleanup. Push
  Wiki `master` only with explicit authorization.
- PRs affecting public behavior should state which documentation surfaces were
  reviewed, which were updated, and any coordinated follow-up still required.

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
- Read `docs/staging.md` before synchronizing `archzfs-testing` or using it to
  validate release-infrastructure changes.
