import 'dart:io';

import 'package:animated_chat_record_button/audio_handlers.dart';

void deleteOnCancel(AudioHandlers audio) async {
  final res = await audio.stopRecording();
  if (res != null) {
    await deleteFile(res);
  }
}

Future<void> deleteFile(File file) async {
  await file.delete();
}
