#!/bin/bash
# Aplica (ou desfaz com --undo) as otimizações de memória no console, por SSH.
# É idempotente: pode rodar de novo depois de regravar o cartão.
#   zram 384 MB (lzo) como swap, ajustes de vm.*, timers do apt desligados.
# Uso: ./console-tune.sh [--undo]
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if [[ "${1:-}" == "--undo" ]]; then
  r36s_ssh 'sudo systemctl disable --now zram-swap.service 2>/dev/null; sudo rm -f /etc/systemd/system/zram-swap.service /etc/sysctl.d/99-r36s-tuning.conf; sudo systemctl daemon-reload; sudo systemctl enable apt-daily.timer apt-daily-upgrade.timer 2>&1 | tail -1; echo "revertido (os valores de vm.* voltam no próximo boot)"'
  exit 0
fi

r36s_ssh 'sudo bash -s' <<'EOF' || die "falha ao aplicar (SSH ou sudo)"
set -e
cat > /etc/systemd/system/zram-swap.service <<'U'
[Unit]
Description=zram compressed swap
After=local-fs.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c "echo lzo > /sys/block/zram0/comp_algorithm; echo 384M > /sys/block/zram0/disksize; /sbin/mkswap /dev/zram0; /sbin/swapon -p 100 /dev/zram0"
ExecStop=/sbin/swapoff /dev/zram0
ExecStopPost=/bin/sh -c "echo 1 > /sys/block/zram0/reset"

[Install]
WantedBy=multi-user.target
U
cat > /etc/sysctl.d/99-r36s-tuning.conf <<'S'
vm.swappiness=100
vm.page-cluster=0
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5
S
systemctl daemon-reload
systemctl is-active --quiet zram-swap.service || systemctl enable --now zram-swap.service
while IFS== read -r k v; do echo "$v" > "/proc/sys/${k//./\/}"; done < /etc/sysctl.d/99-r36s-tuning.conf
systemctl disable --now apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
echo "swap:"; cat /proc/swaps
echo "swappiness=$(cat /proc/sys/vm/swappiness)"
EOF
