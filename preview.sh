ext=$1
body=$2
tr '\f' '\n' <<< $body | bat --color=always --plain --language ${ext##.}
# tr '\f' '\n' <<< $2 | tail -n +2 |
# id=$(cut -b '-13' <<< $2)
# bat --color=always --plain --language ${ext##.} "$dir$id$ext"
