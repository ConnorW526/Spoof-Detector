import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
from scapy.all import sniff, Dot11, Dot11Beacon, Dot11Elt
import json

IFACE = "sensor0"

baseline = {s: set(m) for s, m in json.load(open("baseline.json")).items()}
counts, alerted = {}, set()

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
    key = (ssid, bssid)
    counts[key] = counts.get(key, 0) + 1
    if counts[key] < 3 or key in alerted:
        return
    if ssid in baseline and bssid not in baseline[ssid]:
        print(f"[SPOOF] {ssid!r} from unknown BSSID {bssid}")
        print(f"        known BSSIDs: {baseline[ssid]}")
        alerted.add(key)
    elif ssid not in baseline:
        print(f"[NEW]   {ssid!r} ({bssid}) not in baseline")
        alerted.add(key)

print("Monitoring live... Ctrl-C to stop")
sniff(iface=IFACE, prn=process, store=0)