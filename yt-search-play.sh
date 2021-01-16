#!/bin/bash

max_history_size=50
historyfile_path="$HOME/.cache/yt-search-play"
historyfile="$historyfile_path/search-history"
cookiefile="$historyfile_path/cookies.txt"
history_size=$(< "$historyfile" wc -l 2>/dev/null || echo 0)
search_N=30
skip_search=false

mkdir -p "$historyfile_path"
touch -a "$historyfile"

if [[ $# -gt 0 ]]
then
	if [[ "$@" =~ --clear-history ]]
	then
		> "$historyfile"
		echo "Cleared search history"
		exit
	elif [[ "$@" =~ --subs ]]
	then
		# check/update the cookie file if there are problems
		selection=$(youtube-dl -i --playlist-end $search_N -j --cookies $cookiefile "https://www.youtube.com/feed/subscriptions" | jq --unbuffered -r '. | "\(.fulltitle) :: \(.uploader) => \(.webpage_url)"' | rofi -dmenu -i -p 'Select Video' -no-show-icons -l 10 -async-pre-read 0 -scroll-method 0 &)
		pkill youtube-dl # found result, stop searching
		url=$(echo "$selection" | awk '{print $NF}')
		skip_search=true
	# elif [[ "$@" =~ --n=(all|[0-9]+) ]]
	# ytsearchall doesn't appear to work currently
	elif [[ "$@" =~ --n=([0-9]+) ]]
	then
		search_N="${BASH_REMATCH[1]}"
	fi
fi

if [[ "$skip_search" = false ]]
then
	search_query=$(tac "$historyfile" | rofi -dmenu -p "Search YouTube" -theme-str 'entry { placeholder: "Enter text or select recent search..."; }' -l $([[ $history_size -lt 10 ]] && echo "$history_size" || echo 10) -scroll-method 0)
	if [[ "$search_query" =~ (https?\:\/\/)?(www\.)?(youtube\.com|youtu\.?be)\/.+$ ]]
	then
		selection="$search_query"
		url="${BASH_REMATCH[0]}"
	elif [[ -n "$search_query" ]]
	then
		sanitised_query=${search_query// /+}
		# selection=$(youtube-dl -j "ytsearch$search_N:$sanitised_query" | jq --unbuffered -r '. | "\(.fulltitle) => \(.webpage_url)"' | rofi -dmenu -i -p 'Select Video' -no-show-icons -l 10 -async-pre-read 0 -scroll-method 0 &)
		# url=$(echo "$selection" | awk '{print $NF}')
		
		temp=$(mktemp /tmp/ytidx.XXXXXXXX)
		mapfile -t selection_array < <(youtube-dl -j "ytsearch$search_N:$sanitised_query" | jq --unbuffered -r '. | "\(.fulltitle) :: \(.uploader) => \(.webpage_url)"'| tee >(stdbuf -o0 awk 'BEGIN{FS=OFS=" => "}{NF--; print}' | rofi -dmenu -i -p 'Select Video' -no-show-icons -l 10 -scroll-method 0 -format i -async-pre-read 0 > "$temp") &);
		pkill youtube-dl # found result, stop searching
		idx=$(cat "$temp")
		rm -f "$temp"
		if [[ -n "$idx" ]]
		then
			selection="${selection_array[$idx]}"
			url=$(echo "$selection" | awk 'BEGIN{FS=OFS=" => "}{print $NF}')
		fi
	else
		exit
	fi
fi

if [[ $history_size -ge $max_history_size ]]
then
	echo $(tail -n $(($max_history_size-1)) "$historyfile") >> "$historyfile"
fi

if [[ -n "$url" ]]
then
	history_entry="$selection"
	pkill mpv
	mpv --really-quiet "$url" &
else
	history_entry="$search_query"
fi

if [[ -n "$history_entry" ]] && [[ "$(tail -n 1 "$historyfile")" != "$history_entry" ]]
then
	echo "$history_entry" >> "$historyfile"
fi
