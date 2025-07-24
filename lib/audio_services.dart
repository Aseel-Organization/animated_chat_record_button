import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/material.dart';

class AudioPlayersService {
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
// Change this to store the index instead of the file path
  final ValueNotifier<int?> currentlyPlayingIndexNotifier =
      ValueNotifier<int?>(null);

  void listen() {
    player.onPlayerStateChanged.listen((state) {
      // isPlaying.value = state == PlayerState.playing;

      if (state == PlayerState.stopped ||
          state == PlayerState.paused ||
          state == PlayerState.completed) {}
    });

    player.onDurationChanged.listen((newDuration) {
      totalDuration.value =
          newDuration; // This still updates the service's totalDuration
    });

    player.onPositionChanged.listen((newPosition) {
      currentPosition.value = newPosition;
    });
  }

  Future<void> setAudioPath(
    String path,
  ) async {
    await player.setSource(DeviceFileSource(path));
  }

  Future<void> initializeAudioPLayer() async {
    // This is already done by setSource, but good to keep if you have other init logic.
  }

  Future<void> startPlayingAudio() async {
    isPlaying.value = true;

    await player.resume();
  }

  Future<void> pausePlayingAudio() async {
    isPlaying.value = false;

    await player.pause();
  }

  Future<void> setPlayBackAudio(double rate) async {
    await player.setPlaybackRate(rate);
  }

  Future<void> seekTo(Duration position) async {
    try {
      await player.seek(position).timeout(Duration(seconds: 10));
    } catch (e) {
      // Handle timeout or other errors
      print('Seek failed: $e');
    }
  }

  Future<Duration?> getDurationForFile(String filePath) async {
    final tempPlayer = AudioPlayer();
    try {
      await tempPlayer.setSource(DeviceFileSource(filePath));
      final duration = await tempPlayer.getDuration();
      return duration;
    } catch (e) {
      print('Error getting duration for $filePath: $e');
      return null;
    } finally {
      await tempPlayer.dispose();
    }
  }
}
