#!/bin/bash
# Relatório rápido do console por SSH (só leitura). IP: R36S_IP=... ou padrão em lib.sh
set -euo pipefail
source "$(dirname "$0")/lib.sh"

r36s_ssh 'bash -s' <<'EOF' || die "sem conexão com $R36S_USER@$R36S_IP (console ligado? SSH ativo? mudou o IP?)"
echo "modelo:   $(tr -d '\0' < /proc/device-tree/model)"
echo "sistema:  $(. /etc/os-release; echo "$PRETTY_NAME") | kernel $(uname -r)"
echo "uptime:   $(uptime -p)"
echo "bateria:  $(cat /sys/class/power_supply/*/capacity 2>/dev/null | head -1)% ($(cat /sys/class/power_supply/*/status 2>/dev/null | head -1))"
t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); echo "temp:     $((t/1000)) C"
echo "cpu:      $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) kHz ($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor))"
echo "memória:  $(free -m | awk '/Mem:/{print $3"/"$2" MB usados"}')  swap: $(free -m | awk '/Swap:/{print $3"/"$2" MB"}')"
echo "discos:"; df -h / /boot /roms | sed 's/^/  /'
echo "rede:";   ip -br a | grep -v '^lo' | sed 's/^/  /'
echo "usb:";    for d in /sys/bus/usb/devices/[0-9]*; do [ -f "$d/product" ] && echo "  $(cat $d/manufacturer 2>/dev/null) $(cat $d/product)"; done
echo "serviços com falha: $(systemctl --failed --no-legend | wc -l)"
EOF
