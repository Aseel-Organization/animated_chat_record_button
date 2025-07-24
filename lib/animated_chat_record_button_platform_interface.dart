import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'animated_chat_record_button_method_channel.dart';

abstract class AnimatedChatRecordButtonPlatform extends PlatformInterface {
  /// Constructs a AnimatedChatRecordButtonPlatform.
  AnimatedChatRecordButtonPlatform() : super(token: _token);

  static final Object _token = Object();

  static AnimatedChatRecordButtonPlatform _instance = MethodChannelAnimatedChatRecordButton();

  /// The default instance of [AnimatedChatRecordButtonPlatform] to use.
  ///
  /// Defaults to [MethodChannelAnimatedChatRecordButton].
  static AnimatedChatRecordButtonPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AnimatedChatRecordButtonPlatform] when
  /// they register themselves.
  static set instance(AnimatedChatRecordButtonPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
