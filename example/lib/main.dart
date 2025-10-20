import 'dart:developer';

import 'package:animated_chat_record_button/configs/record_button_config.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'package:animated_chat_record_button/animated_chat_record_button.dart';

void main() {
  runApp(DevicePreview(
    enabled: true,
    builder: (context) => const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? filePathW;
  String? message;
  bool isRecording = false;
  TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final double screenHight = MediaQuery.of(context).size.height;

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xffeee5dc),
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Stack(
          children: [
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              bottom: 70, // Leaves space for the input/record button
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                reverse: true,
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  spacing: 5,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[500],
                        ),
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Column(
                            spacing: 5,
                            children: [
                              Text(
                                'message : $message',
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.black),
                              ),
                              Text(
                                'record path : $filePathW',
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedChatRecordButton(
              maxDuration: Duration(minutes: 5),
              config: RecordButtonConfig(
                recordButtonSize: 45,
              ),
              onPressEmoji: () {
                log('Emoji button pressed');
              },
              onPressCamera: () {
                log('Camera button pressed');
              },
              onPressAttachment: () {
                log('Attachment button pressed');
              },
              onSend: (text) {
                setState(() {
                  message = text;
                  log('Message sent: $message');
                });
              },
              onLockedRecording: (doesLocked) {
                log('Locked recording: $doesLocked');
                setState(() {
                  isRecording = doesLocked;
                });
              },
              textEditingController: textEditingController,
              onRecordingEnd: (filePath) {
                setState(() {
                  filePathW = filePath?.path;
                  log('from plugin test ${filePathW.toString()}');
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}