# ArchZFS Roadmap

Last reviewed: 2026-07-12

This document records the current maintainer's working direction and open design
work. It is not a release schedule, and nothing described as staging, proposed,
or requiring design is deployed production behavior. See
[architecture.md](architecture.md) for the current system.

Status terms used below:

- **Deployed**: available through the production ArchZFS system.
- **Staging**: implemented or exercised outside production, primarily in
  `archzfs-testing`.
- **Priority**: identified by the current maintainer as important current work,
  but not necessarily agreed project-wide, designed, or implemented completely.
- **Design needed**: desired outcome with unresolved policy or implementation.
- **Historical**: retained context, not a supported direction.

## Principles

- Keep production build and publication infrastructure reproducible through
  GitHub rather than dependent on one maintainer's host or private services.
- Test every package set before it reaches an end-user channel. Prefer ephemeral
  artifacts that are never published when validation fails.
- Classify an end-user channel by upstream release status, kernel support, patch
  provenance, and intended audience. Passing tests is necessary but does not by
  itself make unreleased upstream code stable.
- Preserve signed, create-then-promote publication for fixed-name channels so a
  failed upload does not immediately replace the working repository and GitHub
  displays a meaningful publication date.
- Keep channel names provisional until their contents, audience, migration, and
  support expectations are agreed and documented.

## Release Roles

These roles describe policy. Except where noted, their final GitHub release and
Pacman repository names remain design decisions.

### Stable

**Status: Design needed**

The stable end-user repository should provide:

- The latest suitable released OpenZFS version, without unreleased feature or
  kernel-compatibility patches.
- Only kernel combinations inside that OpenZFS release's declared support
  range. A successful build against a newer kernel is not sufficient.
- Matching, unmodified official Arch Linux kernel and header packages so the
  repository remains usable after official Arch repositories advance.
- Verification and redistribution of the original Arch package signatures,
  alongside normal ArchZFS signing for ArchZFS-built packages and repository
  metadata.
- A retention policy that keeps a complete compatible package set available
  long enough for upgrades and fresh installations.

This definition combines compatibility policy with operational maturity. The
current public `experimental` release uses proven infrastructure but does not
enforce these compatibility and self-containment requirements; it therefore
cannot become stable through a name change alone.

### Compatibility Edge

**Status: Design needed; the current `experimental` name may be reused or
replaced**

This end-user repository would follow current Arch kernels before a compatible
OpenZFS release is available. It may use narrowly selected compatibility work
from OpenZFS `master` or upstream pull requests. Its packages must pass the same
automated validation required for other public channels, but remain higher-risk
because tests cannot establish the maturity of unreleased upstream changes or
find every bug exposed by real workloads.

This role is comparable to an upstream testing repository, not to a staging
area for ArchZFS CI implementation changes.

### Feature Preview

**Status: Design needed; optional**

Substantial unreleased OpenZFS features or broader patch sets may warrant a
separate, more explicitly experimental end-user channel. Before creating one,
decide whether there is a real audience, how it differs from compatibility
edge, and what support and retention users can expect.

### CI Validation

**Status: Partially deployed**

