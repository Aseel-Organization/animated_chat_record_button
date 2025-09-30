import 'dart:async';
import 'dart:io';
import 'package:animated_chat_record_button/animations.dart';
import 'package:animated_chat_record_button/audio_player_on_pause.dart';
import 'package:animated_chat_record_button/audio_services.dart';
import 'package:animated_chat_record_button/file_handle.dart';
import 'package:animated_chat_record_button/time_format_helpers.dart';
import 'package:flutter/material.dart';

class RecordingContainerConfig {
  final Color recordContainerColor;
  final Color? waveFormNonPlayedColor;
  final Color? waveFormPlayedColor;
  final Color recordWidgetColor;
  final Color playPauseIconColor;
  final List<Icon> icons;
  final Color durationColor;
  final Color? sendButtonColor;

  RecordingContainerConfig({
    this.sendButtonColor = Colors.black,
    this.recordContainerColor = Colors.white,
    this.waveFormNonPlayedColor = const Color(0xFFBDBDBD),
    this.waveFormPlayedColor = const Color(0xFF757575),
    this.recordWidgetColor = const Color(0xFFEEEEEE),
    this.playPauseIconColor = const Color.fromARGB(255, 138, 138, 138),
    this.icons = const [
      Icon(Icons.mic_rounded, color: Colors.red, size: 35),
      Icon(Icons.pause_rounded, color: Colors.red, size: 35),
      Icon(Icons.send, color: Colors.white, size: 30),
      Icon(Icons.delete_rounded, color: Colors.grey, size: 25),
    ],
    this.durationColor = Colors.black,
  });
}

class RecordingContainer extends StatefulWidget {
  const RecordingContainer(
      {super.key,
      required this.animationGlop,
      this.onRecordingEnd,
      required this.config,
      this.onLockedRecording,
      required this.onStartRecording});
  final Function(bool doesLocked)? onLockedRecording;
  final Function(bool doestStartRecord)? onStartRecording;

  final AnimationGlop animationGlop;
  final Function(File? recordPath)? onRecordingEnd;
  final RecordingContainerConfig config;
  @override
  State<RecordingContainer> createState() => _RecordingContainerState();
}

