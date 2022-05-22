import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:mpv_dart/mpv_dart.dart';

class JustAudioMPVPlayer extends AudioPlayerPlatform {
  late final MPVPlayer mpv;
  late final Future<void> willBeReady;
  bool isReady = false;
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();
  @override
  get playbackEventMessageStream => _eventController.stream;
  final _dataController = StreamController<PlayerDataMessage>.broadcast();
  @override
  get playerDataMessageStream => _dataController.stream;

  Future<void> update({Duration? updatePosition, Duration? bufferedPosition, Duration? duration, IcyMetadataMessage? icyMetadata, int? currentIndex}) async {
    _eventController.add(PlaybackEventMessage(
      processingState: (await mpv.getDuration().onError((_,__) => 0) == 0) ? ProcessingStateMessage.idle
      : (await mpv.getProperty("seeking")) ? ProcessingStateMessage.loading
      : ProcessingStateMessage.ready,
      updateTime: DateTime.now(),
      updatePosition: updatePosition ?? Duration(milliseconds: (await mpv.getTimePosition().onError((_,__) => 0) * 1000).truncate()),
      bufferedPosition: bufferedPosition ?? Duration(milliseconds: (await mpv.getDuration().onError((_,__) => 0) * 1000).truncate()),
      duration: duration ?? Duration(milliseconds: (await mpv.getDuration().onError((_,__) => 0) * 1000).truncate()),
      icyMetadata: icyMetadata,
      currentIndex: currentIndex ?? await mpv.getPlaylistPosition().onError((_,__) => 0).then((value) => value < 0 ? 0 : value),
      androidAudioSessionId: null
    ));
  }

  JustAudioMPVPlayer({required String id}) : super(id) {
    final completer = Completer();
    willBeReady = completer.future;
    mpv = MPVPlayer(
      audioOnly: true,
      timeUpdate: 1,
      socketURI: Platform.isWindows ? '\\\\.\\pipe\\mpvserver-$id' : '/tmp/MPV_Dart-$id.sock',
      mpvArgs: ["--audio-buffer=1", "--idle=yes"]
    );
    // unawaited(mpv.start(mpv_args: mpv.mpvArgs).then((_) {
    mpv.on(MPVEvents.status, null, (ev, _) async {
      await update();
    });
    mpv.on(MPVEvents.paused, null, (ev, _) async {
      _dataController.add(PlayerDataMessage(playing: false));
    });
    mpv.start().then(((value) {
      if (!completer.isCompleted) completer.complete();
      isReady = true;
      if (kDebugMode) {
        print("[just_audio_mpv] MPV started");
      }
    }));
    mpv.on(MPVEvents.resumed, null, (ev, _) async {
      _dataController.add(PlayerDataMessage(playing: true));
    });
    mpv.on(MPVEvents.started, null, (ev, _) async {
      _dataController.add(PlayerDataMessage(playing: true));
    });
    mpv.on(MPVEvents.quit, null, (ev, _) async {
      if (kDebugMode) {
        print("[just_audio_mpv] MPV exited");
      }
    });
    mpv.on(MPVEvents.timeposition, null, (ev, _) async {
      final _duration = await mpv.getDuration();
      final _bufferedTo = await mpv.getProperty("demuxer-cache-time");
      if (kDebugMode) {
        print(ev.eventData);
        print(_duration);
        print(_bufferedTo);
      }
      await update(
        updatePosition: Duration(milliseconds: ((ev.eventData as double) * 1000).truncate()),
        bufferedPosition: (_bufferedTo??-1) < 0 ? null : Duration(milliseconds: (_bufferedTo * 1000).truncate()),
        duration: _duration < 0 ? null : Duration(milliseconds: (_duration * 1000).truncate())
      );
    });
  }

