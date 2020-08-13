#!/usr/bin/bash
ext=$1
body=$2
# Replace all '\f' with '\n' now that entropy has been preseved
tr '\f' '\n' <<< $body | bat --color=always --plain --language ${ext##.}