Package candidates should normally exist only as ephemeral workflow artifacts
until validation succeeds. A mutable release such as `testing` may be used when
persistent assets are technically necessary, but it is not an end-user channel
and developers should rarely need to install from it. The current shared release
also cannot be updated reliably by fork-originated pull requests because of
GitHub token permissions tracked in
[issue #586](https://github.com/archzfs/archzfs/issues/586).

`archzfs-testing` has a separate purpose: it is the disposable staging fork for
release-infrastructure changes. Watchers, publication changes, and other CI work
should be demonstrated there before entering this production repository.

## Immediate Priorities

### Mirror Automation

**Status: Priority; implementation proposed in
[archzfs-mirror PR #1](https://github.com/archzfs/archzfs-mirror/pull/1)**

The public mirror hosted by the
[Computer-Assisted Research and Teaching Laboratory](https://cart.uni-plovdiv.net/)
at the [University of Plovdiv](https://uni-plovdiv.bg/) is online, but the
proposed synchronization tooling is unfinished and not deployed, so it is not
currently refreshed from production releases automatically. Refine the Tier 1
and Tier 2 implementation, preserve its staging, locking, managed-deletion,
API-limit, and archive safety properties, and verify release and package
signatures before downloaded assets become visible. Add deployment, recovery,
monitoring, and retention documentation, then deploy and observe it on the
University-hosted mirror.

This work is a high priority because it improves an existing service without
first changing production package-selection or release-trigger behavior.

### Kernel Watcher Foundation

**Status: Priority and staging in `archzfs-testing`; proposed in
[PR #627](https://github.com/archzfs/archzfs/pull/627)**

Review and refine the watcher, then merge it as the foundation for later release
automation. It should continue to track all supported Arch kernel families and
use the same configurable mirror for detection and builds. Keep version
detection separate from channel policy: a new kernel may trigger a normal
stable rebuild, require compatibility-edge patches, or require stable to retain
an older official kernel.

### Selective Package Updates

**Status: Staging; dependent proposal in
[PR #632](https://github.com/archzfs/archzfs/pull/632)**

After the watcher foundation, rebuild only affected kernel families and retain
unchanged signed assets. Use this work to stop unnecessary replacement of
identically versioned package files described in
[issue #613](https://github.com/archzfs/archzfs/issues/613). Define explicit
criteria for rebuilding utilities and DKMS, and automate dependency-only
`pkgrel` bumps and new-release resets tracked in
[issue #623](https://github.com/archzfs/archzfs/issues/623).

### OpenZFS Update Proposals

**Status: Staging; dependent proposal in
[PR #633](https://github.com/archzfs/archzfs/pull/633)**

Use the watcher to open a reviewed `conf.sh` update pull request when OpenZFS
publishes a release. Retain a human merge gate for source version and hash
changes. This depends on PRs #627 and #632 and on explicitly configured GitHub
permission for Actions to create pull requests.

### Channel Implementation

**Status: Design needed**

Turn the release roles above into concrete names, URLs, package-selection rules,
retention policies, and user migration instructions. Do not repurpose or rename
the current public channel until users can transition without losing a working
repository. Channel routing must preserve independently usable package sets and
the create-then-promote publication invariant.

## Test Infrastructure

**Status: Priority; feasibility investigation needed**

Build a modern GitHub-based suite around the available upstream OpenZFS test
infrastructure, running against a current Arch Linux environment. Starting from
the latest ArchISO is a candidate way to maximize compatibility with current
installation media and packages, not yet a fixed implementation choice.

The investigation should establish:

- Which upstream OpenZFS tests can run reliably in an isolated ephemeral Arch
  environment and what additional ArchZFS package, repository, boot, module,
  and upgrade checks are needed.
- Whether standard GitHub-hosted runners provide sufficient privilege, storage,
  kernel features, KVM access, and execution time.
- How to ensure failed package candidates remain ephemeral and never reach an
  end-user release.
- How to keep the suite reproducible and maintainable by multiple people.

Prefer GitHub-hosted or otherwise shared reproducible infrastructure. Consider
self-hosted runners only as a last resort and only with an explicit plan for
redundancy and maintenance; testing must not recreate the former single-host,
single-maintainer dependency.

Passing this suite is a publication gate for every public channel. It does not
promote packages from compatibility edge to stable or make unreleased upstream
code satisfy stable policy.

## Keyring and Trust

**Status: Priority; packaging proposed in
[archzfs-keyring PR #1](https://github.com/archzfs/archzfs-keyring/pull/1)**

Complete the ArchZFS keyring package, its review and release procedure, and its
integration into the production repository. The intended trust model should use
maintainer keys to certify the release key rather than asking each user to make
that release key locally trusted. Preserve the current release-key verification
path until the package and migration instructions are deployed.

## Distribution and Retention

**Status: Design needed**

Define authoritative sources, signature checks, and retention for official Arch
kernel packages included in stable. Treat `kernels.archzfs.com` only as a
historical lead: its HTTPS endpoint is currently unusable because its certificate
does not match the hostname, and its maintenance and retention status must be
established before it can be considered in distribution planning. A
self-contained stable repository must not depend on it.

Resolve the remaining `archzfs.com` domain, redirect, user-migration, and archive
questions tracked in [issue #599](https://github.com/archzfs/archzfs/issues/599).

## Maintainability Investigation

**Status: Design needed**

The repository predates the current GitHub release architecture and contains
substantial complexity from older operating models. Before proposing a broad
refactor, inventory the requirements and exact call graph of the supported
production path, identify complexity that no longer serves current needs, and
evaluate smaller and more direct implementations, including closer use of Arch
`devtools` where appropriate.

Any redesign needs its own proposal, migration plan, and validation strategy.
This roadmap does not assume that `clean-chroot-manager` should be removed, that
a particular replacement is sufficient, or that old-looking code is unused.

## Open Policy Questions

- What final names best distinguish stable, compatibility-edge, feature-preview,
  and CI-only artifacts?
- Which official Arch kernel families does stable promise to carry?
- From which authoritative archives are matching kernels and headers obtained,
  and for how long are superseded compatible sets retained?
- What user migration avoids disruption when the current `experimental` URL and
  repository role change?
- Is a separate feature-preview channel justified, or should such packages stay
  unpublished outside targeted development tests?
- What minimum hosted-runner test coverage is required before any public
  package set is published?
