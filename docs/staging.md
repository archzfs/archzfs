# Release Infrastructure Staging

This document defines how `archzfs-testing` is synchronized and used to validate
release-infrastructure changes before they are proposed for production. It does
not describe package maturity or an end-user testing repository.

## Model

`archzfs-testing/master` is a disposable, temporarily divergent copy of
`archzfs/master`, not an independently maintained source tree. At the start of
an unrelated experiment, its source should match production exactly. Divergence
should consist only of the active experiment and any clearly separated
testing-only adaptation needed to exercise it.

Canonical instructions and documentation live in `archzfs/archzfs` and are
copied into the fork. Do not add persistent testing-only `AGENTS.md`,
`CLAUDE.md`, README, or workflow documentation to testing `master`; forced
synchronization is intended to replace them.

The testing repository's GitHub description and settings provide its persistent
identity. Experiment branches preserve work that must survive a reset.

## Why a Separate Repository Exists

Pull-request workflows intentionally receive restricted credentials, especially
for contributions from forks. They can build packages but cannot safely prove
that code under review creates, replaces, renames, or deletes releases and tags
correctly.

Running the candidate workflow in `archzfs-testing` confines its
repository-scoped write access to staging resources instead of production. The
token may still mutate releases, tags, branches, and other testing-repository
state allowed by the workflow permissions. A successful staging run supplements
the production PR checks; it does not replace review or prove that every
production setting is equivalent.

## Safety Invariants

- Treat every force-sync, workflow enablement, release mutation, tag update, and
  branch deletion as an explicitly authorized operation.
- Confirm the destination is `archzfs/archzfs-testing` immediately before every
  destructive or publishing command. Never substitute `archzfs/archzfs` in a
  staging command.
- Preserve active experiment commits on a named remote branch before resetting
  testing `master`.
- Disable mutating and scheduled workflows, then disable repository-level
  Actions before synchronization. Keep Actions disabled until workflows
  introduced by the synchronized tree have been inventoried and any mutating or
  scheduled workflows have been disabled.
- Never copy the production private signing key into the staging repository.
  Unsigned staging assets are expected unless a distinct non-production trust
  design is introduced and documented.
- Do not treat mutable staging tags or releases as immutable provenance. Record
  the tested commit SHA and workflow-run URLs.

## Synchronization Procedure

### 1. Inventory and Preserve State

Check the repository identity, active workflows, current runs, branches, and the
commits that differ from production. Determine whether any open production PR
or unresolved experiment still depends on testing `master`.

Useful read-only commands include:

```sh
gh api repos/archzfs/archzfs-testing \
  --jq '{full_name, fork, parent: .parent.full_name, default_branch, permissions}'
gh auth status
gh workflow list --all --repo archzfs/archzfs-testing
gh run list --repo archzfs/archzfs-testing
git remote -v
git fetch --all --prune
git log --oneline --left-right origin/master...archzfs/master
```

The final command assumes the production repository is configured locally as
the `archzfs` remote. Inspect remote URLs rather than assuming remote names.

Abort unless the destination is exactly `archzfs/archzfs-testing`, reports
`fork: true`, has `archzfs/archzfs` as its parent, and uses `master` as its
default branch. The authenticated identity must have repository administration
and contents-write access for the complete procedure.

A GitHub CLI OAuth token or classic personal access token that adds or updates
files under `.github/workflows/` requires the `workflow` scope in addition to
repository write access. Repository administration does not substitute for that
token scope. If `gh auth status` does not report it, stop and obtain explicit
authorization before changing authentication.

Before a reset, preserve relevant testing `master` history on a descriptive
branch such as `experiment/kernel-watcher` or
`archive/kernel-watcher-2026-07-11`. Push and verify that branch before
continuing. Keep it until the corresponding production work is merged or
abandoned explicitly.

### 2. Record Settings and Disable Actions

Record the current repository Actions policy, default workflow-token
permissions, active runs, and per-workflow enabled states. Inspect `master`
branch protection and repository rulesets; do not attempt the force-sync unless
the reset is permitted or an explicitly authorized bypass is available.

```sh
gh api repos/archzfs/archzfs-testing/branches/master
gh api repos/archzfs/archzfs-testing/rulesets
gh api repos/archzfs/archzfs-testing/actions/permissions
gh api repos/archzfs/archzfs-testing/actions/permissions/workflow
gh workflow list --all --repo archzfs/archzfs-testing
gh run list --repo archzfs/archzfs-testing
```

Let mutating runs finish before proceeding. Canceling a run is itself a
state-changing operation and requires explicit authorization.

Disable release, watcher, update, or other currently present workflows that
publish, delete, dispatch privileged work, or run on a schedule. For example,
when those files exist:

```sh
gh workflow disable release.yml --repo archzfs/archzfs-testing
gh workflow disable watcher.yml --repo archzfs/archzfs-testing
gh workflow disable update-zfs.yml --repo archzfs/archzfs-testing
```

Then disable Actions for the entire repository so workflows introduced by the
synchronized production tree cannot start before they are reviewed:

```sh
gh api --method PUT \
  repos/archzfs/archzfs-testing/actions/permissions \
  -F enabled=false
```

