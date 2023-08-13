import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Multiple Player Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatefulBuilder(builder: (context, setState) {
                final player = AudioPlayer();
                var state = player.playerState;
                late final StreamSubscription<PlayerState> stream;
                stream = player.playerStateStream.listen((event) {
                  if (context.mounted) {
                    stream.cancel();
                    return;
                  }
                  setState(() => state = event);
                });
                player.setAudioSource(AudioSource.uri(Uri.parse('https://samplelib.com/lib/preview/mp3/sample-3s.mp3')));
                if (!state.playing && state.processingState == ProcessingState.ready) {
                  return TextButton(onPressed: () => player.play(), child: const Text("Play track 1"));
                } else if (state.playing && state.processingState == ProcessingState.ready) {
                  return TextButton(onPressed: () => player.pause(), child: const Text("Pause track 1"));
                } else {
                  player.stop().then((_) => player.dispose());
                  return const Text("Track 1 done");
                }
              }),
              StatefulBuilder(builder: (context, setState) {
                final player = AudioPlayer();
                var state = player.playerState;
                late final StreamSubscription<PlayerState> stream;
                stream = player.playerStateStream.listen((event) {
                  if (!context.mounted) {
                    player.stop().then((_) => player.dispose());
                    stream.cancel();
                    return;
                  }
                  setState(() => state = event);
                });
                player.setAudioSource(AudioSource.uri(Uri.parse('https://samplelib.com/lib/preview/mp3/sample-9s.mp3')));
                if (!state.playing && state.processingState == ProcessingState.ready) {
                  return TextButton(onPressed: () => player.play(), child: const Text("Play track 2"));
                } else if (state.playing && state.processingState == ProcessingState.ready) {
                  return TextButton(onPressed: () => player.pause(), child: const Text("Pause track 2"));
                } else {
                  player.stop().then((_) => player.dispose());
                  return const Text("Track 2 done");
                }
              }),
            ],
          )
        ),
      ),
    );
  }
}
