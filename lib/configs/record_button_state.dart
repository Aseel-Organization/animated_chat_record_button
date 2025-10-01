
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