This is the current official repository of the ArchZFS project. It is built the same way and provides the same set of packages as the now stale `archzfs.com` repository. Except for the different PGP signing key, it can be used as a direct replacement for the old repo.

**Important:** While testing the repo is encouraged, we still advise you to be cautious and start with non-critical systems.

## Using the repository

### Without PGP verification

The repository and the packages in it are PGP signed, but the signing system is still being developed and may be subject to change. Until this is finalized, one way to use the repo is with signature validation turned off.

Add the following to `/etc/pacman.conf`:
```ini
[archzfs]
# TODO: Change this to `Required` once it's announced that the signing system is finalized.
SigLevel = Never
Server = https://github.com/archzfs/archzfs/releases/download/experimental
```

### With PGP verification

Add the following to `/etc/pacman.conf`:
```ini
[archzfs]
SigLevel = Required
Server = https://github.com/archzfs/archzfs/releases/download/experimental
```

Import the current ArchZFS signing key and sign it locally:
```
# pacman-key --init
# pacman-key --recv-keys 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9
# pacman-key --lsign-key 3A9917BF0DED5C13F69AC68FABEC0A1208037BE9
```
