import 'dart:io';
import 'dart:math';
import 'package:animated_chat_record_button/audio_services.dart';
import 'package:animated_chat_record_button/recoding_container.dart';
import 'package:animated_chat_record_button/time_format_helpers.dart';
import 'package:flutter/material.dart';

class PlayOnPause extends StatefulWidget {
  const PlayOnPause(
      {super.key,
      required this.audioFile,
      required this.amplitudes,
      this.onAudioServiceReady,
      required this.config});
  final File audioFile;
  final List<double> amplitudes;
  final Function(AudioPlayersService audioService)? onAudioServiceReady;
  final RecordingContainerConfig config;
  @override
  State<PlayOnPause> createState() => _PlayOnPauseState();
}

class _PlayOnPauseState extends State<PlayOnPause> {
  final AudioPlayersService audioPlayerS = AudioPlayersService();
  // final AudioWaveformService _waveformService = AudioWaveformService();
  // final Map<String, List<double>> _cachedWaveforms = {};
  final Map<String, Duration> _cachedDurations = {};
  String? currentlyPlayingFilePath;
  double audioPlayback = 0.5;
  bool isThisFilePlaying = false;
  bool isInit = false;
  Duration position = const Duration(milliseconds: 0);

  @override
  void initState() {
    super.initState();

    initWavePoints();

    audioPlayerS.listen();
    audioPlayerS.player.onPlayerComplete.listen((newPosition) async {
      audioPlayerS.isPlaying.value = false;

      // l.log('finished audioooo');
      currentlyPlayingFilePath = null;
      // audioPlayerS.updateCurrentlyPlayingIndex(null);
      audioPlayerS.currentPosition.value = Duration.zero;
      position = Duration.zero;

      await audioPlayerS.seekTo(Duration.zero);
    });
  }

