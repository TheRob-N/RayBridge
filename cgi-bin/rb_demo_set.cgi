#!/usr/bin/env python3
import json, os, time, urllib.parse

STATE = "/opt/raybridge/state/demo.json"

qs = os.environ.get("QUERY_STRING", "")
q = urllib.parse.parse_qs(qs)

msg = q.get("message", ["STINGRAY DETECTED • DEMO"])[0]
try:
    dur = int(q.get("duration", ["60"])[0])
except:
    dur = 60

now = int(time.time())
until = now + max(1, min(dur, 3600))  # clamp 1..3600s

data = {
    "active": True,
    "until": until,
    "message": msg
}

os.makedirs(os.path.dirname(STATE), exist_ok=True)
tmp = STATE + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f)
os.replace(tmp, STATE)

print("Content-Type: application/json")
print("Cache-Control: no-store")
print()
print(json.dumps({"ok": True, "active": True, "until": until, "message": msg}))
