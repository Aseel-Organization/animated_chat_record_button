import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'animated_chat_record_button_platform_interface.dart';

/// An implementation of [AnimatedChatRecordButtonPlatform] that uses method channels.
class MethodChannelAnimatedChatRecordButton
    extends AnimatedChatRecordButtonPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('animated_chat_record_button');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
