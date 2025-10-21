import 'dart:developer';
import 'dart:async';
import 'dart:io';

import 'package:animated_chat_record_button/animations.dart';
import 'package:animated_chat_record_button/custom_text_form.dart';
import 'package:animated_chat_record_button/file_handle.dart';
import 'package:animated_chat_record_button/audio_services.dart';
import 'package:animated_chat_record_button/recoding_container.dart';
import 'package:animated_chat_record_button/secondary_recording_container.dart';
import 'package:animated_chat_record_button/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mic_info/mic_info.dart';

import 'configs/record_button_config.dart';
import 'configs/record_button_state.dart';

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

  /// Callback when microphone is already in use by another app
  final VoidCallback? onMicUsed;

  /// The position from the bottom of the screen where the button and the text form will be placed
  final double bottomPosition;

  /// Callbacks for camera button presses
  final VoidCallback? onPressCamera;

  /// Callbacks for  attachment button presses
  final VoidCallback? onPressAttachment;

  /// Callbacks for  emoji  button presses

  final VoidCallback? onPressEmoji;

  /// Color for the text form buttons
  final Color? textFormButtonsColor;

  /// Optional colors for the arrow
  final Color arrowColor;

  /// Optional colors for the lock icons animation
  final Color lockColorFirst;

  final Color lockColorSecond;

  final bool showCameraButton;
  final bool showEmojiButton;

  /// Optional maximum duration for a single recording. If provided,
  /// recording will automatically stop once this duration is reached.
  final Duration? maxDuration;

  /// Minimum duration for a recording to be considered valid.
  /// Recordings shorter than this will be discarded. Default: 2 seconds.
  final Duration minDuration;

  /// Whether recording functionality is enabled. When false, users can only type and send text messages.
  /// Default: false.
  final bool recordingEnabled;

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
    this.onMicUsed,
    this.bottomPosition = 5,
    this.onPressCamera,
    this.onPressAttachment,
    this.onPressEmoji,
    this.showCameraButton = false,
    this.showEmojiButton = false,
    this.textFormButtonsColor = const Color.fromARGB(255, 116, 116, 116),
    this.arrowColor = Colors.grey,
    this.lockColorFirst = Colors.grey,
    this.lockColorSecond = Colors.black,
    this.maxDuration,
    this.minDuration = const Duration(seconds: 2),
    this.recordingEnabled = false,
  });

  /// Creates an instance of [AnimatedChatRecordButton] with a recording output path
  @override
  State<AnimatedChatRecordButton> createState() =>
      _AnimatedChatRecordButtonState();
}