class _RecordingContainerState extends State<RecordingContainer> {
  bool isRecording = true;
  File onPauseFile = File('');
  AudioPlayersService? audioPlayer;
  void toggleRecord() {
    setState(() {
      isRecording = !isRecording;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ValueListenableBuilder(
      valueListenable: widget.animationGlop.secondsElapsed,
      builder: (context, value, child) => Container(
        width: screenWidth,
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.config.recordContainerColor,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Top section: Timer + Visualizer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: screenWidth,
                height: 80, // Fixed height for the container
                child: Row(
                  children: [
                    if (isRecording)
                      Text(
                        formatTime(value),
                        style: TextStyle(
                            color: widget.config.durationColor, fontSize: 16),
                      ),
                    const SizedBox(width: 16), // Add some spacing
                    if (isRecording)
                      Expanded(
                        child: _Visualizer(animationGlop: widget.animationGlop),
                      ),
                    if (!isRecording && onPauseFile.path.isNotEmpty)
                      PlayOnPause(
                        config: widget.config,
                        onAudioServiceReady: (audioService) {
                          setState(() {
                            audioPlayer = audioService;
                          });
                        },
                        audioFile: onPauseFile,
                        amplitudes: widget.animationGlop.amplitudesController,
                      )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8), // Add some spacing

            /// Bottom section: Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                      onTap: () {
                        if (audioPlayer != null) {
                          audioPlayer!.pausePlayingAudio();
                        }
                        deleteOnCancel(widget.animationGlop.audioHandlers);

                        widget.animationGlop.toggleLock();
                        widget.animationGlop.stopTimer();
                        widget.animationGlop.audioHandlers.stopVisualizer();
                        widget.animationGlop.amplitudesController = [];
                        widget.animationGlop.shouldStartVisualizer.value =
                            false;
                        widget.onLockedRecording
                            ?.call(widget.animationGlop.isReachedLock.value);
                      },
                      child: widget.config.icons[3]),
                  InkWell(
                      onTap: () async {
                        if (isRecording) {
                          toggleRecord();
                          final res = await widget.animationGlop.audioHandlers
                              .pauseRecording();
                          if (res != null) {
                            setState(() {
                              onPauseFile = res;
                            });
                          }
                          widget.animationGlop.audioHandlers.stopVisualizer();
                          widget.animationGlop.pauseTimer();
                        } else {
                          toggleRecord();
                          widget.animationGlop.startTimerRecord();
                          widget.animationGlop.audioHandlers.resumeRecording();
                          widget.animationGlop.audioHandlers.startVisualizer();
                          if (audioPlayer != null) {
                            audioPlayer!.pausePlayingAudio();
                          }
                        }
                      },
                      child: isRecording
                          ? widget.config.icons[1]
                          : widget.config.icons[0]),
                  InkWell(
                    onTap: () async {
                      widget.animationGlop.toggleLock();
                      widget.animationGlop.stopTimer();
                      widget.animationGlop.audioHandlers.stopVisualizer();
                      File? res = await widget.animationGlop.audioHandlers
                          .stopRecording();
                      if (widget.onRecordingEnd != null && res != null) {
                        widget.onRecordingEnd!(res);
                      }
                      widget.animationGlop.amplitudesController = [];
                      widget.animationGlop.shouldStartVisualizer.value = false;
                      widget.onLockedRecording
                          ?.call(widget.animationGlop.isReachedLock.value);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: widget.config.sendButtonColor,
                          shape: BoxShape.circle),
                      child: widget.config.icons[2],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Visualizer extends StatefulWidget {
  const _Visualizer({required this.animationGlop});
  final AnimationGlop animationGlop;

  @override
  State<_Visualizer> createState() => __VisualizerState();
}

class __VisualizerState extends State<_Visualizer> {
  List<double> amplitudes = [];
  double _latestAmp = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    widget.animationGlop.audioHandlers.visualizerChannel
        .setMethodCallHandler((call) async {
      if (call.method == "onAmplitude") {
        final amp = (call.arguments as double?) ?? 0.0;
        _latestAmp = amp.clamp(0.0, 1.0);
      }
    });

    widget.animationGlop.audioHandlers.startVisualizer();

    _timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        // Add to both lists unconditionally
        amplitudes.add(_latestAmp);
        widget.animationGlop.amplitudesController.add(_latestAmp);

        // Remove from both lists to maintain the same length
        const maxLength = 60;
        if (amplitudes.length > maxLength) {
          amplitudes.removeAt(0);
        }

        if (widget.animationGlop.amplitudesController.length > maxLength) {
          widget.animationGlop.amplitudesController.removeAt(0);
        }
      });
    });
  }

  void removeGarpage() {
    for (final i in widget.animationGlop.amplitudesController) {
      if (i <= 0) {
        widget.animationGlop.amplitudesController.remove(i);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxBarHeight = constraints.maxHeight / 2;

        return SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth, // Ensure width is also constrained
          child: ValueListenableBuilder(
            valueListenable: widget.animationGlop.shouldStartVisualizer,
            builder: (context, value, child) => value
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: amplitudes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final amp = entry.value;
                      final opacity =
                          (index / amplitudes.length).clamp(0.3, 1.0);
                      final barHeight =
                          (amp * maxBarHeight).clamp(1.0, maxBarHeight);

                      return VerticalVoiceBar(
                        height: barHeight,
                        width: 2,
                        color: Colors.black,
                        opacity: opacity,
                      );
                    }).toList(),
                  )
                : SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class VerticalVoiceBar extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final double opacity;

  const VerticalVoiceBar({
    super.key,
    required this.height,
    this.width = 4,
    this.color = Colors.grey,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // duration: Duration(milliseconds: 300),
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            // duration: Duration(milliseconds: 300),
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
          Container(
            // duration: Duration(milliseconds: 300),
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }
}
