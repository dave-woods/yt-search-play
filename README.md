# yt-search-play

A utility which uses [rofi](https://github.com/davatorium/rofi), [youtube-dl](https://github.com/ytdl-org/youtube-dl), and [mpv](https://github.com/mpv-player/mpv) to search for and play YouTube videos. Works best when bound to a keypress combination such as within a window manager like [i3](https://github.com/i3/i3).

When the script is run, a rofi window will appear. The user can type to search, or can filter and select from recent searches. If a YouTube URL is part of the search, that video will be opened in MPV, otherwise a new rofi window will be displayed showing a list of videos that match the search terms. The user can then filter and select one of these videos, which will be opened in MPV.

The program can also fetch videos from a specified YouTube account's subscription feed instead.

While this script does not require an API key to run, this does slow down the searching process -- to combat this, relevant results will begin to display immediately and can be selected before all results have appeared, and recent searches will be cached and only refetched after a set amount of time has passed (by default 1 minute).

## Dependencies

Listed versions below have been tested. Newer releases should work fine, but older versions may have problems. Note that the versions located in the standard package managers may be outdated -- see the relevant links above for the most up to date information on installing.

* rofi 1.6.1
* youtube-dl 2021.01.16
* mpv 0.14.0
* jq 1.5.1 (used to parse the data from youtube-dl)
* gawk 4.1.3 (GNU awk, for pretty printing)

## Installation and usage

Make sure to give the script execution permission once it's downloaded. If you download just the script alone, you can run it with the `--generate-config` option to create the default configuration file in the same directory without launching the rest of the program.
##### Method 1
```
git clone https://github.com/dave-woods/yt-search-play.git
cd yt-search-play
chmod +x yt-search-play
```
##### Method 2
```
wget https://raw.githubusercontent.com/dave-woods/yt-search-play/main/yt-search-play
chmod +x yt-search-play
./yt-search-play --generate-config
```

Once you have the file downloaded and executable, you might want to add the script's directory to your PATH variable to make it executable from anywhere without having to specify the full path to it.

### Using the interface

Once launched, a rofi window will appear. You can type in your search query at the prompt, and hit the **Enter key** to begin searching YouTube for matching videos. If you have used the program before, your recent searches will be displayed, and you can use the **arrow keys** to navigate. Hit the **Enter key** to select the highlighted history entry. When you have history entries available, typing will filter the entries -- if what you type doesn't match any entries, a search will be performed instead. If your query matches a history entry, but you want to perform a search instead of selecting the entry, hit **Ctrl + Enter** to override selecting the history entry.

To display just a particular channel's videos, you can use the "@" symbol before the channel's name to find their most recent uploads. For example, typing `@drawfee` will bring up the most recent videos from [Drawfee Show](https://www.youtube.com/c/drawfee). **Note**: this currently only works for channels which have a human-readable channel ID.

#### Accessing subscription feed

In order for the program to be able to access a user's YouTube subscription feed, a Netscape-format `cookies.txt` file must be placed in the data directory (default `.data`) which contains the login credentials. The specific cookies needed can be obtained by logging into YouTube the normal way and then using a browser extension to export the file, such as [EditThisCookie](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg) or [Get cookies.txt](https://chrome.google.com/webstore/detail/get-cookiestxt/bgaddhkoddajcdgocldbbfleckgcbcid). Note that the cookie file *must* be in **Mozilla/Netscape format** and the first line of the cookies file must be either `# HTTP Cookie File` or `# Netscape HTTP Cookie File`. See [here](https://github.com/ytdl-org/youtube-dl/#how-do-i-pass-cookies-to-youtube-dl) for more.

Once the cookie file is valid, launching the program with the `--subs` option will bring up the most recent videos from the user's subscription feed.

#### Options

The following options are available:
* `--generate-config`: Generate a default configuration file and exit
* `--clear-history`: Clear the search history and exit
* `--clear-cache`: Clear the cache and exit
* `--subs`: Fetch videos from a YouTube account's subscription feed instead of using a search query
* `--n [num]` *or* `--search-size [num]` : Fetch a maximum of `num` videos
* `--force-no-cache`: Prevent the program from reading from or writing to the cache
* `--force-no-history`: Disable the search history
* `--config [file]`: Use `file` as the configuration file

## Configuration

The default configuration file is `.default.config.json` which is located in the same directory as the script. This file should not be edited, as it will be overwritten when the script executes. Users can override all or part of this default by providing a file called `config.json` in either the same directory as the script or in `~/.config/yt-search-play/`, or by passing the file at runtime.

The options that can currently be configured are:
* `search_size` [int]: The (maximum) number of videos fetched when searching
* `max_history_size` [int]: The maximum number of history entries displayed
* `max_cache_age` [int]: How long in seconds before a cache entry expires
* `data_dir` [string]: The directory where internal data is stored
* `force_no_cache` [bool]: When true, prevent the program from reading from or writing to the cache
* `force_no_history` [bool]: When true, disable the search history functionality
* `subs_mode` [bool]: When true, fetch videos from a YouTube account's subscription feed instead of using a search query
