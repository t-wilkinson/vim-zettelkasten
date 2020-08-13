dir=$1
file=$2
# somehow need non-greedy match but appears to be very difficult.
# vim might work best
# fd . "$dir" | xargs sed -e "s/\[\(.\{-}\)]($file)/\1/g"