class _AnimatedChatRecordButtonState extends State<AnimatedChatRecordButton>
    with TickerProviderStateMixin {
  late AnimationGlop _animationController;
  bool _hasText = false;
  bool _hasAutoStopped = false;
  int _lastRecordingSeconds = 0;
  Timer? _holdToShowLockTimer;
  bool _isRecordingActive = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();

    _initializeControllers();
    _setupTextListener();
    _setupMaxDurationListener();
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

  void _setupMaxDurationListener() {
    if (widget.maxDuration == null) return;
    _animationController.secondsElapsed.addListener(_onSecondsTick);
  }

  void _onSecondsTick() {
    if (widget.maxDuration == null) return;
    if (_hasAutoStopped) return;
    final elapsed = _animationController.secondsElapsed.value;
    if (elapsed >= widget.maxDuration!.inSeconds && elapsed > 0) {
      _hasAutoStopped = true;
      _onMaxDurationReached();
    }
  }

  Future<void> _onMaxDurationReached() async {
    try {
      final elapsed = _animationController.secondsElapsed.value;
      _animationController.reverseAnimation();
      _animationController.stopTimer();
      _animationController.stopMicFade();

      // If locked UI is active, stop visualizer and close it
      if (_animationController.isReachedLock.value) {
        await _animationController.audioHandlers.stopVisualizer();
      }

      final result = await _animationController.audioHandlers.stopRecording();
      _isRecordingActive = false;
      if (elapsed < widget.minDuration.inSeconds) {
        if (result != null) {
          await deleteFile(result);
        }
      } else {
        widget.onRecordingEnd(result);
      }
      widget.onStartRecording?.call(false);

      if (_animationController.isReachedLock.value) {
        // Dismiss locked recording container
        _animationController.amplitudesController = [];
        _animationController.shouldStartVisualizer.value = false;
        _animationController.toggleLock();
        widget.onLockedRecording?.call(false);
      }
    } finally {
      // Reset flag after a brief delay to allow new recordings
      Future.microtask(() => _hasAutoStopped = false);
    }
  }

  /// Callback for text changes in the text field
  void _onTextChanged() {
    final hasTextNow = widget.textEditingController!.text.isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() {
        _hasText = hasTextNow;
      });
    }
  }

  Future requestPermissions() async {
    final PermissionStatus storagePermission =
        await Permission.storage.request();

    if (storagePermission.isGranted) {
      log('Storage permission granted');
    } else if (storagePermission.isDenied) {
      log('Storage permission denied. Requesting again...');
    } else if (storagePermission.isPermanentlyDenied) {
      log('Storage permission permanently denied. Open settings.');
      await openAppSettings();
    }

    // Only request microphone permission if recording is enabled
    if (widget.recordingEnabled) {
      final PermissionStatus mic = await Permission.microphone.request();
      if (mic.isGranted) {
        log('mic permission granted');
      }
    }
  }

  /// Initializes the animation controller and audio handlers
  void _initializeControllers() {
    _animationController = AnimationGlop(context);

    _animationController.initialize(
      lockColorFirst: widget.lockColorFirst,
      lockColorSecond: widget.lockColorSecond,
      roundedContainerHightt: widget.config.slideUpContainerHeight ?? 150,
      recordButtonSizeInit: widget.config.recordButtonSize,
      recordButtonScaleInit: widget.config.recordButtonScaleVal,
      roundedContainerWidhdInit: widget.config.slideUpContainerWidth,
    );
  }

  @override
  void dispose() {
    // Remove text listener before disposing
    if (widget.textEditingController != null) {
      widget.textEditingController!.removeListener(_onTextChanged);
    }
    if (widget.maxDuration != null) {
      _animationController.secondsElapsed.removeListener(_onSecondsTick);
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _stopRecording() async {
    final result = await _animationController.audioHandlers.stopRecording();
    final elapsed = _lastRecordingSeconds;
    _lastRecordingSeconds = 0;
    _isRecordingActive = false;
    final minSecs = widget.minDuration.inSeconds;
    if (elapsed > 0 && elapsed < minSecs) {
      if (result != null) {
        await deleteFile(result);
      }
      return;
    }
    widget.onRecordingEnd(result);
  }

  Future<void> _handleRecordingStart({bool fromTap = false}) async {
    // Check if mic is currently in use, if so notify and abort
    try {
      final activeMics = await MicInfo.getActiveMicrophones();
      if (Platform.isIOS && activeMics.length > 1 || Platform.isAndroid && activeMics.isNotEmpty) {
        widget.onMicUsed?.call();

        _animationController.stopMicFade();
        _animationController.stopTimer();
        deleteOnCancel(_animationController.audioHandlers);
        return;
      }
    } catch (_) {
      // If the check fails, proceed to attempt recording as a fallback
    }

    if (fromTap) {
      // Start without showing lock animated view, but show recording view
      _animationController.isReachedLock.value = true;
      _animationController.isMoving.value = false;
      _animationController.shouldStartVisualizer.value = true;
      _animationController.startTimerRecord();
    } else {
      _animationController.startAnimation();
      _animationController.startTimerRecord();
      _animationController.startMicFade();
    }
    _animationController.audioHandlers.startRecording(
      filePath: widget.recordingOutputPath,
    );
    _isRecordingActive = true;
    widget.onStartRecording?.call(true);
  }

  void _handleRecordingEnd(bool isLocked, bool isCanceled) {
    if (!_isRecordingActive) {
      return;
    }
    _animationController.reverseAnimation();

    if (!isLocked && !isCanceled) {
      _lastRecordingSeconds = _animationController.secondsElapsed.value;
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
      _isRecordingActive = false;
    }
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
                            builder: (
                              context,
                              dyOffsetVerticalUpdate,
                              child,
                            ) =>
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

                                return Stack(
                                  children: [
                                    Positioned(
                                      bottom: widget.bottomPosition,
                                      child: _buildMainContainer(
                                        screenSize,
                                        state,
                                      ),
                                    ),
                                    if (state.isReachedLock)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: _buildLockedRecordingContainer(),
                                      ),
                                  ],
                                );
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
          // if (state.isReachedLock) _buildLockedRecordingContainer(),
        ],
      ),
    );
  }

  Widget _buildBackgroundContainer(double width, double xAxisValue) {
    return Positioned(
      bottom: 0,
      height: widget.config.recordButtonSize,
      width: width - (xAxisValue.abs() + _calculateContainersWidth()),
      child: Padding(
        padding: widget.config.containersPadding,
        child: Container(
          width: width - (widget.config.recordButtonSize + 5),
          height: widget.config.recordButtonSize,
          decoration: BoxDecoration(
            color: widget.config.textFormFieldBoxFillColor ?? Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(double screenWidth) {
    return Positioned(
      bottom: 0,
      child: SizedBox(
        height: widget.config.recordButtonSize,
        width: screenWidth - _calculateContainersWidth(),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              width: screenWidth - _calculateContainersWidth(),
              height: widget.config.recordButtonSize,
              child: Padding(
                padding: widget.config.containersPadding,
                child: CustomTextForm(
                  controller: widget.textEditingController,
                  boxFillColor:
                      widget.config.textFormFieldBoxFillColor ?? Colors.white,
                  hinText: widget.config.textFormFieldHint ?? 'Message',
                  hintStyle: widget.config.textFormFieldHintStyle ??
                      TextStyle(color: Colors.grey[500], fontSize: 15),
                  contentPading: EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: widget.showEmojiButton ? 30 : 10,
                  ),
                  border: 10,
                  focusedBorderColor: widget.config.focusedBorderColor,
                  activeBorderColor: widget.config.activeBorderColor,
                ),
              ),
            ),
            if (widget.showCameraButton)
              Positioned(
                bottom: 0,
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: widget.onPressCamera,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: SizedBox(
                    width: 50,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: widget.textFormButtonsColor,
                      size: 25,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              top: 0,
              right: widget.showCameraButton ? 50 : 5,
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: widget.onPressAttachment,
                child: SizedBox(
                  width: 30,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(
                      Icons.attachment,
                      color: widget.textFormButtonsColor,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showEmojiButton)
              Positioned(
                bottom: 0,
                top: 0,
                // right: 0,
                left: 0,
                child: SizedBox(
                  width: 50,
                  child: IconButton(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: widget.onPressEmoji,
                    icon: Icon(
                      Icons.emoji_emotions_rounded,
                      color: widget.textFormButtonsColor,
                      size: 25,
                    ),
                  ),
                ),
              ),
          ],
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
                    arrowColor: widget.arrowColor,
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

  double _calculateContainersWidth() {
    if (widget.config.slideUpContainerWidth > widget.config.recordButtonSize) {
      return widget.config.slideUpContainerWidth + 5;
    } else if (widget.config.recordButtonSize >
        widget.config.slideUpContainerWidth) {
      return widget.config.recordButtonSize + 5;
    } else if (widget.config.slideUpContainerWidth ==
        widget.config.recordButtonSize) {
      return widget.config.slideUpContainerWidth + 5;
      // ignore: curly_braces_in_flow_control_structures
    } else {
      return widget.config.slideUpContainerWidth + 5;
    }
  }

  double _calculateContainerHeight(RecordButtonState state) {
    if (state.isHorizontalMoving &&
        state.roundedContainerHorizontal.abs() > 0.6) {
      return (_animationController.roundedContainerHight +
              state.roundedContainerHorizontal)
          .clamp(
        widget.config.recordButtonSize,
        _animationController.roundedContainerHight,
      );
    }

    if (!state.isMovingVertical &&
        state.roundedContainerVal != _animationController.lockValue) {
      return _animationController.roundedVerticalContainerAnimationHight.value;
    }

    return (_animationController.roundedContainerHight +
            state.roundedContainerVal * 1.2)
        .clamp(
      widget.config.slideUpContainerWidth,
      _animationController.roundedContainerHight,
    );
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
          child: SlideToCancelContainer(animationGlop: _animationController),
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
          child: _buildSendOrRecordButton(state, _hasText),
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
    return RecordingContainer(
      onStartRecording: (doestStartRecord) =>
          widget.onStartRecording?.call(doestStartRecord),
      onLockedRecording: (doesLocked) =>
          widget.onLockedRecording?.call(doesLocked),
      config: widget.recordingContainerConfig ?? RecordingContainerConfig(),
      onRecordingEnd: (file) async {
        // Validate using actual file duration to avoid timer drift in locked flow
        if (file != null) {
          final audioService = AudioPlayersService();
          final dur = await audioService.getDurationForFile(file.path);
          final secs = dur?.inSeconds ?? 0;
          if (secs < widget.minDuration.inSeconds) {
            await deleteFile(file);
            return;
          }
        }
        widget.onRecordingEnd(file);
      },
      animationGlop: _animationController,
    );
  }

  _buildSendOrRecordButton(RecordButtonState state, bool hasText) {
    return GestureDetector(
      onTapDown: hasText || !widget.recordingEnabled
          ? null
          : (_) {
              // Start a 1s timer to show lock animation + start recording if user holds
              _holdToShowLockTimer?.cancel();
              _holdToShowLockTimer = Timer(const Duration(milliseconds: 100), () async {
                // If user hasn't started moving or locked via tap yet, start hold flow
                if (!_animationController.isMoving.value &&
                    !_animationController.isReachedLock.value) {
                  await _handleRecordingStart();
                }
              });
            },
      onTap: hasText
          ? () {
              widget.onSend(widget.textEditingController?.text ?? '');
              widget.textEditingController?.clear();
            }
          : widget.recordingEnabled
              ? () async {
                  // Cancel pending hold timer; this is a tap
                  _holdToShowLockTimer?.cancel();
                  // Simple tap should start recording without showing lock animation
                  if (!_animationController.isReachedLock.value) {
                    await _handleRecordingStart(fromTap: true);
                  }
                }
              : null,
      onPanStart: hasText || !widget.recordingEnabled
          ? null
          : (_) {
              // Drag started, cancel any pending long-hold timer and start hold recording
              _holdToShowLockTimer?.cancel();
            },
      onPanUpdate: hasText || !widget.recordingEnabled
          ? null
          : state.isReachedLock
              ? null
              : (details) {
                  _animationController.onPanUpdate(details);
                },
      onPanEnd: hasText || !widget.recordingEnabled
          ? null
          : (details) {
              _holdToShowLockTimer?.cancel();
              _handleRecordingEnd(
                state.isReachedLock,
                state.isReachedCancel,
              );
              _animationController.onPanEnd(details);
            },
      onPanCancel: hasText || !widget.recordingEnabled
          ? null
          : () {
              _holdToShowLockTimer?.cancel();
              _animationController.reverseAnimation();
              _handleRecordingEnd(
                state.isReachedLock,
                state.isReachedCancel,
              );
            },
      child: Opacity(
        opacity: state.isReachedLock ? 0 : 1,
        child: Transform.translate(
          offset: Offset(
            state.xAxisVal,
            state.dyOffsetVerticalUpdate,
          ),
          child: Transform.scale(
            scale: _calculateButtonScale(state),
            child: Container(
              width: widget.config.recordButtonSize,
              height: widget.config.recordButtonSize,
              decoration: BoxDecoration(
                  color: widget.config.firstRecordButtonColor ?? Colors.black,
                  borderRadius: BorderRadius.circular(10)),
              child: AnimatedSwitcher(
                duration: const Duration(
                    milliseconds: 200), // Adjust duration as needed
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: child.key == ValueKey('icon1')
                      ? Tween<double>(begin: 1, end: 1).animate(anim)
                      : Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: ScaleTransition(scale: anim, child: child),
                ),

                child: !hasText
                    ? (widget.recordingEnabled 
                        ? widget.config.firstRecordingButtonIcon 
                        : widget.config.secondRecordingButtonIcon)
                    : widget.config.secondRecordingButtonIcon,
              ), // Mic icon when no text
            ),
          ),
        ),
      ),
    );
  }
}
