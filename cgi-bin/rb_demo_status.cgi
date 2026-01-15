#!/usr/bin/env python3
import json, os, time

demo_file = "/opt/raybridge/state/demo.json"
now = int(time.time())
data = {"active": False, "message": "", "until": 0}

try:
    with open(demo_file, "r") as f:
        data = json.load(f) or data
except:
    pass

active = bool(data.get("active")) and int(data.get("until",0) or 0) > now
data["active"] = active
data["seconds_left"] = max(0, int(data.get("until",0) or 0) - now)

print("Content-Type: application/json\n")
print(json.dumps(data, indent=2))
