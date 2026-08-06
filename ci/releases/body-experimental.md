This is the current official repository of the ArchZFS project. It is built the same way and provides the same set of packages as the now stale `archzfs.com` repository. Except for the different PGP signing key, it can be used as a direct replacement for the old repo.

**Important:** While testing the repo is encouraged, we still advise you to be cautious and start with non-critical systems.

## Using the repository

### With PGP verification (recommended)

The repository database and packages are PGP signed. An installable [`archzfs-keyring`](https://github.com/archzfs/archzfs-keyring) package is in development. For now, manually import and locally sign the current ArchZFS signing key as described below.

Review the full fingerprint before choosing to trust it, then initialize the Pacman keyring, retrieve the key, and sign it locally:
```
# pacman-key --init
# pacman-key --recv-keys 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9
# pacman-key --lsign-key 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9
```

Add the following to `/etc/pacman.conf`:
```ini
[archzfs]
SigLevel = Required
Server = https://github.com/archzfs/archzfs/releases/download/experimental
```

### Without PGP verification

You can use the repository without signature verification by configuring Pacman as shown below. This is not recommended: Pacman will not verify the authenticity of the repository database or packages.

Add the following to `/etc/pacman.conf` instead:
```ini
[archzfs]
SigLevel = Never
Server = https://github.com/archzfs/archzfs/releases/download/experimental
```
