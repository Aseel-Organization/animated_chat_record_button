import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animated_chat_record_button/animated_chat_record_button_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAnimatedChatRecordButton platform = MethodChannelAnimatedChatRecordButton();
  const MethodChannel channel = MethodChannel('animated_chat_record_button');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
