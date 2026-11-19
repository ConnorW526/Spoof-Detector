#!/bin/bash
# Puts both Wi-Fi cards into monitor mode with fixed names.
# Uses airmon-ng because Intel/iwlwifi needs a real monitor vif, which a
# manual "iw set type monitor" does NOT create.
#   mt76*   (ALFA)  -> attack0  (broadcaster)
#   iwlwifi (Intel) -> sensor0  (detector)

sudo airmon-ng check kill >/dev/null 2>&1

# Identify each card by driver before changing anything
declare -A ROLE
for dev in $(iw dev | awk '$1=="Interface"{print $2}'); do
    drv=$(basename "$(readlink -f /sys/class/net/$dev/device/driver)")
    case "$drv" in
        mt76*)   ROLE[$dev]=attack0 ;;
        iwlwifi) ROLE[$dev]=sensor0 ;;
    esac
done

for dev in "${!ROLE[@]}"; do
    role=${ROLE[$dev]}
    sudo airmon-ng start "$dev" >/dev/null 2>&1    # creates ${dev}mon
    sudo ip link set "${dev}mon" down
    sudo ip link set "${dev}mon" name "$role"
    sudo ip link set "$role" up
    sudo iw dev "$role" set channel 6
    echo "[*] $dev -> $role (monitor, channel 6)"
done

echo "[+] sensor0 = detector, attack0 = broadcaster (channel 6)"
iw dev | awk '$1=="Interface"{print "    " $2}'
