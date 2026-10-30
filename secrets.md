# Secrets

All the secrets live in the `signing` environment, which only runs from `main`.

## Who can update main

Every push to `main` signs the repo metadata, so `main` has a ruleset (`main-solo-publicadores`):
nobody can push, merge or force-push to it, and it cannot be deleted. Only two actors bypass it:

- the `adhoc-apt-publisher` GitHub App: the release workflows of each tool push the `.deb` with it,
  and `update-repo.yml` pushes the signed metadata with it;
- the `apt-maintainers` team (no bots on purpose).

To publish by hand, ask someone in `apt-maintainers`.

## adhoc-apt-publisher

APT_PUBLISHER_CLIENT_ID (repo variable) and APT_PUBLISHER_PRIVATE_KEY (`signing` environment).
The private key is in Bitwarden: "GitHub App adhoc-apt-publisher — private key".

## GPG

GPG_PRIVATE_KEY

```sh
gpg --export-secret-keys --armor apt@example.com > apt-private.asc
```

This cert is already generetad and stored on secure vault. If you need to create it do the following steps

```sh
# gpg --full-generate-key 
# gpg --armor --export apt@example.com > apt.asc
```

GPG_EMAIL

```sh
apt@example.com
```
