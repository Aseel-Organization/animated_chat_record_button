import 'dart:developer';
import 'dart:io';

import 'package:animated_chat_record_button/animations.dart';
import 'package:animated_chat_record_button/audio_handlers.dart';
import 'package:animated_chat_record_button/custom_text_form.dart';
import 'package:animated_chat_record_button/file_handle.dart';
import 'package:animated_chat_record_button/recoding_container.dart';
import 'package:animated_chat_record_button/secondary_recording_container.dart';
import 'package:animated_chat_record_button/slide_animation.dart';
import 'package:flutter/material.dart';

/// Configuration class for styling the record button
class RecordButtonConfig {
  final double? slideUpContainerHeight;
  final Color? slideUpContainerColor;
  final Color? firstRecordButtonColor;
  final Color? secondRecordButtonColor;
  final Color? textFormFieldBoxFillColor;
  final String? textFormFieldHint;
  final TextStyle? textFormFieldStyle;
  final TextStyle? textFormFieldHintStyle;

  final EdgeInsetsGeometry containersPadding;
  final Icon firstRecordingButtonIcon;
  final Icon secondRecordingButtonIcon;
  final double recordButtonSize;
  final double recordButtonScaleVal;
  final double slideUpContainerWidth;

  const RecordButtonConfig({
    this.slideUpContainerHeight,
    this.slideUpContainerColor,
    this.firstRecordButtonColor,
    this.secondRecordButtonColor,
    this.textFormFieldBoxFillColor,
    this.textFormFieldHint,
    this.textFormFieldStyle,
    this.textFormFieldHintStyle,
    this.containersPadding = const EdgeInsets.only(left: 8),
    this.firstRecordingButtonIcon = const Icon(
      Icons.mic,
      color: Colors.white,
    ),
    this.secondRecordingButtonIcon = const Icon(
      Icons.send_rounded,
      color: Colors.white,
    ),
    this.recordButtonSize = 40,
    this.recordButtonScaleVal = 2.5,
    this.slideUpContainerWidth = 50,
  }) : assert(recordButtonScaleVal >= 1.5 && recordButtonScaleVal <= 2.5,
            'recordButtonScaleVal must be between 1.5 and 2.5 for better experience');
}

/// State management for record button animations
class RecordButtonState {
  final bool isReachedCancel;
  final bool isReachedLock;
  final bool isMoving;
  final bool isMovingVertical;
  final bool isHorizontalMoving;
  final double roundedOpacity;
  final double roundedContainerHorizontal;
  final double onHorizontalButtonScale;
  final double verticalScale;
  final double roundedContainerVal;
  final double xAxisVal;
  final double dyOffsetVerticalUpdate;

  const RecordButtonState({
    required this.isReachedCancel,
    required this.isReachedLock,
    required this.isMoving,
    required this.isMovingVertical,
    required this.isHorizontalMoving,
    required this.roundedOpacity,
    required this.roundedContainerHorizontal,
    required this.onHorizontalButtonScale,
    required this.verticalScale,
    required this.roundedContainerVal,
    required this.xAxisVal,
    required this.dyOffsetVerticalUpdate,
  });
}

class AnimatedChatRecordButton extends StatefulWidget {
  /// Configuration for the record button , text field, and slide-up container
  final RecordButtonConfig config;

  /// Configuration for the recording container , waveforms , and icons
  final RecordingContainerConfig? recordingContainerConfig;

  /// TextEditingController to manage the text input field
  final TextEditingController? textEditingController;

  /// the path where the recording will be saved ex : /storage/emulated/0/Android/data/com.example.animated_chat_record_button_example/files/recording_1753372209083.aac

  final String? recordingOutputPath;

  /// Callback when recording ends, providing the file path of the recording
  final Function(File? filePath) onRecordingEnd;

  /// Callback when the send button is pressed, providing the text from the input field
  final Function(String text) onSend;

  /// Callback when the recording starts, providing a boolean indicating if it started successfully
  final Function(bool doesStartRecording)? onStartRecording;

  /// Callback when the recording is locked, providing a boolean indicating if it was locked successfully
  final Function(bool doesLocked)? onLockedRecording;

  /// Creates an instance of [AnimatedChatRecordButton]
  const AnimatedChatRecordButton({
    super.key,
    this.config = const RecordButtonConfig(),
    this.textEditingController,
    this.recordingOutputPath,
    required this.onRecordingEnd,
    required this.onSend,
    this.recordingContainerConfig,
    this.onStartRecording,
    this.onLockedRecording,
  });

