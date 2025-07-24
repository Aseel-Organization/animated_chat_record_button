import Flutter
import UIKit
import AVFoundation

public class AnimatedChatRecordButtonPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var methodChannel: FlutterMethodChannel!
  private var visualizerChannel: FlutterEventChannel!
  private var eventSink: FlutterEventSink?
  
  private var audioRecorder: AVAudioRecorder?
  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?
  private var visualizerTimer: Timer?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = YourPluginPlugin()
    
    instance.methodChannel = FlutterMethodChannel(
      name: "your_plugin/audio",
      binaryMessenger: registrar.messenger()
    )
    
    instance.visualizerChannel = FlutterEventChannel(
      name: "your_plugin/visualizer",
      binaryMessenger: registrar.messenger()
    )
    
    registrar.addMethodCallDelegate(instance, channel: instance.methodChannel)
    instance.visualizerChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermissions":
      requestPermissions(result: result)
    case "startRecording":
      startRecording(call: call, result: result)
    case "stopRecording":
      stopRecording(result: result)
    case "pauseRecording":
      pauseRecording(result: result)
    case "resumeRecording":
      resumeRecording(result: result)
    case "startVisualizer":
      startVisualizer(result: result)
    case "stopVisualizer":
      stopVisualizer(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func requestPermissions(result: @escaping FlutterResult) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }
  
  private func startRecording(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let filePath = args["filePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "File path required", details: nil))
      return
    }
    
    let url = URL(fileURLWithPath: filePath)
    
    let settings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    do {
      try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      
      audioRecorder = try AVAudioRecorder(url: url, settings: settings)
      audioRecorder?.record()
      
      result(true)
    } catch {
      result(FlutterError(code: "RECORDING_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func stopRecording(result: @escaping FlutterResult) {
    audioRecorder?.stop()
    audioRecorder = nil
    result(true)
  }
  
  private func pauseRecording(result: @escaping FlutterResult) {
    audioRecorder?.pause()
    result(true)
  }
  
  private func resumeRecording(result: @escaping FlutterResult) {
    audioRecorder?.record()
    result(true)
  }
  
  private func startVisualizer(result: @escaping FlutterResult) {
    do {
      audioEngine = AVAudioEngine()
      inputNode = audioEngine?.inputNode
      
      let recordingFormat = inputNode?.outputFormat(forBus: 0)
      
      inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, _) in
        self?.processAudioBuffer(buffer)
      }
      
      try audioEngine?.start()
      
      visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
        // Timer keeps the visualizer running
      }
      
      result(true)
    } catch {
      result(FlutterError(code: "VISUALIZER_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func stopVisualizer(result: @escaping FlutterResult) {
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    visualizerTimer?.invalidate()
    audioEngine = nil
    result(true)
  }
  
  private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
    guard let channelData = buffer.floatChannelData?[0] else { return }
    
    let frameCount = Int(buffer.frameLength)
    let amplitudes = stride(from: 0, to: frameCount, by: frameCount / 10).map { i in
      let endIndex = min(i + frameCount / 10, frameCount)
      let chunk = Array(UnsafeBufferPointer(start: channelData + i, count: endIndex - i))
      let rms = sqrt(chunk.map { $0 * $0 }.reduce(0, +) / Float(chunk.count))
      return min(Double(rms * 10), 1.0) // Normalize and amplify
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(amplitudes)
    }
  }
  
  // FlutterStreamHandler methods
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}