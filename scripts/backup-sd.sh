#!/bin/bash
# Backup do microSD do R36S, só leitura no cartão.
#   1) ROMs  -> backups/<data>/roms/            (rsync)
#   2) Sistema (bootloader + tabela de partições + BOOT + Linux, sem as ROMs)
#            -> backups/<data>/system.img.gz   (dd + gzip)
# Uso: ./backup-sd.sh [diskN]      (sem argumento, lista os cartões para escolher)
#      BACKUP_DIR=... muda o destino
set -euo pipefail
source "$(dirname "$0")/lib.sh"

DISK="${1:-}"; [[ -n "$DISK" ]] || DISK="$(pick_sd_card)"; DISK="${DISK#/dev/}"
DEST="${BACKUP_DIR:-$PROJECT_DIR/backups}/$(date +%Y-%m-%d)"
mkdir -p "$DEST"
require_sd_card "$DISK" "$DEST"
confirm_disk "$DISK" "Backup (só leitura)"

# 1) ROMs, com o volume ainda montado
ROMS_PART="/dev/${DISK}s3"
MNT="$(diskutil info "$ROMS_PART" 2>/dev/null | sed -n 's/^ *Mount Point: *//p')"
if [[ -z "$MNT" ]]; then diskutil mount "$ROMS_PART" >/dev/null; MNT="$(diskutil info "$ROMS_PART" | sed -n 's/^ *Mount Point: *//p')"; fi
[[ -n "$MNT" ]] || die "não consegui montar $ROMS_PART"
echo "== ROMs: $MNT -> $DEST/roms/"
mkdir -p "$DEST/roms"
rsync -rt --info=progress2 \
  --exclude='.fseventsd' --exclude='.Spotlight-V100' --exclude='.Trashes' \
  --exclude='System Volume Information' --exclude='._*' --exclude='.DS_Store' \
  "$MNT/" "$DEST/roms/"

# 2) Sistema: do começo do cartão até o início da partição 3 (arredondado para 4 MiB)
OFFSET="$(diskutil info "$ROMS_PART" | awk '/Partition Offset/{print $3}')"
[[ "$OFFSET" =~ ^[0-9]+$ ]] || die "não consegui ler o offset da partição 3"
COUNT=$(( (OFFSET + 4194303) / 4194304 ))
echo "== Sistema: $COUNT x 4 MiB -> $DEST/system.img.gz"
diskutil unmountDisk force "/dev/$DISK" >/dev/null
sudo dd if="/dev/r$DISK" bs=4m count="$COUNT" status=progress | gzip -1 > "$DEST/system.img.gz"
gzip -t "$DEST/system.img.gz" && echo "gzip OK"
ls -lh "$DEST/system.img.gz"
diskutil mountDisk "/dev/$DISK" >/dev/null || true
echo "Pronto: $DEST"
