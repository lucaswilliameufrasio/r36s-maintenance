#!/bin/bash
# Restaura um system.img.gz no cartão. APAGA o sistema do cartão (as ROMs ficam
# fora da imagem; recopie com: rsync -rtv backups/<data>/roms/ /Volumes/EASYROMS/).
# Uso: ./restore-system.sh arquivo.img.gz [diskN]   (sem diskN, lista os cartões para escolher)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

IMG="${1:?uso: $0 arquivo.img.gz [diskN]}"
[[ -f "$IMG" ]] || die "arquivo não encontrado: $IMG"
gzip -t "$IMG" || die "arquivo gzip corrompido"
DISK="${2:-}"; [[ -n "$DISK" ]] || DISK="$(pick_sd_card)"; DISK="${DISK#/dev/}"
require_sd_card "$DISK" "$(dirname "$IMG")"
confirm_disk "$DISK" "RESTAURAR (apaga o sistema)" sim

diskutil unmountDisk force "/dev/$DISK" >/dev/null
gunzip -c "$IMG" | sudo dd of="/dev/r$DISK" bs=4m
sync
diskutil eject "/dev/$DISK" || true
echo "Restaurado. Coloque o cartão no console."
