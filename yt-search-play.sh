#!/bin/bash

## Initialise variables

search_N=30
max_history_size=50
max_cache_age=60
force_no_cache=

data_path="$(dirname $0)/.data"
mkdir -p "$data_path"

historyfile="$data_path/search-history"
cookiefile="$data_path/cookies.txt"
cachefile="$data_path/cache.json"

if [[ ! -f "$historyfile" ]]
then
	touch -a "$historyfile"
fi
history_size=$(< "$historyfile" wc -l 2>/dev/null || echo 0)

## Define functions

clear_history () {
	local success=$(> "$historyfile")
	echo "Cleared search history"
	return $success
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

write_to_cache () {
	if [[ -n "$2" ]]
	then
		if [[ ! -s "$cachefile" ]] || [[ -z "$(cat "$cachefile" | tr -d '[:space:]')" ]]
  	then
  	  echo "[]" > "$cachefile"
  	fi

  	tail --pid="$2" -f /dev/null
  	local cache=$(<"$temp")
  
		jq --arg sel "$1" 'del(.[] | select(.entry == $sel))' "$cachefile" | jq --arg sel "$1" --arg time "$(date +%s)" --arg cc "$cache" '. += [{entry: $sel, time: $time, cache: $cc}]' > "$cachefile.tmp" && mv "$cachefile.tmp" "$cachefile"
  
	fi
	rm -f "$temp"
}

read_from_cache () {
	if [[ -f "$cachefile" ]]
  then
    local entry_found=$(jq --arg sel "$1" '.[] | select(.entry == $sel)' "$cachefile")
    if [[ -n "$entry_found" ]] && [[ $(($(date +%s)-$(echo "$entry_found" | jq -r '.time'))) -lt $max_cache_age ]]
    then
      echo "$entry_found"
    fi
  fi 
}

find_video () {
	local search_url="$1"
	selection=
	url=
	
	[[ -z "$force_no_cache" ]] && local cache_result=$(read_from_cache "$search_url")
	
	if [[ -z "$cache_result" ]]
	then
		temp=$(mktemp /tmp/ysp_idx.XXXXXXXX)
		
		( youtube-dl -i --playlist-end $search_N $include_cookies -j "$search_url" & echo $! >&3 ) 3>pid \
			| jq --unbuffered -r '. | "\(.fulltitle) :: \(.uploader) => \(.webpage_url)"' > "$temp" &
		ytdl_pid=$(<pid)

		idx=$(tail -f "$temp" | stdbuf -o0 awk 'BEGIN{FS=OFS=" => "}{NF--; print}' \
			| rofi -dmenu -i -p 'Select Video' -no-show-icons -l 10 -scroll-method 0 -format i -async-pre-read 0 &)
		
		if [[ -n "$idx" ]]
		then
			selection=$(sed "$((idx+1))q;d" "$temp")
		fi

		[[ -z "$force_no_cache" ]] && write_to_cache "$search_url" $ytdl_pid || (kill $ytdl_pid 2>/dev/null; rm -f "$temp") &
	else
		local cache_value=$(echo "$cache_result" | jq -r '.cache')
    idx=$(echo "$cache_value" | stdbuf -o0 awk 'BEGIN{FS=OFS=" => "}{NF--; print}' \
      | rofi -dmenu -i -p 'Select Video' -no-show-icons -l 10 -scroll-method 0 -format i -async-pre-read 0 &)
    if [[ -n "$idx" ]]
    then
      selection=$(echo "$cache_value" | sed "$((idx+1))q;d")
    fi
	fi

	url=$(echo "$selection" | awk 'BEGIN{FS=OFS=" => "}{print $NF}')
}

process_args () {
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
			do_search
		fi
	else
		do_search
	fi
}

do_search () {
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
}

play_video () {
	if [[ -n "$url" ]]
	then
		history_entry="$selection"
		pkill mpv
		mpv --really-quiet "$url" &
	else
		history_entry="$search_query"
	fi
}

## Main thread

process_args "$@"
play_video
update_history
