import 'package:flutter_test/flutter_test.dart';
import 'package:animated_chat_record_button/animated_chat_record_button.dart';
import 'package:animated_chat_record_button/animated_chat_record_button_platform_interface.dart';
import 'package:animated_chat_record_button/animated_chat_record_button_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAnimatedChatRecordButtonPlatform
    with MockPlatformInterfaceMixin
    implements AnimatedChatRecordButtonPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AnimatedChatRecordButtonPlatform initialPlatform = AnimatedChatRecordButtonPlatform.instance;

  test('$MethodChannelAnimatedChatRecordButton is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAnimatedChatRecordButton>());
  });

  test('getPlatformVersion', () async {
    AnimatedChatRecordButton animatedChatRecordButtonPlugin = AnimatedChatRecordButton();
    MockAnimatedChatRecordButtonPlatform fakePlatform = MockAnimatedChatRecordButtonPlatform();
    AnimatedChatRecordButtonPlatform.instance = fakePlatform;

    expect(await animatedChatRecordButtonPlugin.getPlatformVersion(), '42');
  });
}
