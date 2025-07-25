import Flutter
import UIKit
import AVFoundation

public class AnimatedChatRecordButtonPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var visualizerChannel: FlutterMethodChannel?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isRecording = false
    private var isPaused = false
    private var localRecordingPath: String?
    
    private var visualizerTimer: Timer?
    private var isVisualizing = false
    
    // Audio settings
    private let sampleRate: Double = 44100.0
    private let channels: UInt32 = 1
    private let bitDepth: UInt32 = 16
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = AnimatedChatRecordButtonPlugin()
        
        let methodChannel = FlutterMethodChannel(
            name: "your_plugin/audio",
            binaryMessenger: registrar.messenger()
        )
        
        let visualizerChannel = FlutterMethodChannel(
            name: "your_plugin/visualizer",
            binaryMessenger: registrar.messenger()
        )
        
        instance.methodChannel = methodChannel
        instance.visualizerChannel = visualizerChannel
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        registrar.addMethodCallDelegate(instance, channel: visualizerChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            startRecording(call: call, result: result)
        case "stopRecording":
            stopRecording(result: result)
        case "pauseRecording":
            pauseRecording(result: result)
        case "resumeRecording":
            resumeRecording(result: result)
        case "startVisualizer":
            startMicAmplitudeStream()
            result(nil)
        case "stopVisualizer":
            stopMicAmplitudeStream()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func startRecording(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "File path is required", details: nil))
            return
        }
        
        localRecordingPath = filePath
        
        // Stop any existing recording
        stopRecording(result: nil)
        
        setupAudioSession()
        
        let url = URL(fileURLWithPath: filePath)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 96000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            let success = audioRecorder?.record() ?? false
            if success {
                isRecording = true
                isPaused = false
                result(true)
            } else {
                result(FlutterError(code: "RECORDING_ERROR", message: "Failed to start recording", details: nil))
            }
        } catch {
            result(FlutterError(code: "RECORDING_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func stopRecording(result: FlutterResult?) {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        isPaused = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        let response = ["localPath": localRecordingPath ?? ""]
        result?(response)
    }
    
    private func pauseRecording(result: @escaping FlutterResult) {
        if #available(iOS 6.0, *) {
            audioRecorder?.pause()
            isPaused = true
            let response = ["localPath": localRecordingPath ?? ""]
            result(response)
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "Pause not supported on this iOS version", details: nil))
        }
    }
    
    private func resumeRecording(result: @escaping FlutterResult) {
        if #available(iOS 6.0, *) {
            let success = audioRecorder?.record() ?? false
            if success {
                isPaused = false
                result(true)
            } else {
                result(FlutterError(code: "RESUME_ERROR", message: "Failed to resume recording", details: nil))
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "Resume not supported on this iOS version", details: nil))
        }
    }
    
    private func startMicAmplitudeStream() {
        guard !isVisualizing else { return }
        
        setupAudioSession()
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        guard let audioEngine = audioEngine, let inputNode = inputNode else {
            print("Failed to create audio engine or input node")
            return
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let desiredFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        )
        
        guard let format = desiredFormat else {
            print("Failed to create desired audio format")
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isVisualizing = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        // Calculate RMS (Root Mean Square) for amplitude
        let sumOfSquares = channelDataArray.reduce(0) { $0 + ($1 * $1) }
        let rms = sqrt(sumOfSquares / Float(channelDataArray.count))
        let amplitude = Double(rms)
        
        DispatchQueue.main.async { [weak self] in
            self?.visualizerChannel?.invokeMethod("onAmplitude", arguments: amplitude)
        }
    }
    
    private func stopMicAmplitudeStream() {
        guard isVisualizing else { return }
        
        isVisualizing = false
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AnimatedChatRecordButtonPlugin: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recorder encode error: \(error)")
        }
    }
}