# `just_audio` with MPV
This platform interface allows you to use `just_audio` on Linux (and probably Windows) with the user's installed MPV.

This uses `mpv_dart`, which uses a local socket to communicate with mpv over JSON IPC. mpv takes care of all the file loading, shuffling, looping, pretty much everything.

## Features

| Feature                        | Windows | Linux |
| ------------------------------ | :-----: | :---: |
| read from URL                  |   ✅    |  ✅   |
| read from file                 |   ✅    |  ✅   |
| read from asset                |   ✅    |  ✅   |
| read from byte stream          |         |       |
| request headers                |         |       |
| DASH                           |   ✅    |  ✅   |
| HLS                            |   ✅    |  ✅   |
| ICY metadata                   |         |       |
| buffer status/position         |   ✅    |  ✅   |
| play/pause/seek                |   ✅    |  ✅   |
| set volume/speed               |   ✅    |  ✅   |
| clip audio                     |   ✅    |  ✅   |
| playlists                      |   ✅    |  ✅   |
| looping/shuffling              |   ✅    |  ✅   |
| compose audio                  |         |       |
| gapless playback               |   ✅    |  ✅   |
| report player errors           |   ✅    |  ✅   |
| handle phonecall interruptions |         |       |
| buffering/loading options      |         |       |
| set pitch                      |         |       |
| skip silence                   |         |       |
| equalizer                      |   ✅    |  ✅   |
| volume boost                   |   ✅    |  ✅   |