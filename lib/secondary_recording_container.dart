import 'package:animated_chat_record_button/animations.dart';
import 'package:animated_chat_record_button/time_format_helpers.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class SlideToCancelContainer extends StatefulWidget {
  const SlideToCancelContainer({super.key, required this.animationGlop});
  final AnimationGlop animationGlop;
  @override
  State<SlideToCancelContainer> createState() => _SlideToCancelContainerState();
}

class _SlideToCancelContainerState extends State<SlideToCancelContainer> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedBuilder(
      animation: widget.animationGlop.micFadeAnimation,
      builder: (context, child) => ValueListenableBuilder(
        valueListenable: widget.animationGlop.secondsElapsed,
        builder: (context, value, child) => Container(
          width: screenWidth - 55,
          height: 50,
          decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50)),
          child: Stack(
            // spacing: 25,
            children: [
              Positioned(
                left: 0,
                bottom: 0,
                top: 0,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      child: FadeTransition(
                        opacity: widget.animationGlop.micFadeAnimation,
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: Colors.red,
                          size: 25,
                        ),
                      ),
                    ),
                    Text(
                      formatTime(value),
                      style: TextStyle(color: Colors.grey),
                    )
                  ],
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 35,
                child: ValueListenableBuilder(
                  valueListenable: widget.animationGlop.roundedOpacity,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 10,
                          color: Colors.grey,
                        ),
                        Shimmer(
                          duration: Duration(seconds: 2), //Default value
                          interval: Duration(
                              seconds: 0), //Default value: Duration(seconds: 0)
                          color: Colors.white, //Default value
                          colorOpacity: 0.3, //Default value
                          enabled: true, //Default value

                          direction: ShimmerDirection.fromLTRB(),
                          child: Text(
                            'Slide to cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
