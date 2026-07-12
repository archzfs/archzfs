This is the current official repository of the ArchZFS project. It is built the same way and provides the same set of packages as the now stale `archzfs.com` repository. Except for the different PGP signing key, it can be used as a direct replacement for the old repo.

**Important:** While testing the repo is encouraged, we still advise you to be cautious and start with non-critical systems.

## Using the repository

### With PGP verification (recommended)

The repository database and packages are PGP signed. An installable `archzfs-keyring` package is planned but is not yet deployed in this repository, so establishing trust in the current release key remains a manual step.

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

If you cannot establish trust in the release key yet, you may consciously choose temporary use with signature verification disabled. This prevents Pacman from verifying the authenticity of the repository database and packages; revisit this choice when the ArchZFS keyring is deployed or when you can verify and import the release key.

Add the following to `/etc/pacman.conf` instead:
```ini
[archzfs]
SigLevel = Never
Server = https://github.com/archzfs/archzfs/releases/download/experimental
```
