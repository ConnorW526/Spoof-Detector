# Spoof Detector

A Python-based Wi-Fi evil-twin detector that flags rogue access points impersonating known networks by watching for a trusted SSID broadcast from an untrusted MAC.

## How It Works

The baseline program records all detected beacons for one minute to build a list of safe Wi-Fi networks, recording their SSIDs and their associated BSSIDs.

A beacon is the frame an access point broadcasts to announce itself. The SSID is the network's name, which anyone can copy. The BSSID is the access point's hardware MAC address, which is much harder to fake. The baseline ties each name to the real MAC(s) it should come from.

The detector then listens to beacons live and checks each one against the baseline:

- If a known SSID shows up from a BSSID that isn't on its trusted list, that's an evil twin — same name, wrong hardware — and it prints a **SPOOF** alert.
- If an SSID isn't in the baseline at all, it prints a lower-priority **NEW** alert.

To cut down on false alarms from corrupted frames, the detector only acts on a network after it has seen the same SSID/BSSID pair at least three times.

## Requirements

- Kali Linux
- An external USB adapter with a MediaTek MT7612U chipset and mt76 driver.
- A built-in Intel Arrow Lake CNVi Wi-Fi card, or any internal Wi-Fi card that can enter monitor mode.

Detection requires one adapter that supports monitor mode (to capture beacons). The demo requires a second adapter that supports AP/injection mode, used only to simulate the attack so the whole thing is self-contained.

## Setup

```bash
git clone https://github.com/ConnorW526/Spoof-Detector.git
cd Spoof-Detector
bash setup.sh
```

`setup.sh` identifies the two cards by their driver, renames them to fixed roles (`sensor0` for the detector, `attack0` for the broadcaster), switches them into monitor mode, and sets them to channel 6 — so the interface names never shift between boots.

## Usage

**1. Build the baseline**
```bash
sudo python3 baseline.py
```
Captures beacons for 60 seconds and saves the trusted SSID-to-BSSID map to `baseline.json`.

**2. Run the detector**
```bash
sudo python3 detect.py
```
Monitors beacons live and prints a SPOOF or NEW alert whenever it sees a network that doesn't match the baseline.

**3. Test it (simulate an evil twin)**
```bash
sudo airbase-ng -e CoreNet -c 6 attack0
```
Broadcasts a fake "CoreNet" access point from the second card. CoreNet's real BSSIDs are in the baseline but this fake one's MAC isn't, so the detector flags it:
```
[SPOOF] 'CoreNet' from unknown BSSID 00:c0:ca:b9:60:93
```

## Limitations

- Watches only one channel at a time (channel 6 by default), so an evil twin on a different channel would be missed.
- Rule-based: it only catches a name/MAC mismatch. An attacker who also spoofs the real BSSID would not be flagged.
- Depends on a clean baseline. If a rogue AP is already broadcasting during the 60-second capture, it gets recorded as trusted.
- Ignores hidden networks (empty SSID), since many unrelated access points share a blank name.
