# `just_audio` with MPV
This platform interface allows you to use `just_audio` on Linux with the user's installed MPV.

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

For Fedora:
```
sudo yum install mpv
```

### Build into a Flatpak
To add MPV to a Flatpak build, add these modules to your flatpak-builder manifest:
```yaml
  - name: libass
    # mpv won't build without this
    cleanup:
      - /include
      - /lib/pkgconfig
    config-opts:
      - --disable-static
    sources:
      - type: archive
        url: https://github.com/libass/libass/releases/download/0.15.0/libass-0.15.0.tar.gz
        sha256: 9cbddee5e8c87e43a5fe627a19cd2aa4c36552156eb4edcf6c5a30bd4934fe58
  - name: mpv
    buildsystem: simple
    cleanup:
      - /include
      - /lib/pkgconfig
    build-commands:
      - python3 waf configure --prefix=/app --enable-libmpv-shared --disable-build-date
        --disable-manpage-build --disable-alsa --enable-libarchive
        --disable-lua --disable-javascript --disable-uchardet --disable-drm --disable-dvdnav
      - python3 waf build
      - python3 waf install
    post-install:
      # save screenshots at ~/Pictures/mpv
      - echo "screenshot-directory=~/Pictures/mpv" > /app/etc/mpv/mpv.conf
    sources:
      - type: archive
        url: https://github.com/mpv-player/mpv/archive/v0.35.0.tar.gz
        sha256: dc411c899a64548250c142bf1fa1aa7528f1b4398a24c86b816093999049ec00
      - type: file
        url: https://waf.io/waf-2.0.22
        sha256: 0a09ad26a2cfc69fa26ab871cb558165b60374b5a653ff556a0c6aca63a00df1
        dest-filename: waf
```

For other distributions, you might want to look into https://mpv.io/installation/.

Currently it is not possible to tell `just_audio_mpv` to use an asset-bundled `mpv`.

## Checking for MPV
To check whether MPV is installed, first check if it's going to be used (with `if (Platform.isLinux)`), then check the exit code of the command `which mpv`. If it returns `0`, MPV is present and you can continue. If it returns `1`, MPV is not present. Any other error codes are likely indicative of the `which` command not being present-- good luck getting a Flutter app to run on a machine that doesn't have basic tools like `which`.

```dart
// In a synchronous environment, optimally before the runApp(MyApp()) call and/or with a
// splash/loading screen available:
// (Note: asynchronous is preferred where possible, but `which` is an instant command
// so running it synchronously should not hurt performance.)
if (Platform.isLinux && Process.runSync("which", ["mpv"]).exitCode != 0) {
  // Tell the user somehow that MPV is not installed,
  // point them to this page, and prevent them from
  // trying to play audio.
}
// If you're running in an environment where audio support is considered absent by default,
// you can check for MPV's presence asynchronously like this:
final which = Process.run("which", ["mpv"]);
if (which.exitCode == 0) {
  canPlayAudio = true;
}
```

For Windows the command would be `Get-Command` for PowerShell and `where` for CMD.

## Logging
If you want centralized, controlled, or pretty logging, you can use the below example to tell `just_audio_mpv` to log to wherever you want instead. It logs to console by default, so for most debugging purposes nothing needs to be done.

**Please note:** the `dynamic error` parameter may include non-error information that may be useful in debugging, such as what track it is attempting to load. It is typically null.

```dart
// Map your various log levels to MPV's:
const _logLevelMap = {
  JAMPV_LogLevel.debug: LogLevel.debug,
  JAMPV_LogLevel.info: LogLevel.info,
  JAMPV_LogLevel.warning: LogLevel.warning,
  JAMPV_LogLevel.error: LogLevel.error,
  JAMPV_LogLevel.verbose: LogLevel.verbose,
  JAMPV_LogLevel.none: LogLevel.debug,
};
mpvLog = (dynamic message, {dynamic error, JAMPV_LogLevel level = JAMPV_LogLevel.debug, StackTrace stackTrace}) {
  // Run your logging function of choice here.
  // For example, if using Pinelogger:
  justAudioMpvPinelogger.log(message, severity: _logLevelMap[level]!, error: error, stackTrace: stackTrace);
};
```

## Features

| Feature                        |  Linux |
| ------------------------------ |  :---: |
| read from URL                  |   ✅   |
| read from file                 |   ✅   |
| read from asset                |   ✅   |
| read from byte stream          |        |
| request headers                |        |
| DASH                           |   ✅   |
| HLS                            |   ✅   |
| ICY metadata                   |        |
| buffer status/position         |   ✅   |
| play/pause/seek                |   ✅   |
| set volume/speed               |   ✅   |
| clip audio                     |   ✅   |
| playlists                      |   ✅   |
| looping/shuffling              |   ✅   |
| compose audio                  |        |
| gapless playback               |   ✅   |
| report player errors           |   ✅   |
| handle phonecall interruptions |        |
| buffering/loading options      |        |
| set pitch                      |        |
| skip silence                   |        |
| equalizer                      |   ✅   |
| volume boost                   |   ✅   |