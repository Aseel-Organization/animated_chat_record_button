import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AudioHandlers {
  final MethodChannel _channel = MethodChannel('your_plugin/audio');
  final MethodChannel visualizerChannel =
      MethodChannel('your_plugin/visualizer');
  static Future<String> _getRecordingPath() async {
    final directory = await getExternalStorageDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory?.path}/recording_$timestamp.aac';
  }

  /// used to start native recording at sample rate 44100
  /// save the output file int the given filePath
  Future<bool> startRecording({String? filePath}) async {
    final filePaths = filePath ?? await _getRecordingPath();

    // Ensure directory exists
    final file = File(filePaths);
    await file.parent.create(recursive: true);

    try {
      log('started recording at $filePaths');
      final result = await _channel.invokeMethod('startRecording', {
        'filePath': filePaths,
      });
      return result ?? false;
    } catch (e) {
      log('Error starting recording: $e');
      return false;
    }
  }

  /// used to stop native recording
  Future<File?> stopRecording() async {
    try {
      final result = await _channel.invokeMethod('stopRecording');
      // log(" ${result['localPath']} ${result['localPath'].runtimeType}");
      return File(result['localPath']);
    } catch (e) {
      log('Error stopping recording: $e');
      return null;
    }
  }

  Future<File?> pauseRecording() async {
    try {
      final result = await _channel.invokeMethod('pauseRecording');
      return File(result['localPath']);
    } catch (e) {
      return null;
    }
  }

  Future<bool> resumeRecording() async {
    try {
      final result = await _channel.invokeMethod('resumeRecording');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Audio Visualizer Stream
  // Stream<List<double>> get visualizerStream {
  //   return _visualizerChannel.receiveBroadcastStream().map((data) {
  //     if (data is List) {
  //       return data.cast<double>();
  //     }
  //     return <double>[];
  //   });
  // }

  Future<void> startVisualizer() async {
    await visualizerChannel.invokeMethod('startVisualizer');
  }

  Future<void> stopVisualizer() async {
    await visualizerChannel.invokeMethod('stopVisualizer');
  }

  // Permission handling
  // Future<bool> requestPermissions() async {
  //   try {
  //     final result = await _channel.invokeMethod('requestPermissions');
  //     return result ?? false;
  //   } catch (e) {
  //     return false;
  //   }
  // }
}
