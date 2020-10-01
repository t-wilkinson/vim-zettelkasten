#!/usr/bin/bash
dir=$1
ext=$2
for f in $(command fd . "$dir" -e "$ext"); do
    # Human readable time format
    base=$(basename $f)
    year=${base:0:4}
    week=${base:4:2}
    day=${base:6:1}
    hours=${base:7:2}
    minutes=${base:9:2}
    seconds=${base:11:2}
    echo -n $year-$week-$day $hours:$minutes:$seconds $'\f'

    # Replace all '\n' with '\f' to preserve entropy
    cat $f | tr '\n' '\f'
    echo
done
