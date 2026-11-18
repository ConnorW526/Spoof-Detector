from scapy.all import sniff, Dot11, Dot11Beacon, Dot11Elt
import json

IFACE = "sensor0"

baseline = {}
def process(pkt):
    if not pkt.haslayer(Dot11Beacon):
        return
    bssid = pkt[Dot11].addr2
    ssid = None
    elt = pkt.getlayer(Dot11Elt)
    while elt:
        if elt.ID == 0:
            ssid = elt.info.decode(errors="ignore")
            break
        elt = elt.payload.getlayer(Dot11Elt)
    if ssid is None or ssid == "":
        return
    baseline.setdefault(ssid, set()).add(bssid)
    print(f"seen: {ssid!r:25} {bssid}")

print("Capturing baseline for 60s...")
sniff(iface=IFACE, prn=process, store=0, timeout=60)
json.dump({s: sorted(m) for s, m in baseline.items()}, open("baseline.json","w"), indent=2)
print(f"\nSaved {len(baseline)} networks to baseline.json")