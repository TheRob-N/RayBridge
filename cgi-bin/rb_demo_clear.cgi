#!/usr/bin/env python3
import json, os, time

STATE = "/opt/raybridge/state/demo.json"

data = {
    "active": False,
    "until": int(time.time()),
    "message": ""
}

os.makedirs(os.path.dirname(STATE), exist_ok=True)
tmp = STATE + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f)
os.replace(tmp, STATE)

print("Content-Type: application/json")
print("Cache-Control: no-store")
print()
print(json.dumps({"ok": True, "active": False}))
