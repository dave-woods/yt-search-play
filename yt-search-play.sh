#!/bin/bash

search_N=30
historyfile_path="$HOME/.cache/yt-search-play"
historyfile="$historyfile_path/search-history"
history_size=$(< "$historyfile" wc -l 2>/dev/null || echo 0)
max_history_size=50
cookiefile="$historyfile_path/cookies.txt"

if [[ ! -f "$historyfile" ]]
then
	mkdir -p "$historyfile_path"
	touch -a "$historyfile"
fi

clear_history () {
	local success=$(> "$historyfile")
	echo "Cleared search history"
	return "$success"
}

update_history () {
	if [[ -n "$history_entry" ]] && [[ "$(tail -n 1 "$historyfile")" != "$history_entry" ]]
	then
		echo "$history_entry" >> "$historyfile"
	fi

	if [[ $history_size -gt $max_history_size ]]
	then
		echo $(tail -n $max_history_size "$historyfile") > "$historyfile"
	fi
}

find_video () {
	temp=$(mktemp /tmp/ysp_idx.XXXXXXXX)
	search_url="$1"
	selection=
	url=
	
	mapfile -t selection_array < <(youtube-dl -i --playlist-end $search_N $include_cookies -j "$search_url" \
		| jq --unbuffered -r '. | "\(.fulltitle) :: \(.uploader) => \(.webpage_url)"' \
		| tee >(stdbuf -o0 awk 'BEGIN{FS=OFS=" => "}{NF--; print}' \
		| rofi -dmenu -i -p 'Select Video' -no-show-icons -l 10 -scroll-method 0 -format i -async-pre-read 0 > "$temp") &);
	
	pkill youtube-dl # found result, stop searching
	
	idx=$(cat "$temp")
	rm -f "$temp"
	
	if [[ -n "$idx" ]]
	then
		selection="${selection_array[$idx]}"
		url=$(echo "$selection" | awk 'BEGIN{FS=OFS=" => "}{print $NF}')
	fi
}

if [[ $# -gt 0 ]]
then
	if [[ "$@" =~ --clear-history ]]
	then
		clear_history
		exit
	elif [[ "$@" =~ --subs ]]
	then
		include_cookies="--cookies $cookiefile" # check/update this file if sub feed breaks
		find_video "https://www.youtube.com/feed/subscriptions"
	elif [[ "$@" =~ --n=(all|[0-9]+) ]]
	then
		search_N="${BASH_REMATCH[1]}"
	fi
fi

if [[ -z "$url" ]]
then
	search_query=$(tac "$historyfile" | rofi -dmenu -p "Search YouTube" -theme-str 'entry { placeholder: "Enter text or select recent search..."; }' -l $([[ $history_size -lt 10 ]] && echo "$history_size" || echo 10) -scroll-method 0)
	if [[ "$search_query" =~ (https?\:\/\/)?(www\.)?(youtube\.com|youtu\.?be)\/.+$ ]]
	then
		selection="$search_query"
		url="${BASH_REMATCH[0]}"
	elif [[ -n "$search_query" ]]
	then
		sanitised_query=${search_query// /+}
		find_video "ytsearch$search_N:$sanitised_query"
	else
		exit
	fi
fi

if [[ -n "$url" ]]
then
	history_entry="$selection"
	pkill mpv
	mpv --really-quiet "$url" &
else
	history_entry="$search_query"
fi

update_history
