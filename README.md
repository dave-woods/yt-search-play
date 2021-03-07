# yt-search-play

A utility which uses [rofi](https://github.com/davatorium/rofi), [youtube-dl](https://github.com/ytdl-org/youtube-dl), and [mpv](https://github.com/mpv-player/mpv) to search for and play YouTube videos. Works best when bound to a keypress combination such as within a window manager like [i3](https://github.com/i3/i3).

When the script is run, a rofi window will appear. The user can type to search, or can filter and select from recent searches. If a YouTube URL is part of the search, that video will be opened in MPV, otherwise a new rofi window will be displayed showing a list of videos that match the search terms. The user can then filter and select one of these videos, which will be opened in MPV.

The program can also fetch videos from a specified YouTube account's subscription feed or Watch Later playlist instead.

By default, searches are cached for 1 minute, but this can be disabled by using the `--force-no-cache` flag. The cache time can also be extended if desired, and you can set new defaults with a config file. If using the `--thumbnails` option, thumbnail files will only be stored until the cache expires.
## Dependencies

Listed versions below have been tested. Newer releases should work fine, but older versions may have problems. Note that the versions located in the standard package managers may be outdated - see the relevant links above for the most up to date information on installing.

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

Once you have the file downloaded and executable, you might want to add the script's directory to your PATH variable to make it executable from anywhere without having to specify the full path to it. The simplest way is to symlink to your user `bin` directory.

```
ln -s ./yt-search-play ~/bin/yt-search-play
# or
ln -s ./yt-search-play ~/.local/bin/yt-search-play
```
### Using the interface

Once launched, a rofi window will appear. You can type in your search query at the prompt, and hit the **Enter** key to begin searching YouTube for matching videos. If you have used the program before, your recent searches will be displayed, and you can use the **Up** and **Down** arrow keys to navigate, or the **Left** and **Right** arrow keys to move back and forth between pages.

Hit the **Enter key** to select the highlighted history entry. When you have history entries available, typing will filter the entries - if what you type doesn't match any entries, a search will be performed instead. If your query matches a history entry, but you want to perform a search instead of selecting the entry, hit **Ctrl + Enter** to override selecting the history entry. If the program is launched in Subscriptions or Watch Later mode, searching is disabled, and typing at the prompt will just filter videos.

You can press **Alt+1** to add N more videos to the results screen, where N is the search size. Note that due to the way YouTube allows videos to be found, playlists which contain over 100 videos (including the Subscriptions feed) may be problematic, either being slow, or returning no results. This is an upstream issue which youtube-dl may or may not be able to solve in the future.

If cached results are displayed, pressing **Alt+0** will empty the cache and reload fresh results.

To display just a particular channel's videos, you can use the "@" symbol before the channel's name to find their most recent uploads. For example, typing `@drawfee` will bring up the most recent videos from [Drawfee Show](https://www.youtube.com/c/drawfee). **Note**: this currently only works for channels which have a human-readable channel ID.

#### Accessing subscription feed or Watch Later playlist

In order for the program to be able to access a user's YouTube subscription feed or Watch Later playlist, a Netscape-format `cookies.txt` file must be placed in the data directory (default `.data`) which contains the login credentials. The specific cookies needed can be obtained by logging into YouTube the normal way and then using a browser extension to export the file, such as [EditThisCookie](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg) or [Get cookies.txt](https://chrome.google.com/webstore/detail/get-cookiestxt/bgaddhkoddajcdgocldbbfleckgcbcid). Note that the cookie file *must* be in **Mozilla/Netscape format** and the first line of the cookies file must be either `# HTTP Cookie File` or `# Netscape HTTP Cookie File`. See [here](https://github.com/ytdl-org/youtube-dl/#how-do-i-pass-cookies-to-youtube-dl) for more.

Once the cookie file is valid, launching the program with the `--subs` option will bring up the most recent videos from the user's subscription feed. Using the `--watch-later` option will grab videos from the top of the user's Watch Later playlist.

#### Options

The following options are available:
* `--generate-config`: Generate a default configuration file and exit
* `--dump-config`: Print the loaded config file's location and the loaded configuration to the terminal and exit
* `--clear-history`: Clear the search history and exit
* `--clear-cache`: Clear the cache and exit
* `-s` *or* `--subs`: Fetch videos from a YouTube account's subscription feed instead of using a search query
* `-wl` *or* `--watch-later`: Fetch videos from a YouTube account's Watch Later playlist instead of using a search query
* `-n [num]` *or* `--search-size [num]`: Fetch a maximum of `num` videos
* `-r` *or* `--reverse`: Reverse the order of the displayed videos
* `-m` *or* `--mark-watched`: Marks the video as "Watched" on YouTube
* `-t` *or* `--thumbnails`: Fetch and display video thumbnails
* `--use-max-downloads`: This uses youtube-dl's `--max-downloads` flag instead of `--playlist-end` internally (see configuration below)
* `-C` *or* `--force-no-cache`: Prevent the program from reading from or writing to the cache
* `-H` *or* `--force-no-history`: Disable the search history
* `--max-cache-age [num]`: Set the maximum number of seconds before cache entries expire
* `--config [file]`: Use `file` as the configuration file
* `-h` *or* `--help`: Print help and exit

## Known issues and upcoming features

The reverse mode is currently problematic due to the way that youtube-dl mixes the `--reverse` and `--playlist-end` flags. As a result, when the `--reverse` and `--use-max-downloads` options are both set, the `search_size` parameter is ignored initially (though it is obeyed for cached results). This ensures that the end of the playlist is actually shown first, instead of the Nth video. Hopefully youtube-dl will eventually fix this issue, but in the meantime, it's advisable to only use `--reverse` and `--use-max-downloads` together with small playlists. Using them with `--subs`, for example, is likely to cause an error.

In future:
* pass a theme file for rofi

## Configuration

The default configuration file is `.default.config.json` which is located in the same directory as the script. This file should not be edited, as it will be overwritten when the script executes. Users can override all or part of this default by providing a file called `config.json` in either the same directory as the script or in `~/.config/yt-search-play/`, or by passing the file at runtime.

The options that can currently be configured are:
* `search_size` [int]: The (maximum) number of videos fetched when searching.
* `max_history_size` [int]: The maximum number of history entries displayed.
* `max_cache_age` [int]: How long in seconds before a cache entry expires.
* `data_dir` [string]: The directory where internal data is stored.
* `force_no_cache` [bool]: When true, prevent the program from reading from or writing to the cache.
* `force_no_history` [bool]: When true, disable the search history functionality.
* `mark_watched` [bool]: When true, mark videos as "Watched" on YouTube (requires cookiefile).
* `use_thumbnails` [bool]: When true, video thumbnails are fetched and stored in the data directory, and then displayed next to the video title.
* `subs_mode` [bool]: When true, fetch videos from a YouTube account's subscription feed instead of using a search query (requires cookiefile).
* `wl_mode` [bool]: When true, fetch videos from a YouTube account's Watch Later playlist instead of using a search query (requires cookiefile).
* `reverse` [true|false|'wl']: When true, reverse the order of the fetched videos, or only when using `wl_mode` if set to `'wl'`.
* `use_max_downloads` [true|false|'wl']: When true, youtube-dl's `--max-downloads` flag will be used internally instead of `--playlist-end`. This ensures that the end of the playlist is fetched rather then just the first N videos reversed. **NB:** This may cause a performance impact, and will not have a noticeable difference except when used with the `reverse` option set to true. When set to `'wl'`, it will only be true when `wl_mode` is true. Note also that this flag will be deprecated in the future and was only needed initially due to how youtube-dl mixes flags (see [issue here](https://github.com/ytdl-org/youtube-dl/issues/25943) and [related PR](https://github.com/ytdl-org/youtube-dl/pull/24487)).

#### Example config

The following is located at `~/.config/yt-search-play/config.json`. It sets the maximum time before the cache expires to be 10 minutes, sets the data directory to be the same as the config directory, and says that when accessing the user's Watch Later playlist fetch from the bottom of the list instead of the top by setting reverse mode and the use of max downloads to be true when watch later mode is true.

```
{
  "max_cache_age": "600",
  "data_dir": "~/.config/yt-search-play",
  "reverse_mode": "wl",
  "use_max_downloads": "wl",
  "mark_watched": "true",
  "use_thumbnails": "true"
}
```
