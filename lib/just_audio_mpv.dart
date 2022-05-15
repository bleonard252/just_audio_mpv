import 'package:flutter/services.dart';
import 'package:just_audio_mpv/src/mpv_player.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class JustAudioMpv extends JustAudioPlatform {
  final Map<String, JustAudioMPVPlayer> players = {};

  /// The entrypoint called by the generated plugin registrant.
  static void registerWith() {
    JustAudioPlatform.instance = JustAudioMpv();
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    if (players.containsKey(request.id)) {
      throw PlatformException(
          code: "error",
          message: "Platform player ${request.id} already exists");
    }
    final player = JustAudioMPVPlayer(id: request.id);
    players[request.id] = player;
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    await players[request.id]?.release();
    players.remove(request.id);
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
      DisposeAllPlayersRequest request) async {
    for (var player in players.values) {
      await player.release();
    }
    players.clear();
    return DisposeAllPlayersResponse();
  }
}
