# Adhoc APT Repository

```sh
wget -qO - https://apt.dev-adhoc.com/adhoc-devops.asc | sudo gpg --dearmor -o /usr/share/keyrings/adhoc-devops.gpg
echo "deb [signed-by=/usr/share/keyrings/adhoc-devops.gpg]  https://apt.dev-adhoc.com/ stable main" | sudo tee /etc/apt/sources.list.d/adhoc.list
```

## Paquetes armados en este repo

`build/<paquete>/build.sh` arma el `.deb` de un paquete de terceros. Para
publicarlo, corré el script y dejá el `.deb` en `pool/`:

```sh
build/fprintd-elan-0c4b/build.sh pool
```

- `fprintd-elan-0c4b`: lector de huellas Elan `04f3:0c4b` (ThinkPad E14/E15
  Gen 4) en Debian 12 y 13. El paquete no trae el driver de Lenovo: lo baja
  al instalarse y verifica su sha256.
