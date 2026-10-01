#!/bin/bash
# Funções compartilhadas pelos scripts de manutenção do R36S.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R36S_IP="${R36S_IP:-10.99.99.153}"
R36S_USER="${R36S_USER:-ark}"

die() { echo "erro: $*" >&2; exit 1; }

# Valida que o disco é externo e removível, e que o destino não está nele.
# Uso: require_sd_card diskN [pasta_destino]
require_sd_card() {
  local disk="${1#/dev/}" dest="${2:-}"
  [[ "$disk" =~ ^disk[0-9]+$ ]] || die "informe o disco como diskN (veja: diskutil list external physical)"
  local info; info="$(diskutil info "/dev/$disk" 2>/dev/null)" || die "disco /dev/$disk não encontrado"
  grep -q "Device Location:.*External" <<<"$info" || die "/dev/$disk não é externo; recusando"
  grep -q "Removable Media:.*Removable" <<<"$info" || die "/dev/$disk não é removível; recusando"
  if [[ -n "$dest" ]]; then
    local dest_dev; dest_dev="$(df "$dest" | awk 'NR==2{print $1}')"
    [[ "$dest_dev" == /dev/${disk}* ]] && die "o destino $dest está dentro de /dev/$disk"
  fi
  return 0
}

# Lista os discos removíveis e deixa escolher por número. Imprime o diskN escolhido.
# Menu e prompt vão para stderr, para poder usar: DISK="$(pick_sd_card)"
pick_sd_card() {
  local ids=() id info size name parts i choice
  for id in $(diskutil list external physical | awk '/^\/dev\/disk/{sub("/dev/","",$1); print $1}'); do
    diskutil info "/dev/$id" | grep -q "Removable Media:.*Removable" && ids+=("$id")
  done
  [[ ${#ids[@]} -gt 0 ]] || die "nenhum cartão removível encontrado (conecte o microSD)"
  echo "Discos removíveis encontrados:" >&2
  i=0
  for id in "${ids[@]}"; do
    i=$((i+1))
    info="$(diskutil info "/dev/$id")"
    size="$(sed -n 's/^ *Disk Size: *\([^(]*\)(.*/\1/p' <<<"$info" | head -1)"
    name="$(sed -n 's/^ *Device \/ Media Name: *//p' <<<"$info" | head -1)"
    parts="$(diskutil list "/dev/$id" | awk '$1 ~ /^[1-9][0-9]*:$/ { n = (NF > 5) ? $3 : $2; printf "%s%s", sep, n; sep = ", " }')"
    printf '  %d) %-7s %-10s %-18s [%s]\n' "$i" "$id" "$size" "$name" "$parts" >&2
  done
  read -r -p "Escolha o número do cartão: " choice
  [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#ids[@]} ]] || die "escolha inválida"
  echo "${ids[$((choice-1))]}"
}

# Mostra o disco e pede confirmação. Uso: confirm_disk diskN "ação" [palavra]
# A palavra padrão é "s"; use "sim" para ações destrutivas.
confirm_disk() {
  local disk="${1#/dev/}" word="${3:-s}" ans
  echo >&2
  diskutil list "/dev/$disk" >&2
  echo >&2
  read -r -p "$2 em /dev/$disk. Digite '$word' para continuar: " ans
  [[ "$ans" == "$word" ]] || die "cancelado"
}

r36s_ssh() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$R36S_USER@$R36S_IP" "$@"
}