Keep the recorded settings available for the restore step. Do not assume the
current values or hard-code a permissive replacement policy.

### 3. Force-Sync the Default Branch

The normal fork-sync operation only fast-forwards when possible. Testing
`master` normally has unique experiment commits, so exact parity requires the
explicitly destructive form:

```sh
gh repo sync archzfs/archzfs-testing \
  --source archzfs/archzfs \
  --branch master \
  --force
```

The command first uses GitHub's fork-only upstream-merge operation and may fall
back to moving the destination ref directly. That fallback cannot transfer
missing Git objects; it can only reference commits already in the destination's
object network. Continuous synchronization of new production commits therefore
requires preserving `archzfs-testing` as a GitHub fork of `archzfs`. If the
testing repository is recreated, recreate it as a fork.

`--force` hard-resets the destination branch to the source branch. It does not
synchronize or clean releases, tags, Actions variables, secrets, environments,
permissions, workflow enabled state, caches, branch protection, or repository
metadata.

After synchronization, compare the remote commit SHAs rather than relying on a
successful command alone:

```sh
gh api repos/archzfs/archzfs/commits/master --jq .sha
gh api repos/archzfs/archzfs-testing/commits/master --jq .sha
gh workflow list --all --repo archzfs/archzfs-testing
```

While repository Actions remain disabled, inventory every workflow introduced
by the synchronized tree and disable each mutating or scheduled workflow. After
the commit SHAs and workflow states are verified, restore the exact recorded
repository Actions policy and default workflow-token permissions. Explicitly
enable only the workflow needed for the authorized experiment; do not broadly
enable all synchronized workflows.

Prefer a fresh clone or worktree for the synchronized source. Do not hard-reset
an existing local checkout until its uncommitted work and local-only commits
have been reviewed and preserved.

## Experiment Structure

Create a named candidate branch from the synchronized production commit. Keep
commits intended for production free of testing-only release names, credentials,
or documentation.

If repository settings cannot express a required staging difference, create a
separate testing-only commit on top of the production candidate. Record that
difference in the eventual PR and do not transfer the adaptation commit to
production. A test with such an overlay is evidence for the shared code below
it, not proof that the production workflow was tested byte-for-byte.

Testing workflows currently depend on `master` push, schedule, or dispatch
behavior. Advance testing `master` to the experiment only after the destination
has been rechecked, the repository Actions policy has been restored, and the
single required workflow has been explicitly enabled. Enabling a synced
production workflow may also restore its schedule, so disable it again when the
experiment is complete.

Repository context should provide most isolation automatically: release actions
using `github.repository` mutate the testing repository. Review hard-coded URLs
separately. The builder currently reads signed failover assets from the
production `archzfs/archzfs` release; that is a read-only dependency, not a
license to mutate production releases.

## Environment Parity

Before interpreting a staging result, compare every setting used by the changed
workflow. Source synchronization does not copy:

- Actions variables, secrets, and environments.
- Environment protection and branch policies.
- Default workflow-token permissions and allowed Actions policy.
- Workflow enabled state, schedules already queued, caches, or artifacts.
- Releases, assets, tags, branch protection, or repository metadata.

Record relevant non-secret values and the names, but never the values, of
required secrets. The production `Release` environment supplies signing
material; staging must not contain that production private key. An unsigned
staging build therefore does not validate production private-key import or
signing unless a separate safe mechanism is deliberately provided.

## Verification

A green workflow conclusion is only the start of release verification. Check
the behavior relevant to the change, including:

- The checked-out commit SHA and workflow inputs.
- The package families built, skipped, or reused from failover.
- Expected package and repository signature behavior.
- Temporary release creation and cleanup.
- Final release asset completeness and repository database contents.
- Tag targets and release dates after create-then-promote publication.
- Per-kernel failover behavior when only one build fails.
- Preservation of the previous usable release when failure occurs before
  promotion.
- Safe repeated execution where idempotence is expected.
- Absence of writes to production repositories, releases, tags, or branches.

Keep links to the workflow runs and releases in the production PR description.
If failure-path testing would require deliberately breaking or deleting shared
staging resources, describe and authorize that test separately.

## Production Pull Request

Preserve the exact production-intended candidate commits after staging. Push
those commits, without any testing-only overlay, to a named branch used for the
PR against `archzfs/master`. Avoid manually recreating an already tested diff;
retaining the commit object or applying the exact patch makes provenance easier
to review.

The production PR should state:

- The production commit or patch tested and any staging-only differences.
- Relevant testing workflow runs and release results.
- Environment differences that staging did not cover, especially signing.
- Failure paths, retries, or destructive cases that were not exercised.
- Expected release, tag, failover, and generated-artifact impact.

Normal production PR checks still apply. Their inability to mutate a shared
release from fork-originated code is a known boundary, not a reason to grant
untrusted code broader credentials.

## Cleanup

After verification, disable mutating staging workflows and ensure no unexpected
scheduled run remains active. Retain the experiment branch and evidence until
the production PR is resolved. Before unrelated work begins, repeat the
inventory and force-sync procedure rather than accumulating experiments on
testing `master`.

Releases and tags may be cleaned when a test requires it, but they are shared
staging state and need explicit authorization. Branch synchronization alone does
not remove them.