  void initWavePoints() async {
    // Process waveforms

    // final String? wavPath =
    //     await _waveformService.convertToPcmWav(widget.audioFile.path);
    // if (wavPath != null) {
    //   final List<double>? points =
    //       await _waveformService.getWaveformPoints(wavPath);
    //   if (points != null) {
    //     points.removeAt(0);
    //     _cachedWaveforms[widget.audioFile.path] = points;
    //   }
    //   try {
    //     await File(wavPath).delete();
    //     print('Deleted temporary WAV: $wavPath');
    //   } catch (e) {
    //     print('Error deleting temporary WAV: $e');
    //   }
    // }

    // Get and cache duration for each file
    // This requires a temporary AudioPlayer instance or a method in AudioPlayersService
    // to get duration without playing. Let's add a method to AudioPlayersService.
    final uri = Uri.file(widget.audioFile.path);
    final Duration? duration =
        await audioPlayerS.getDurationForFile(uri.toString());
    if (duration != null) {
      setState(() {
        _cachedDurations[widget.audioFile.path] = duration;
      });
    }
    if (duration == null || duration.inMilliseconds <= 0) {
      // Handle invalid duration case

      return;
    }
    setState(() {
      isInit = true;
      // currentIndex = widget.index;
    });

    widget.onAudioServiceReady?.call(audioPlayerS);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return isInit
        ? ValueListenableBuilder(
            valueListenable: audioPlayerS.isPlaying,
            builder: (context, isPlaying, child) => ValueListenableBuilder(
              valueListenable: audioPlayerS.currentPosition,
              builder: (context, currentPositionValue, child) {
                final Duration? fileDuration =
                    _cachedDurations[widget.audioFile.path];
                Duration displayedDuration = fileDuration ?? Duration.zero;
                double progressValue = 0.0;

                progressValue = currentPositionValue.inMilliseconds /
                    displayedDuration.inMilliseconds;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: EdgeInsets.only(right: 20),
                    width: screenWidth * 0.8,
                    height: 60,
                    decoration: BoxDecoration(
                        color: widget.config.recordWidgetColor,
                        borderRadius: BorderRadius.circular(50)),
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () async {
                              if (isPlaying) {
                                await audioPlayerS.pausePlayingAudio();
                              } else {
                                final uri =
                                    Uri.file(widget.audioFile.path); // Safe way

                                await audioPlayerS.pausePlayingAudio();

                                await audioPlayerS.setAudioPath(
                                  uri.toString(),
                                );

                                await audioPlayerS
                                    .initializeAudioPLayer(); // This should set the source and prepare the player
                                await audioPlayerS.startPlayingAudio();
                              }
                            },
                            icon: isPlaying
                                ? Icon(Icons.pause_rounded,
                                    color: widget.config.playPauseIconColor)
                                : Icon(Icons.play_arrow,
                                    color: widget.config.playPauseIconColor)),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            // Removed spacing: 10.rW if it's not defined
                            children: [
                              if (
                                  // _cachedWaveforms[widget.audioFile.path]!
                                  //   .isNotEmpty
                                  widget.amplitudes.isNotEmpty)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: SizedBox(
                                      height: 50,
                                      // Removed width: double.infinity as LayoutBuilder handles it
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final double availableWidth =
                                              constraints.maxWidth;
                                          const double barWidth =
                                              2.0; // Desired bar width
                                          const double spacing =
                                              1; // Desired spacing
                                          const double totalWidthPerBar =
                                              barWidth + spacing;

                                          // Calculate how many bars can actually fit
                                          final int maxBarsThatFit =
                                              (availableWidth /
                                                      totalWidthPerBar)
                                                  .floor();

                                          // Ensure we don't try to render more points than we have
                                          final int actualBarsToRender = min(
                                              maxBarsThatFit,

                                              // _cachedWaveforms[
                                              //         widget.audioFile.path]!
                                              //     .length

                                              widget.amplitudes.length);

                                          final int progressPointIndex =
                                              (actualBarsToRender *
                                                      progressValue)
                                                  .floor();

                                          return Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceBetween, // Distribute available space if needed
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: List.generate(
                                                    actualBarsToRender, (i) {
                                                  final double amplitude =
                                                      widget.amplitudes[i];
                                                  final double barHeight =
                                                      max(1.0, amplitude * 50);

                                                  final Color? barColor =
                                                      // isThisFilePlaying &&
                                                      i < progressPointIndex
                                                          ? widget.config
                                                              .waveFormPlayedColor
                                                          : widget.config
                                                              .waveFormNonPlayedColor;

                                                  return Container(
                                                    width: barWidth,
                                                    height: barHeight,
                                                    decoration: BoxDecoration(
                                                      color: barColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              1.0),
                                                    ),
                                                  );
                                                }),
                                              ),
                                              Positioned.fill(
                                                child: SliderTheme(
                                                  data: SliderTheme.of(context)
                                                      .copyWith(
                                                    trackHeight:
                                                        0, // no visible track
                                                    overlayShape:
                                                        SliderComponentShape
                                                            .noOverlay,
                                                    activeTrackColor:
                                                        Colors.transparent,
                                                    inactiveTrackColor:
                                                        Colors.transparent,
                                                    thumbShape:
                                                        const RoundSliderThumbShape(
                                                            enabledThumbRadius:
                                                                5),
                                                    trackShape:
                                                        const _NoPaddingTrackShape(),
                                                  ),
                                                  child: Slider(
                                                    value: progressValue.clamp(
                                                        0.0, 1.0),
                                                    onChanged: (value) async {
                                                      final totalDuration =
                                                          fileDuration ??
                                                              Duration.zero;
                                                      position = Duration(
                                                        milliseconds: (totalDuration
                                                                    .inMilliseconds *
                                                                value)
                                                            .round(),
                                                      );
                                                      // progressValue =
                                                      //     value;
                                                      print('changing');
                                                      audioPlayerS
                                                          .currentPosition
                                                          .value = position;
                                                      await audioPlayerS
                                                          .seekTo(position);
                                                    },
                                                    min: 0,
                                                    max: 1,
                                                    thumbColor: Colors.black,
                                                  ),
                                                ),
                                              )
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              Text(
                                formatDuration(isPlaying
                                    ? currentPositionValue
                                    : displayedDuration),
                                style: TextStyle(
                                    color: widget.config.durationColor),
                                // style: context.textTheme.bodyMedium
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : SizedBox.shrink();
  }
}

class _NoPaddingTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _NoPaddingTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset,
      {required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required Offset thumbCenter,
      Offset? secondaryOffset,
      bool? isEnabled,
      bool? isDiscrete,
      required TextDirection textDirection}) {
    // TODO: implement paint
  }
}
