import 'dart:async';
import 'dart:developer';

import 'package:animated_chat_record_button/audio_handlers.dart';
import 'package:animated_chat_record_button/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class TopContainerSlider extends StatefulWidget {
  const TopContainerSlider(
      {super.key, required this.animationGlop, this.containerColor});

  final AnimationGlop animationGlop;
  final Color? containerColor;

  @override
  State<TopContainerSlider> createState() => _TopContainerSliderState();
}

class _TopContainerSliderState extends State<TopContainerSlider> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.animationGlop.colorAnimation,
        widget.animationGlop.slideUpArrowAnimation,
        widget.animationGlop.shackleAnimation
      ]),
      builder: (context, _) {
        return Container(
          width: 50,
          height: 300,
          decoration: BoxDecoration(
            color: widget.containerColor ?? Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          child: StaggeredSlideIn(
            direction: SlideDirection.bottom,
            child: Stack(
              children: [
                _buildLockShackle(widget.animationGlop.colorAnimation.value!),
                _buildLockBody(widget.animationGlop.colorAnimation.value!),
                _buildArrowIcon(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockShackle(Color color) {
    return ValueListenableBuilder(
      valueListenable: widget.animationGlop.isMovingVertical,
      builder: (context, isMovingVertical, child) => ValueListenableBuilder(
        valueListenable: widget.animationGlop.isReachedLock,
        builder: (context, isMovingVert, _) {
          return ValueListenableBuilder(
            valueListenable: widget.animationGlop.shackleLock,
            builder: (context, vValue, _) {
              return Positioned(
                left: 0,
                right: 0,
                top: isMovingVertical
                    ? ((widget.animationGlop.roundedContainerWidth * 0.3) *
                                0.6 +
                            vValue)
                        .clamp(
                            (widget.animationGlop.roundedContainerWidth * 0.3) *
                                0.2,
                            (widget.animationGlop.roundedContainerWidth * 0.3))
                    : isMovingVert
                        ? (widget.animationGlop.roundedContainerWidth * 0.3)
                        : widget.animationGlop.shackleAnimation.value,

                // (widget.animationGlop.recordButtonSize * 0.4) * 0.2,

                child: CustomPaint(
                  size: Size(widget.animationGlop.recordButtonSize,
                      widget.animationGlop.roundedContainerHight),
                  painter: InvertedUPainter(color: color),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArrowIcon() {
    return Positioned(
      left: 0,
      right: 0,
      top: ((widget.animationGlop.roundedContainerHight - 5) * 0.65) -
          widget.animationGlop.roundedContainerWidth * 0.5 +
          widget.animationGlop.slideUpArrowAnimation.value,
      child: ValueListenableBuilder(
        valueListenable: widget.animationGlop.arrowOpacity,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLockBody(Color color) {
    return Positioned(
        // all roundedContainer was recordButtonSize
        // left: widget.animationGlop.roundedContainerWidth * 0.3,
        // // // bottom: 0,
        // right: widget.animationGlop.roundedContainerWidth * 0.3,
        top: (widget.animationGlop.roundedContainerWidth * 0.5) -
            (widget.animationGlop.roundedContainerWidth * 0.2) * 0.5,
        child: Padding(
          padding: EdgeInsets.only(
              left: (widget.animationGlop.roundedContainerWidth * 0.5) -
                  (widget.animationGlop.roundedContainerWidth * 0.3) * 0.5),
          child: Container(
            height: widget.animationGlop.roundedContainerWidth * 0.3,
            width: widget.animationGlop.roundedContainerWidth * 0.3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(5)),
          ),
        ));
  }
}

class InvertedUPainter extends CustomPainter {
  final Color color;

  InvertedUPainter({super.repaint, required this.color});
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path();

    final widthFactor = 0.4;
    final heightFactor = 0.03;
    final initialHight = 0.09;
    final radiusFctor = 0.1;
    path.moveTo(size.width * widthFactor, size.height * initialHight);
    path.lineTo(size.width * widthFactor, size.height * heightFactor);
    // path.moveTo(size.width * 0.25, size.height * 0.11);
    path.arcToPoint(
      Offset(
          size.width - (size.width * widthFactor), size.height * heightFactor),
      clockwise: true,
      radius: Radius.circular(size.width * radiusFctor),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class AnimationGlop extends State<StatefulWidget>
    with TickerProviderStateMixin {
  AnimationGlop(this.context) {
    // double screenHeight = MediaQuery.of(context).size.height;
    // double screenWidth = MediaQuery.of(context).size.width;
  }

  @override
  final BuildContext context;

  late AnimationController _animationController;
  late AnimationController _roundedVerticalContainerController;
  late AnimationController _roundedVerticalContainerControllerHight;

  late Animation<double> _scaleAnimation;
  late Animation<double> _roundedVerticalContainerAnimation;
  late Animation<double> _roundedVerticalContainerAnimationHight;
  late Animation<double> _slideUpParIconArrowUpAnimation;

  late AnimationController _slideUpParIconArrowUpAnimationController;
  late AnimationController colorController;
  late Animation<Color?> colorAnimation;

  late AnimationController micFadeController;
  late Animation<double> micFadeAnimation;
  late AnimationController shackleAnimationController;
  late Animation<double> shackleAnimation;

  Offset initialOffset = Offset(0, 0);
  ValueNotifier<double> dyOffsetVerticalUpdate = ValueNotifier<double>(0);
  ValueNotifier<double> roundedContainerVal = ValueNotifier<double>(0);
  ValueNotifier<double> roundedContainerHorizontal = ValueNotifier<double>(0);

  ValueNotifier<double> verticalScale = ValueNotifier<double>(1.0);

  ValueNotifier<bool> isMoving = ValueNotifier<bool>(false);
  ValueNotifier<bool> isMovingVertical = ValueNotifier<bool>(false);

  ValueNotifier<bool> isReachedLock = ValueNotifier<bool>(false);
  ValueNotifier<bool> isReachedCancel = ValueNotifier<bool>(false);
  ValueNotifier<bool> isHorizontalMoving = ValueNotifier<bool>(false);
  ValueNotifier<double> onHorizontalButtonScale = ValueNotifier<double>(1.9);
  ValueNotifier<double> roundedOpacity = ValueNotifier<double>(1.0);
  ValueNotifier<double> shackleLock = ValueNotifier<double>(0.0);
  final ValueNotifier<double> xAxisVal = ValueNotifier(0.0);
  ValueNotifier<int> secondsElapsed = ValueNotifier<int>(0);
  ValueNotifier<bool> shouldStartVisualizer = ValueNotifier<bool>(false);
  ValueNotifier<double> arrowOpacity = ValueNotifier(0.0);

  Vibration? vipration;
  Timer? recordTimer;
  double roundedContainerHight = 170;
  double lockValue = 0;
  double roundedContainerWidth = 55;
  String currentDirection = 'none';
  AudioHandlers audioHandlers = AudioHandlers();
  double recordButtonSize = 0;
  double recordButtonScale = 1.9;
  bool _permissionsGranted = false;
  bool _permissionCheckInProgress = false;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<double> get roundedVerticalContainerAnimationHight =>
      _roundedVerticalContainerAnimationHight;
  Animation<double> get roundedVerticalContainerAnimation =>
      _roundedVerticalContainerAnimation;
  VoidCallback get startAnimation => _startAnimation;
  VoidCallback get reverseAnimation => _reverseAnimation;
  Animation<double> get slideUpArrowAnimation =>
      _slideUpParIconArrowUpAnimation;
  List<double> amplitudesController = [];
// Position trackers

  void initialize(
      {double roundedContainerHightt = 170,
      required double recordButtonSizeInit,
      double recordButtonScaleInit = 1.9,
      double roundedContainerWidhdInit = 55}) {
    roundedContainerHight = roundedContainerHightt;
    recordButtonScale = recordButtonScaleInit;
    roundedContainerWidth = roundedContainerWidhdInit;

    onHorizontalButtonScale.value = recordButtonScale;

    recordButtonSize = recordButtonSizeInit;
    lockValue = -(roundedContainerHightt - 50).toDouble();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 350),
      vsync: this,
    );
    _roundedVerticalContainerController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _slideUpParIconArrowUpAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _roundedVerticalContainerControllerHight = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );

    micFadeController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    shackleAnimationController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );

    shackleAnimation = Tween<double>(
            begin: (roundedContainerWidth * 0.3),
            end: (roundedContainerWidth * 0.3) * 0.6)
        .animate(CurvedAnimation(
      parent: shackleAnimationController,
      curve: Curves.easeInOut,
    ));
    micFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: micFadeController, curve: Curves.easeInCubic));

    _roundedVerticalContainerAnimationHight = Tween<double>(
      begin: roundedContainerHight,
      end: roundedContainerHight + 10,
    ).animate(CurvedAnimation(
      parent: _roundedVerticalContainerControllerHight,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: recordButtonScale,
    ).chain(CurveTween(curve: Curves.elasticInOut)).animate(
          _animationController,
          // curve: Curves.easeInOut,
        );
    _roundedVerticalContainerAnimation = Tween<double>(
      begin: 1.0,
      end: 1.6,
    ).animate(CurvedAnimation(
      parent: _roundedVerticalContainerController,
      curve: Curves.easeInOut,
    ));

    _slideUpParIconArrowUpAnimation =
        Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(
      parent: _slideUpParIconArrowUpAnimationController,
      curve: Curves.easeInOut,
    ));

    colorController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    colorAnimation =
        ColorTween(begin: Color.fromARGB(255, 107, 107, 107), end: Colors.black)
            .animate(CurvedAnimation(
                parent: colorController,
                curve: Curves.easeInOutCubicEmphasized));

    _roundedVerticalContainerController.addStatusListener(
      (status) {
        if (status == AnimationStatus.dismissed &&
            !_roundedVerticalContainerController.isAnimating) {
          roundedContainerVal.value = 0;
          isMoving.value = false;
          _roundedVerticalContainerController.reverse();
          shouldStartVisualizer.value = true;
        }
      },
    );
  }

  void preWarm() {
    // Advance controllers by 1 frame to ensure they're ready
    _animationController.value = 0.0;
    _roundedVerticalContainerController.value = 0.0;
    _roundedVerticalContainerControllerHight.value = 0.0;
    _slideUpParIconArrowUpAnimationController.value = 0.0;
    colorController.value = 0.0;
    micFadeController.value = 0.0;

    // Force a frame to be rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

// Async permission request - non-blocking
  Future<void> requestPermissionsAsync() async {
    if (_permissionCheckInProgress || _permissionsGranted) return;

    _permissionCheckInProgress = true;

    try {
      final results = await Future.wait([
        Permission.storage.request(),
        Permission.microphone.request(),
      ]);

      final storagePermission = results[0];
      final micPermission = results[1];

      if (storagePermission.isGranted) {
        log("Storage permission granted");
      } else if (storagePermission.isPermanentlyDenied) {
        log("Storage permission permanently denied. Open settings.");
        await openAppSettings();
      }

      if (micPermission.isGranted) {
        log("Mic permission granted");
        _permissionsGranted = true;
      } else if (micPermission.isDenied) {
        log("Mic permission denied - will retry on next interaction");
      }
    } catch (e) {
      log("Permission request error: $e");
    } finally {
      _permissionCheckInProgress = false;
    }
  }

  // Synchronous permission check - non-blocking fallback
  void requestPermissions() {
    // Don't block - just schedule async request
    Future.microtask(() => requestPermissionsAsync());
  }

  void startMicFade() {
    micFadeController.repeat(reverse: true);
  }

  void stopMicFade() {
    micFadeController.reverse();
  }

  void startTimerRecord() {
    // if (!isMoving.value) return;

    recordTimer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        secondsElapsed.value++;
      },
    );
  }

  void stopTimer() {
    recordTimer?.cancel();
    secondsElapsed.value = 0;
  }

  void pauseTimer() {
    int tempValue = secondsElapsed.value;
    secondsElapsed.value = tempValue;
    recordTimer?.cancel();
  }

  void playTimer() {}

  void startShackleAnimation() {
    shackleAnimationController.repeat(reverse: true);
  }

  void stopShackleAnimation() {
    shackleAnimationController.reverse();
  }

  void startSlideUpIconAnimaiton() {
    _slideUpParIconArrowUpAnimationController.repeat(reverse: true);
  }

  void stopSlideUpIconAnimation() {
    _slideUpParIconArrowUpAnimationController.reverse();
  }

  void startColorAnimation() {
    if (isReachedLock.value) {
      colorController.forward();
    }
  }

  void stopColorAnimation() {
    colorController.reverse();
  }

  void onPanUpdate(details) {
    final dx = details.delta.dx;
    final dy = details.delta.dy;

    if (currentDirection == 'none') {
      if (dx.abs() > dy.abs()) {
        currentDirection = 'horizontal';
      } else if (dy.abs() > dx.abs()) {
        currentDirection = 'vertical';
      }
    }

    // Apply movement based on current direction
    if (currentDirection == 'horizontal') {
      onHorizontalUpdate(DragUpdateDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        delta: Offset(details.delta.dx, 0.0),
        primaryDelta: dx,
      ));
    } else if (currentDirection == 'vertical') {
      onVerticalDragUpdate(DragUpdateDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        delta: Offset(0.0, details.delta.dy),
        primaryDelta: dy,
      ));
    }
    // log('x ${xAxisVal.value.abs()} , y ${dyOffsetVerticalUpdate.value.abs()}');
    // Allow switching back only when both are reset
    if (xAxisVal.value == 0.0 && dyOffsetVerticalUpdate.value.abs() == 0.0) {
      currentDirection = 'none';
      onHorizontalEnd(details);

      // onVerticalDragEnd(details);

      // roundedContainerVal.value = 0;
    }
  }

  void onPanEnd(details) {
    onVerticalDragEnd(DragEndDetails(
      velocity: Velocity(
          pixelsPerSecond: Offset(0, details.velocity.pixelsPerSecond.dy)),
      primaryVelocity: details.velocity.pixelsPerSecond.dy,
    ));

    onHorizontalEnd(DragEndDetails(
      velocity: Velocity(
          pixelsPerSecond: Offset(details.velocity.pixelsPerSecond.dx, 0)),
      primaryVelocity: details.velocity.pixelsPerSecond.dx,
    ));

    log(isHorizontalMoving.value.toString());
  }

  void onHorizontalUpdate(details) {
    isMoving.value = true;
    isHorizontalMoving.value = true;
    // log(isHorizontalMoving.value.toString());
    // log(onHorizontalButtonScale.value.toString());

    // log(roundedContainerHorizontal.value.toString());
    onHorizontalButtonScale.value = recordButtonScale;
    xAxisVal.value += details.delta.dx;

    roundedContainerHorizontal.value = xAxisVal.value;
    if (xAxisVal.value < -roundedContainerHight) {
      xAxisVal.value = -roundedContainerHight;
      isReachedCancel.value = true;
    }
    if (xAxisVal.value > 0) {
      xAxisVal.value = 0;
    }
    if (xAxisVal.value > -roundedContainerHight) {
      isReachedCancel.value = false;
    }

    roundedOpacity.value = 1.0 -
        (xAxisVal.value.abs() * recordButtonScale / roundedContainerHight)
            .clamp(0.0, 1.0);
  }

  void onPanCancel() {
    onVerticalDragCancel();
    onHorizontalCancel();

    // isMoving.value = false;
  }

  void onHorizontalEnd(details) {
    xAxisVal.value = 0;
    onHorizontalButtonScale.value = 1.0;
    isHorizontalMoving.value = false;
    roundedContainerHorizontal.value = 0;
    roundedOpacity.value = 1.0;
  }

  void onHorizontalCancel() {
    xAxisVal.value = 0;
    onHorizontalButtonScale.value = 1.0;
    isHorizontalMoving.value = false;
    roundedContainerHorizontal.value = 0;
    roundedOpacity.value = 1.0;
  }

  void onVerticalDragUpdate(details) {
    isMovingVertical.value = true;
    isMoving.value = true;
    dyOffsetVerticalUpdate.value += details.delta.dy;
    // verticalScale.value += ( - details.delta.dy.abs() *0.1 );
    roundedContainerVal.value = dyOffsetVerticalUpdate.value;

    if (dyOffsetVerticalUpdate.value < lockValue) {
      dyOffsetVerticalUpdate.value = lockValue.toDouble();
      roundedContainerVal.value = lockValue.toDouble();

      isReachedLock.value = true;
      startColorAnimation();
      stopShackleAnimation();
    }
    if (dyOffsetVerticalUpdate.value >= 0) {
      dyOffsetVerticalUpdate.value = 0;
    }
    // _onVerticalEndEndRoundedContainer(dyOffsetVerticalUpdate.value , false);
    shackleLock.value =
        (dyOffsetVerticalUpdate.value.abs() / roundedContainerHight) *
            ((roundedContainerWidth * 0.4) * 0.5);

    verticalScale.value = recordButtonScale -
        (dyOffsetVerticalUpdate.value.abs() * 3.5 / roundedContainerHight)
            .clamp(0.1, recordButtonScale);

    arrowOpacity.value = 1.0 -
        (dyOffsetVerticalUpdate.value.abs() *
                recordButtonScale /
                roundedContainerHight)
            .clamp(0.0, 1.0);
    // if( verticalScale.value < 0.3){
    //   verticalScale.value = 0.3;
    // }
    initialOffset = Offset(0, dyOffsetVerticalUpdate.value);
  }

  void toggleLock() {
    isReachedLock.value = !isReachedLock.value;
    stopColorAnimation();
  }

  void _startAnimationRoundedHight() {
    _roundedVerticalContainerControllerHight.repeat(reverse: true).then(
      (value) {
        if (isMovingVertical.value) {
          _roundedVerticalContainerControllerHight.reverse();
        }
      },
    );
  }

  void onVerticalDragEnd(details) {
    dyOffsetVerticalUpdate.value = 0;
    isMovingVertical.value = false;
    // log('onVerticalDrageTriggered');

    // isMoving.value = false;
    // await  Future.delayed(Duration(milliseconds: 700));
    _onVerticalEndEndRoundedContainer(roundedContainerVal.value, true);
  }

  onVerticalDragCancel() {
// _reverseRevScalse.call();
    dyOffsetVerticalUpdate.value = 0;
    isMovingVertical.value = false;
    // await  Future.delayed(Duration(milliseconds: 700));
    _onVerticalEndEndRoundedContainer(roundedContainerVal.value, true);
  }

  void _startAnimation() {
    _animationController.forward();
    _startAnimationRoundedHight.call();
    startSlideUpIconAnimaiton();
    startShackleAnimation();

    isMoving.value = true;
    Future.microtask(() => Vibration.vibrate(duration: 100));
    // Vibration.vibrate(duration: 100); // short feedback
  }

  void _reverseAnimation() {
    _animationController.reverse();
    stopSlideUpIconAnimation();
    // startShackleAnimation();
    stopShackleAnimation();
    isMoving.value = false;
    Future.microtask(() => Vibration.vibrate(duration: 100));

    // Vibration.vibrate(duration: 100); // short feedback

    // stopTimer();
  }

  void _forwardRoundedContainerAnimation() {
    _roundedVerticalContainerController.repeat(
        reverse: true,
        // period: Duration(milliseconds: 500) ,
        count: 3);

    // Future.delayed(Duration(milliseconds: 500));
    // roundedContainerVal.value = 0;
    // isMoving.value = false;
    // _roundedVerticalContainerController.reverse();
  }

  void _onVerticalEndEndRoundedContainer(double verticalVal, bool isOnEnd) {
    if (verticalVal == lockValue && !isOnEnd) {
      roundedContainerVal.value = verticalVal;
      isMoving.value = true;
    } else if (verticalVal == lockValue) {
      roundedContainerVal.value = lockValue.toDouble();
      isMoving.value = true;

      _forwardRoundedContainerAnimation();
      // roundedContainerVal.value = 0;
      // isMoving.value = false;
    } else if (verticalVal != lockValue) {
      roundedContainerVal.value = 0;
      isMoving.value = false;
    } else {
      return;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _roundedVerticalContainerControllerHight.dispose();
    _roundedVerticalContainerController.dispose();
    _slideUpParIconArrowUpAnimationController.dispose();
    micFadeController.dispose();
    colorController.dispose();
    shackleAnimationController.dispose();
    stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
