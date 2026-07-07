#!/usr/bin/env bash
# Poda pool/: mantiene solo las últimas N versiones de cada paquete .deb.
#
# Uso:
#   scripts/prune-pool.sh [--dry-run]
#   KEEP=4 scripts/prune-pool.sh
#
# Variables:
#   KEEP  cantidad de versiones a conservar por paquete (default: 4)
#   POOL  directorio de pool (default: pool)
#
# El nombre de paquete se toma del filename `<nombre>_<version>_<arch>.deb`.
# Las versiones se ordenan con `sort -V` (version sort) y se eliminan las más
# viejas por encima de KEEP. Si el repo es un working tree de git, usa `git rm`
# para que la eliminación quede staged; si no, usa `rm`.
set -euo pipefail

KEEP="${KEEP:-4}"
POOL="${POOL:-pool}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# Ubicarse en la raíz del repo si estamos dentro de un working tree de git.
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  cd "$(git rev-parse --show-toplevel)"
fi

if [ ! -d "$POOL" ]; then
  echo "No existe el directorio '$POOL', nada que podar." >&2
  exit 0
fi

# Nombres de paquete únicos (campo previo al primer '_').
pkgs=$(find "$POOL" -maxdepth 1 -name '*.deb' -printf '%f\n' | sed 's/_.*//' | sort -u)

for pkg in $pkgs; do
  # Versiones ÚNICAS del paquete (campo 2 del filename), ordenadas ascendente
  # (la más vieja primero). Se dedupe por versión para que un paquete con
  # varios .deb por versión (p.ej. amd64 + i386) cuente como una sola versión.
  mapfile -t versions < <(find "$POOL" -maxdepth 1 -name "${pkg}_*.deb" -printf '%f\n' \
    | awk -F_ '{print $2}' | sort -u -V)
  count=${#versions[@]}
  if [ "$count" -le "$KEEP" ]; then
    echo "$pkg: $count versión(es) — nada que podar (KEEP=$KEEP)."
    continue
  fi
  remove=$(( count - KEEP ))
  echo "$pkg: $count versiones — elimino las $remove más viejas, conservo $KEEP."
  for ((i = 0; i < remove; i++)); do
    v="${versions[$i]}"
    # Todos los archivos de esa versión (cualquier arch).
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      echo "  - rm $f"
      if [ "$DRY_RUN" -eq 0 ]; then
        git rm -q "$f" 2>/dev/null || rm -f "$f"
      fi
    done < <(find "$POOL" -maxdepth 1 -name "${pkg}_${v}_*.deb")
  done
done
