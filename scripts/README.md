# Scripts de manutenção do R36S

| Script | O que faz | Precisa de |
|---|---|---|
| `backup-sd.sh [diskN]` | ROMs (rsync) + sistema (`system.img.gz`) em `backups/<data>/` | cartão no Mac, sudo |
| `restore-system.sh arquivo.img.gz [diskN]` | Regrava o sistema (apaga o cartão; ROMs ficam de fora) | cartão no Mac, sudo |
| `verify-roms.sh pasta [volume]` | Compara ROMs por checksum | cartão no Mac |
| `console-status.sh` | Bateria, temperatura, memória, discos, rede, USB | console ligado, SSH |
| `console-tune.sh [--undo]` | Aplica/desfaz zram e ajustes de memória | console ligado, SSH |

- Sem `diskN`, os scripts listam os discos removíveis (tamanho, modelo, partições) e você escolhe pelo número. Eles recusam discos internos ou não removíveis. O backup pede `s`; a restauração, que apaga o cartão, pede `sim`.
- O IP do console é `10.99.99.153`. Se mudar: `R36S_IP=1.2.3.4 ./console-status.sh`.
- SSH por chave: `ssh-copy-id ark@<ip>` (senha padrão `ark`). Se o SSH estiver fechado, ative em Options → Advanced.
- Depois de regravar o cartão, o `EASYROMS` é reformatado no primeiro boot. Recopie as ROMs:
  `rsync -rtv backups/<data>/roms/ /Volumes/EASYROMS/`.
- DTBs do painel 4 (60 Hz): `../panel4-60hz-dtbs/`. Numa imagem nova, copie
  `rg351mp-kernel.dtb` como `rg351mp-uboot.dtb` e `rk3326-r35s-linux.dtb` como `rk3326-rg351mp-linux.dtb` na partição BOOT.