  /// Creates an instance of [AnimatedChatRecordButton] with a recording output path
  @override
  State<AnimatedChatRecordButton> createState() =>
      _AnimatedChatRecordButtonState();
}

class _AnimatedChatRecordButtonState extends State<AnimatedChatRecordButton>
    with TickerProviderStateMixin {
  late AnimationGlop _animationController;
  late AudioHandlers _audioHandlers;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupTextListener();
  }

  /// Sets up a listener for the text field to update the state when text changes
  void _setupTextListener() {
    if (widget.textEditingController != null) {
      // Set initial state
      _hasText = widget.textEditingController!.text.isNotEmpty;

      // Add listener
      widget.textEditingController!.addListener(_onTextChanged);
    }
  }

  /// Callback for text changes in the text field
  void _onTextChanged() {
    final hasTextNow = widget.textEditingController!.text.isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() {
        _hasText = hasTextNow;
      });
      log('Text field ${_hasText ? 'has text' : 'is empty'}');
    }
  }

  /// Initializes the animation controller and audio handlers
  void _initializeControllers() {
    _animationController = AnimationGlop(context);
    _audioHandlers = AudioHandlers();

    _animationController.initialize(
      roundedContainerHightt: widget.config.slideUpContainerHeight ?? 150,
      recordButtonSizeInit: widget.config.recordButtonSize,
      recordButtonScaleInit: widget.config.recordButtonScaleVal,
      roundedContainerWidhdInit: widget.config.slideUpContainerWidth,
    );

    _animationController.requestPermissions();
  }

  @override
  void dispose() {
    // Remove text listener before disposing
    if (widget.textEditingController != null) {
      widget.textEditingController!.removeListener(_onTextChanged);
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _stopRecording() async {
    final result = await _animationController.audioHandlers.stopRecording();
    widget.onRecordingEnd(result);
  }

  void _handleRecordingStart() {
    _animationController.startAnimation();
    _animationController.startTimerRecord();
    _animationController.startMicFade();
    _animationController.audioHandlers.startRecording(
      filePath: widget.recordingOutputPath,
    );
    widget.onStartRecording?.call(true);
  }

  void _handleRecordingEnd(bool isLocked, bool isCanceled) {
    _animationController.reverseAnimation();

    if (!isLocked && !isCanceled) {
      _animationController.stopTimer();
      _stopRecording();
      _animationController.stopMicFade();
      widget.onLockedRecording?.call(isLocked);
      widget.onStartRecording?.call(false);
    }
    if (isLocked) {
      widget.onLockedRecording?.call(isLocked);
    }
    if (isCanceled) {
      widget.onLockedRecording?.call(isLocked);

      _animationController.stopMicFade();
      _animationController.stopTimer();
      deleteOnCancel(_animationController.audioHandlers);
    }
  }

  RecordButtonState _extractState() {
    return RecordButtonState(
      isReachedCancel: _animationController.isReachedCancel.value,
      isReachedLock: _animationController.isReachedLock.value,
      isMoving: _animationController.isMoving.value,
      isMovingVertical: _animationController.isMovingVertical.value,
      isHorizontalMoving: _animationController.isHorizontalMoving.value,
      roundedOpacity: _animationController.roundedOpacity.value,
      roundedContainerHorizontal:
          _animationController.roundedContainerHorizontal.value,
      onHorizontalButtonScale:
          _animationController.onHorizontalButtonScale.value,
      verticalScale: _animationController.verticalScale.value,
      roundedContainerVal: _animationController.roundedContainerVal.value,
      xAxisVal: _animationController.xAxisVal.value,
      dyOffsetVerticalUpdate: _animationController.dyOffsetVerticalUpdate.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return _buildAnimatedListeners(screenSize);
  }

  Widget _buildAnimatedListeners(Size screenSize) {
    return ValueListenableBuilder(
      valueListenable: _animationController.isReachedCancel,
      builder: (context, isReachedCancel, child) => ValueListenableBuilder(
        valueListenable: _animationController.roundedOpacity,
        builder: (context, roundedOpacity, child) => ValueListenableBuilder(
          valueListenable: _animationController.roundedContainerHorizontal,
          builder: (context, roundedContainerHorizontal, child) =>
              ValueListenableBuilder(
            valueListenable: _animationController.isHorizontalMoving,
            builder: (context, isHorizontalMoving, child) =>
                ValueListenableBuilder(
              valueListenable: _animationController.onHorizontalButtonScale,
              builder: (context, onHorizontalButtonScale, child) =>
                  ValueListenableBuilder(
                valueListenable: _animationController.isReachedLock,
                builder: (context, isReachedLock, child) =>
                    ValueListenableBuilder(
                  valueListenable: _animationController.verticalScale,
                  builder: (context, verticalScale, child) =>
                      ValueListenableBuilder(
                    valueListenable: _animationController.isMovingVertical,
                    builder: (context, isMovingVertical, child) =>
                        ValueListenableBuilder(
                      valueListenable: _animationController.isMoving,
                      builder: (context, isMoving, child) =>
                          ValueListenableBuilder(
                        valueListenable:
                            _animationController.roundedContainerVal,
                        builder: (context, roundedContainerVal, child) =>
                            ValueListenableBuilder(
                          valueListenable: _animationController.xAxisVal,
                          builder: (context, xAxisVal, child) =>
                              ValueListenableBuilder(
                            valueListenable:
                                _animationController.dyOffsetVerticalUpdate,
                            builder: (context, dyOffsetVerticalUpdate, child) =>
                                AnimatedBuilder(
                              animation: _animationController.scaleAnimation,
                              builder: (context, child) {
                                final state = RecordButtonState(
                                  isReachedCancel: isReachedCancel,
                                  isReachedLock: isReachedLock,
                                  isMoving: isMoving,
                                  isMovingVertical: isMovingVertical,
                                  isHorizontalMoving: isHorizontalMoving,
                                  roundedOpacity: roundedOpacity,
                                  roundedContainerHorizontal:
                                      roundedContainerHorizontal,
                                  onHorizontalButtonScale:
                                      onHorizontalButtonScale,
                                  verticalScale: verticalScale,
                                  roundedContainerVal: roundedContainerVal,
                                  xAxisVal: xAxisVal,
                                  dyOffsetVerticalUpdate:
                                      dyOffsetVerticalUpdate,
                                );

                                return _buildMainContainer(screenSize, state);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContainer(Size screenSize, RecordButtonState state) {
    return SizedBox(
      width: screenSize.width,
      height: screenSize.height * 0.5,
      child: Stack(
        children: [
          _buildBackgroundContainer(screenSize.width, state.xAxisVal),
          if (!state.isReachedLock && !state.isMoving)
            _buildTextField(screenSize.width),
          _buildSlideUpContainer(state),
          if (state.isMoving)
            _buildSlideToCancelContainer(screenSize.width, state.xAxisVal),
          _buildRecordButton(state),
          if (state.isReachedLock) _buildLockedRecordingContainer(),
        ],
      ),
    );
  }

  Widget _buildBackgroundContainer(double width, double xAxisValue) {
    return Positioned(
      bottom: 0,
      height: widget.config.recordButtonSize,
      width: width - (xAxisValue.abs() + widget.config.slideUpContainerWidth),
      child: Padding(
        padding: widget.config.containersPadding,
        child: Container(
          width: width - (widget.config.recordButtonSize + 5),
          height: widget.config.recordButtonSize,
          decoration: BoxDecoration(
            color: widget.config.textFormFieldBoxFillColor ?? Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(double screenWidth) {
    return Positioned(
      bottom: 0,
      width: screenWidth - widget.config.slideUpContainerWidth,
      height: widget.config.recordButtonSize,
      child: Padding(
        padding: widget.config.containersPadding,
        child: CustomTextForm(
          controller: widget.textEditingController,
          boxFillColor: widget.config.textFormFieldBoxFillColor ?? Colors.white,
          hinText: widget.config.textFormFieldHint ?? 'Message',
          hintStyle: widget.config.textFormFieldHintStyle ??
              TextStyle(color: Colors.grey[500], fontSize: 15),
          contentPading:
              const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          border: widget.config.recordButtonSize,
        ),
      ),
    );
  }

  Widget _buildSlideUpContainer(RecordButtonState state) {
    if (!state.isMoving) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController.roundedVerticalContainerAnimationHight,
      builder: (context, child) => AnimatedBuilder(
        animation: _animationController.roundedVerticalContainerAnimation,
        builder: (context, child) {
          final containerHeight = _calculateContainerHeight(state);

          return Positioned(
            width: widget.config.slideUpContainerWidth,
            height: containerHeight,
            bottom: widget.config.recordButtonSize + 15,
            right: 0,
            child: Opacity(
              opacity: state.roundedOpacity,
              child: Transform.translate(
                offset: Offset(
                  0,
                  state.roundedContainerVal * 1.8 +
                      widget.config.recordButtonSize,
                ),
                child: Transform.scale(
                  scale: _animationController
                      .roundedVerticalContainerAnimation.value,
                  child: TopContainerSlider(
                    animationGlop: _animationController,
                    containerColor: widget.config.slideUpContainerColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateContainerHeight(RecordButtonState state) {
    if (state.isHorizontalMoving &&
        state.roundedContainerHorizontal.abs() > 0.6) {
      return (_animationController.roundedContainerHight +
              state.roundedContainerHorizontal)
          .clamp(widget.config.recordButtonSize,
              _animationController.roundedContainerHight);
    }

    if (!state.isMovingVertical &&
        state.roundedContainerVal != _animationController.lockValue) {
      return _animationController.roundedVerticalContainerAnimationHight.value;
    }

    return (_animationController.roundedContainerHight +
            state.roundedContainerVal * 1.2)
        .clamp(widget.config.slideUpContainerWidth,
            _animationController.roundedContainerHight);
  }

  Widget _buildSlideToCancelContainer(double screenWidth, double xAxisValue) {
    return Positioned(
      bottom: 0,
      width: screenWidth -
          (xAxisValue.abs() + widget.config.slideUpContainerWidth),
      height: widget.config.recordButtonSize,
      child: StaggeredSlideIn(
        direction: SlideDirection.end,
        duration: const Duration(milliseconds: 100),
        child: Padding(
          padding: widget.config.containersPadding,
          child: SlideToCancelContainer(
            animationGlop: _animationController,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton(RecordButtonState state) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: SizedBox(
        width: widget.config.slideUpContainerWidth,
        child: Center(
          child: _hasText
              ? InkWell(
                  onTap: () {
                    widget.onSend(widget.textEditingController?.text ?? '');
                    widget.textEditingController?.clear();
                  },
                  child: Container(
                    width: widget.config.recordButtonSize,
                    height: widget.config.recordButtonSize,
                    decoration: BoxDecoration(
                      color:
                          widget.config.firstRecordButtonColor ?? Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: widget.config
                        .secondRecordingButtonIcon, // Mic icon when no text
                  ),
                )
              : GestureDetector(
                  onPanDown: (_) => _handleRecordingStart(),
                  onPanUpdate: state.isReachedLock
                      ? null
                      : (details) {
                          _animationController.onPanUpdate(details);
                        },
                  onPanEnd: (details) {
                    _handleRecordingEnd(
                        state.isReachedLock, state.isReachedCancel);
                    _animationController.onPanEnd(details);
                  },
                  onPanCancel: () {
                    _animationController.reverseAnimation();
                    _handleRecordingEnd(
                        state.isReachedLock, state.isReachedCancel);
                  },
                  child: Opacity(
                    opacity: state.isReachedLock ? 0 : 1,
                    child: Transform.translate(
                      offset:
                          Offset(state.xAxisVal, state.dyOffsetVerticalUpdate),
                      child: Transform.scale(
                        scale: _calculateButtonScale(state),
                        child: Container(
                          width: widget.config.recordButtonSize,
                          height: widget.config.recordButtonSize,
                          decoration: BoxDecoration(
                            color: widget.config.firstRecordButtonColor ??
                                Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: widget.config
                              .firstRecordingButtonIcon, // Mic icon when no text
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  double _calculateButtonScale(RecordButtonState state) {
    if (state.isMovingVertical) {
      return state.verticalScale;
    } else if (state.isHorizontalMoving) {
      return state.onHorizontalButtonScale;
    } else {
      return _animationController.scaleAnimation.value;
    }
  }

  Widget _buildLockedRecordingContainer() {
    return Positioned(
      bottom: 0,
      child: RecordingContainer(
        onStartRecording: (doestStartRecord) =>
            widget.onStartRecording?.call(doestStartRecord),
        onLockedRecording: (doesLocked) =>
            widget.onLockedRecording?.call(doesLocked),
        config: widget.recordingContainerConfig ?? RecordingContainerConfig(),
        onRecordingEnd: widget.onRecordingEnd,
        animationGlop: _animationController,
      ),
    );
  }
}
