# `just_audio` with MPV
This platform interface allows you to use `just_audio` on Linux (and probably Windows) with the user's installed MPV.

This uses `mpv_dart`, which uses a local socket to communicate with mpv over JSON IPC. mpv takes care of all the file loading, shuffling, looping, pretty much everything.

## Installation
**Users** with software that uses `just_audio_mpv` have to install `mpv`. A recent version is *highly recommended*. The `mpv` binary must be present in the PATH. One of the following commands should do this for you:

For Debian and Ubuntu, add [this](https://non-gnu.uvt.nl/) repository and run:
```
sudo apt update
sudo apt install mpv
```

For Arch, get `https://aur.archlinux.org/packages/mpv-git/` via AUR and install it. This can be done with something like:
```
yay -S mpv-git
```

If your app is to be packaged as a Flatpak, you can add `io.mpv.Mpv` as a dependency (don't ask me how, I've never built for it).

For other distributions, you might want to look into https://mpv.io/installation/.

Currently it is not possible to tell `just_audio_mpv` to use a bundled `mpv`.

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