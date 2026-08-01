#!/usr/bin/env python

import subprocess
import json

LIBEXEC = "/data/data/com.termux/files/usr/libexec/termux-api"


def get_data() -> dict:
    ret = {"result": {}, "returncode": -1}

    command = [LIBEXEC, "AudioInfo"]
    aud = subprocess.run(command, capture_output=True, text=True)
    ret["result"] = json.loads(aud.stdout)
    ret["returncode"] = aud.returncode
    return ret


old_aud = None
a = "WIREDHEADSET_IS_CONNECTED"
while True:
    aud = get_data()

    if aud["returncode"] != 0:
        break

    if old_aud is None:
        old_aud = aud["result"]
        continue

    z = aud["result"]

    if z[a] != old_aud[a]:
        print("pause")
    old_aud = aud["result"]
