# r36s-maintenance

Notas e scripts para manter um console **R36S (clone, RK3326)** rodando
[dArkOS](https://github.com/christianhaitian/dArkOS), a partir de um Mac.

Foi montado numa sessão real de upgrade: ArkOS de 2024 → dArkOS oficial, com backup,
ajuste de painel, PortMaster e otimizações. Os scripts repetem essas etapas.

> **Atenção:** gravar imagem no cartão apaga tudo nele. Os scripts recusam discos
> internos ou não removíveis, mas confira sempre o disco antes de confirmar.

## Contexto do aparelho

- O R36S "genuíno" e os clones são placas diferentes. Dá para saber pelo DTB em uso:
  este aparelho carregava `rk3326-r35s-linux.dtb`, e o modelo reportado no Linux é
  `Game Console R35S/R36S fix by lxc`, ou seja, um **clone**.
- O que decide a instalação é o **painel da tela**, não a marca. Se o DTB estiver errado,
  a tela fica preta ou torta.
- A porta OTG só funciona como host (WiFi/ethernet/pendrive). O console **não** aparece
  como dispositivo USB no Mac. O acesso é por SSH ou lendo o cartão.

## Scripts

Ficam em [`scripts/`](scripts/README.md).

| Script | O que faz |
|---|---|
| `backup-sd.sh [diskN]` | ROMs (rsync) + sistema (`system.img.gz`, sem repetir as ROMs) |
| `restore-system.sh arquivo.img.gz [diskN]` | Regrava o sistema no cartão |
| `verify-roms.sh pasta [volume]` | Compara ROMs por checksum |
| `console-status.sh` | Bateria, temperatura, memória, discos, rede, USB (SSH) |
| `console-tune.sh [--undo]` | Aplica/desfaz zram e ajustes de memória (SSH) |

Sem `diskN`, os scripts de cartão listam os discos removíveis e você escolhe pelo número.
Requisitos: macOS, `rsync`, `7z` (`brew install p7zip`) e a [`gh`](https://cli.github.com/)
só se for baixar a imagem pela linha de comando.

## Fluxo de upgrade (resumo)

1. **Backup** do cartão atual: `scripts/backup-sd.sh`.
2. **Baixar** a imagem do [repositório oficial](https://github.com/christianhaitian/dArkOS/releases).
   Para clones RK3326 foi usada a `dArkOS_RG351MP_*`. Confira o SHA-256 publicado:
   ```
   gh release download <tag> -R christianhaitian/dArkOS -p 'dArkOS_RG351MP_*.img.7z.*'
   shasum -a 256 dArkOS_RG351MP_*.img.7z.*
   7z x dArkOS_RG351MP_*.img.7z.001
   ```
3. **Ajustar o painel** na imagem antes de gravar. Monte a partição BOOT (FAT32) da imagem
   e troque os DTBs pelos do seu painel. No pacote de painéis que vinha no cartão antigo
   (`New Screens/Panel N/`), a correspondência foi:

   | Pacote de painéis | Imagem oficial |
   |---|---|
   | `rg351mp-kernel.dtb` | `rg351mp-uboot.dtb` |
   | `rk3326-r35s-linux.dtb` | `rk3326-rg351mp-linux.dtb` |

   Para saber qual é o seu painel, compare por `md5` o DTB em uso no cartão antigo com os
   de cada pasta `Panel N`. Guarde os originais como `.orig`.
4. **Gravar** (apaga o cartão): `sudo dd if=<imagem>.img of=/dev/rdiskN bs=4m status=progress`
   com o cartão desmontado (`diskutil unmountDisk force /dev/diskN`).
5. **Primeiro boot:** sem carregador. O console reinicia duas vezes e **reformata o
   `EASYROMS` como exFAT**. Só depois disso recopie as ROMs:
   `rsync -rtv backups/<data>/roms/ /Volumes/EASYROMS/`.
6. **SSH:** ative em *Options → Advanced*, depois `ssh-copy-id ark@<ip>` (senha padrão `ark`).
7. **Otimizações:** `scripts/console-tune.sh`.
8. **PortMaster:** vem como `Install.PortMaster.sh` em *Tools*. Rode pelo menu ou por SSH
   (precisa de internet; os runtimes baixam na primeira abertura).

## Otimizações aplicadas

O CPU (1,5 GHz), a GPU (520 MHz) e a memória (786 MHz) já vêm no máximo. O ganho foi na RAM
(895 MB):

- zram de 384 MB (`lzo`) como swap, prioridade 100;
- `vm.swappiness=100`, `vm.page-cluster=0`, `vm.vfs_cache_pressure=50`;
- `vm.dirty_ratio=10` e `vm.dirty_background_ratio=5`, para escritas menores no cartão;
- timers `apt-daily*` desligados.

`scripts/console-tune.sh --undo` desfaz tudo.

## Limitações conhecidas

- **Moonlight:** não foi encontrada fonte oficial confiável para o RK3326. Um guia da
  comunidade diz que funciona no dArkOS "Enhanced", mas isso não foi verificado.
  Procure no PortMaster.
- **Ethernet USB (ASIX AX88179A):** o adaptador é reconhecido no Mac, mas não foi testado no
  console. O WiFi Realtek 802.11ac funcionou.
- O painel testado foi o **Panel 4 (60 Hz)**. Outros painéis exigem outro conjunto de DTBs.
- O IP do console vem do DHCP. Use `R36S_IP=<ip> scripts/console-status.sh`.

## Não está neste repositório

ROMs, imagens do sistema, backups e os DTBs de terceiros (ver `.gitignore`).
