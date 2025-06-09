# Secrets

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
