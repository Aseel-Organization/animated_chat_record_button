import 'package:flutter/material.dart';

/// Configuration class for styling the record button
class RecordButtonConfig {
  final double? slideUpContainerHeight;
  final Color? slideUpContainerColor;
  final Color? firstRecordButtonColor;
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

  final Color? focusedBorderColor;
  final Color? activeBorderColor;

  const RecordButtonConfig({
    this.slideUpContainerHeight,
    this.slideUpContainerColor,
    this.firstRecordButtonColor,
    this.textFormFieldBoxFillColor,
    this.textFormFieldHint,
    this.textFormFieldStyle,
    this.textFormFieldHintStyle,
    this.containersPadding = const EdgeInsets.only(left: 8),
    this.firstRecordingButtonIcon = const Icon(Icons.mic, color: Colors.white, key:ValueKey('icon1')),
    this.secondRecordingButtonIcon = const Icon(
      Icons.send_rounded,
      color: Colors.white,
    ),
    this.recordButtonSize = 40,
    this.recordButtonScaleVal = 2.5,
    this.slideUpContainerWidth = 50,
    this.activeBorderColor,
    this.focusedBorderColor,
  }) : assert(
  recordButtonScaleVal >= 1.5 && recordButtonScaleVal <= 2.5,
  'recordButtonScaleVal must be between 1.5 and 2.5 for better experience',
  );
}
