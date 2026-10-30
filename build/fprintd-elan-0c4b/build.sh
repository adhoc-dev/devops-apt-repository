#!/bin/bash
# Build fprintd-elan-0c4b: Ubuntu libfprint-tod for fprintd; postinst downloads Lenovo's Elan TOD driver.
set -euo pipefail
PKG=fprintd-elan-0c4b
VERSION=0.0.8-2
TOD=1:1.94.3+tod1-0ubuntu2~22.04.08
TODF=1.94.3+tod1-0ubuntu2~22.04.08
POOL=https://archive.ubuntu.com/ubuntu/pool/main/libf/libfprint
LENOVO=https://download.lenovo.com/pccbbs/mobiles/r1slf01w.zip
LENOVO_SO_SHA=a5060ccdfc0c613bd4522be29f87cd94f098e6b83294cf02cd5a958b24b27f80
declare -A SHA=(
  [libfprint-2-2_${TODF}_amd64.deb]=e351e55a912a2b7481dafc272afd0e2c1d3de18758cdae95144fc5647a1c4b98
  [libfprint-2-tod1_${TODF}_amd64.deb]=93b4c4fba8ac9b19f83a258b2780de44b6c1661379a882be2cf9024d794af508
)

W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
for f in "${!SHA[@]}"; do
  curl -fsSL -o "$W/$f" "$POOL/$f"
  echo "${SHA[$f]}  $W/$f" | sha256sum -c -
  dpkg-deb -x "$W/$f" "$W/ex"
done

R=$W/root; L=$R/usr/lib/$PKG; D=$R/usr/share/doc/$PKG
install -Dm644 "$W/ex/usr/lib/x86_64-linux-gnu/libfprint-2.so.2.0.0" "$L/libfprint-2.so.2"
install -Dm644 "$W/ex/usr/lib/x86_64-linux-gnu/libfprint-2-tod.so.1" "$L/libfprint-2-tod.so.1"
install -d "$R/usr/lib/systemd/system/fprintd.service.d"
printf '[Service]\nEnvironment=LD_LIBRARY_PATH=/usr/lib/%s\nEnvironment=FP_TOD_DRIVERS_DIR=/var/lib/%s\n' "$PKG" "$PKG" \
  > "$R/usr/lib/systemd/system/fprintd.service.d/$PKG.conf"
install -d "$D"
cat > "$D/copyright" <<C
libfprint-2.so.2, libfprint-2-tod.so.1: Ubuntu libfprint $TOD, LGPL-2.1+.
  Source: $POOL
libfprint-2-tod1-elan.so is not shipped. postinst downloads it from Lenovo (DS560939):
  $LENOVO
C

install -d "$R/DEBIAN"
cat > "$R/DEBIAN/control" <<C
Package: $PKG
Version: $VERSION
Architecture: amd64
Maintainer: Devops Team <devops@adhoc.inc>
Depends: fprintd, curl, unzip, libglib2.0-0 | libglib2.0-0t64, libgusb2, libgudev-1.0-0, libnss3, libpixman-1-0, libusb-1.0-0, libssl3 | libssl3t64
Section: misc
Priority: optional
Homepage: https://support.lenovo.com/us/en/downloads/ds560939-elan-fingerprint-driver-for-ubuntu-2204-thinkpad-e14-gen-4-e15-gen-4
Description: Elan 04f3:0c4b fingerprint driver for fprintd (ThinkPad E14/E15 Gen 4)
 The stock libfprint elan driver fails to enroll on this sensor.
 This package ships libfprint-tod in a private directory and loads it only
 in fprintd through a systemd drop-in. On install it downloads Lenovo's
 proprietary TOD driver from download.lenovo.com and checks its sha256.
C

cat > "$R/DEBIAN/postinst" <<S
#!/bin/sh
set -e
DIR=/var/lib/$PKG
SO=\$DIR/libfprint-2-tod1-elan.so
SHA=$LENOVO_SO_SHA

fetch() {
  T=\$(mktemp -d)
  trap 'rm -rf "\$T"' EXIT
  curl -fsSL --retry 3 -o "\$T/r.zip" "$LENOVO" || return 1
  unzip -q "\$T/r.zip" -d "\$T/a" && unzip -q "\$T"/a/*.zip -d "\$T/b" || return 1
  echo "\$SHA  \$T/b/libfprint-2-tod1-elan.so" | sha256sum -c --quiet - || return 1
  install -Dm644 "\$T/b/libfprint-2-tod1-elan.so" "\$SO"
}

if [ "\$1" = configure ]; then
  if ! echo "\$SHA  \$SO" | sha256sum -c --quiet - >/dev/null 2>&1; then
    if ! fetch; then
      echo "W: $PKG: could not download the Lenovo driver. Retry: sudo dpkg-reconfigure $PKG" >&2
    fi
  fi
  if [ -d /run/systemd/system ]; then
    systemctl daemon-reload || true
    systemctl try-restart fprintd.service || true
  fi
fi
S

cat > "$R/DEBIAN/postrm" <<S
#!/bin/sh
set -e
case "\$1" in
  remove|purge) rm -rf /var/lib/$PKG ;;
esac
if [ -d /run/systemd/system ]; then
  systemctl daemon-reload || true
  systemctl try-restart fprintd.service || true
fi
S
chmod 755 "$R/DEBIAN/postinst" "$R/DEBIAN/postrm"

dpkg-deb --root-owner-group -Zxz --build "$R" "${1:-.}/${PKG}_${VERSION}_amd64.deb"