  release() async {
    if (kDebugMode) {
      print("[just_audio_mpv] Quitting at request");
    }
    await _eventController.close();
    await _dataController.close();
    await mpv.quit();
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    if (kDebugMode) {
      print("[just_audio_mpv] Starting to load...");
      print(request.audioSourceMessage.toMap());
    }
    if (request.audioSourceMessage is ClippingAudioSourceMessage) {
      await mpv.load((request.audioSourceMessage as ClippingAudioSourceMessage).child.uri, options: [
        if ((request.audioSourceMessage as ClippingAudioSourceMessage).start != null) "start=.${(request.audioSourceMessage as ClippingAudioSourceMessage).start!.inMilliseconds}",
        if ((request.audioSourceMessage as ClippingAudioSourceMessage).end != null) "end=.${(request.audioSourceMessage as ClippingAudioSourceMessage).end!.inMilliseconds}",
      ]);
    } else if (request.audioSourceMessage is UriAudioSourceMessage) {
      await mpv.load((request.audioSourceMessage as UriAudioSourceMessage).uri);
    } else if (request.audioSourceMessage is IndexedAudioSourceMessage) {
      await mpv.clearPlaylist();
      for (final message in (request.audioSourceMessage as ConcatenatingAudioSourceMessage).children) {
        if (request.audioSourceMessage is ClippingAudioSourceMessage) {
          await mpv.load((message as ClippingAudioSourceMessage).child.uri, options: [
            if (message.start != null) "start=.${message.start!.inMilliseconds}",
            if (message.end != null) "end=.${message.end!.inMilliseconds}",
          ], mode: LoadMode.append);
        } else if (message is UriAudioSourceMessage) {
          await mpv.load(message.uri, mode: LoadMode.append);
        } else if (message is IndexedAudioSourceMessage) {
          throw UnsupportedError("nested ${message.runtimeType.toString()} is not supported");
        } else if (message is SilenceAudioSourceMessage) {
          await mpv.load("av://lavfi:anullsrc=d=${message.duration.inMilliseconds}ms", mode: LoadMode.append);
        } else {
          throw UnsupportedError("${message.runtimeType.toString()} is not supported");
        }
      }
      if (request.initialIndex != null) await mpv.setProperty("playlist-start", request.initialIndex);
      if (request.initialPosition != null) await mpv.setProperty("start", request.initialPosition!.inMilliseconds / 1000);
    } else if (request.audioSourceMessage is SilenceAudioSourceMessage) {
      await mpv.load("av://lavfi:anullsrc=d=${(request.audioSourceMessage as SilenceAudioSourceMessage).duration.inMilliseconds}ms", mode: LoadMode.append);
    } else {
      throw UnsupportedError("${request.audioSourceMessage.runtimeType.toString()} is not supported");
    }
    await update();
    return LoadResponse(duration: const Duration(days: 365));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    await mpv.play();
    return PlayResponse();
  }
  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    await mpv.pause();
    return PauseResponse();
  }
  // Future<void> next(dynamic request) async {
  //   await mpv.next();
  // }
  // Future<void> previous(dynamic request) async {
  //   await mpv.prev();
  // }
  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    if (request.index != null) await mpv.command("playlist-play-index", [request.index!.toString()]);
    if (request.position != null) await mpv.seek(request.position!.inMilliseconds / 1000);
    return SeekResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    if (request.volume > 1.3) return SetVolumeResponse();
    await mpv.volume(request.volume * 100);
    return SetVolumeResponse();
  }
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    await mpv.speed(request.speed);
    return SetSpeedResponse();
  }
  // @override
  // Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
  //   await mpv.s(request.pitch * 100);
  //   return SetPitchResponse();
  // }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    if (request.loopMode == LoopModeMessage.all) {
      await mpv.loop('no');
      await mpv.loopPlaylist('inf');
    } else if (request.loopMode == LoopModeMessage.one) {
      await mpv.loop('inf');
      await mpv.loopPlaylist('no');
    } else {
      await mpv.loop('no');
      await mpv.loopPlaylist('no');
    }
    return SetLoopModeResponse();
  }
  @override
  Future<SetShuffleModeResponse> setShuffleMode(SetShuffleModeRequest request) async {
    if (request.shuffleMode == ShuffleModeMessage.all) {
      await mpv.shuffle();
    } else {
      await mpv.unshuffle();
    }
    return SetShuffleModeResponse();
  }


}