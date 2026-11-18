#!/bin/bash
# Renames the two Wi-Fi cards by driver so names never shift between boots:
#   mt76* (ALFA)    -> attack0   (broadcasts the evil twin)
#   iwlwifi (Intel) -> sensor0   (runs the detector)
sudo airmon-ng check kill >/dev/null 2>&1
for dev in $(iw dev | awk '$1=="Interface"{print $2}'); do
    drv=$(basename "$(readlink -f /sys/class/net/$dev/device/driver)")
    case "$drv" in
        mt76*)   name=attack0 ;;
        iwlwifi) name=sensor0 ;;
        *)       continue ;;
    esac
    echo "[*] $dev ($drv) -> $name"
    sudo ip link set "$dev" down
    sudo iw dev "$dev" set type monitor 2>/dev/null
    sudo ip link set "$dev" name "$name"
    sudo ip link set "$name" up
    sudo iw dev "$name" set channel 6
done
echo "[+] sensor0 = detector, attack0 = broadcaster (channel 6)"