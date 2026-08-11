This is the current official repository of the ArchZFS project. It is built the same way and provides the same set of packages as the now stale `archzfs.com` repository. Except for the different PGP signing key, it can be used as a direct replacement for the old repo.

**Important:** While testing the repo is encouraged, we still advise you to be cautious and start with non-critical systems.

## Using the repository

### Optional manual PGP verification

The repository database and packages are PGP signed. An installable
[`archzfs-keyring`](https://github.com/archzfs/archzfs-keyring) package is in
development and is intended to provide the normal supported trust setup once it
is ready. Until then, users who want signature verification and are comfortable
managing Pacman's trust database may use this transitional procedure.

Initialize the Pacman keyring if needed, retrieve the release key, display its
full fingerprint, and compare it with the
[`archzfs-keyring` release-key entry](https://github.com/archzfs/archzfs-keyring/tree/master/keyring/packager/archzfs/3A9917BF0DED5C13F69AC68FABEC0A1208037BE9)
before signing it locally:

```sh
# pacman-key --init
# pacman-key --recv-keys 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9
# pacman-key --finger 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9
# pacman-key --lsign-key 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9
```

Retrieving the key from a keyserver does not by itself establish its identity.
Locally signing it tells Pacman to trust that key.

Add the repository to `/etc/pacman.conf`:

```ini
[archzfs]
SigLevel = Required
Server = https://github.com/archzfs/archzfs/releases/download/experimental
```

Once a supported `archzfs-keyring` installation and update path is available,
follow those instructions instead of locally signing the release key.

### Temporary compatibility without PGP verification

If you do not use the transitional manual procedure, you can configure the
repository without signature verification:

```ini
[archzfs]
SigLevel = Never
Server = https://github.com/archzfs/archzfs/releases/download/experimental
```

This prevents Pacman from authenticating the repository database or packages.
It is a temporary compatibility option, not an equivalent trust configuration.
