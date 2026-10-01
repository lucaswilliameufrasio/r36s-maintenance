#!/bin/bash
# Compara por checksum uma pasta de ROMs com o cartão (só leitura). Lento: lê tudo.
# Uso: ./verify-roms.sh pasta_backup [/Volumes/EASYROMS]
set -euo pipefail
SRC="${1:?uso: $0 pasta_backup [volume]}"
DST="${2:-/Volumes/EASYROMS}"
[[ -d "$SRC" && -d "$DST" ]] || { echo "erro: pasta ou volume não encontrado" >&2; exit 1; }
echo "Arquivos diferentes ou faltando em $DST (vazio = tudo igual):"
rsync -rnc --exclude='.fseventsd' --exclude='.Spotlight-V100' --exclude='.Trashes' \
  --exclude='System Volume Information' --exclude='._*' --exclude='.DS_Store' \
  --out-format='%n' "$SRC/" "$DST/"
echo "verificação concluída"
