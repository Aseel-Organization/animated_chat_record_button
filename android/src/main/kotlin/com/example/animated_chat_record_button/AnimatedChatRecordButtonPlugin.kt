package com.example.animated_chat_record_button


import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.sqrt
class AnimatedChatRecordButtonPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var methodChannel: MethodChannel
  // private lateinit var visualizerChannel: EventChannel
  private lateinit var context: Context
  private var activity: android.app.Activity? = null
  
  private var mediaRecorder: MediaRecorder? = null
  private var audioRecord: AudioRecord? = null
  private var isRecording = false
  private var isPaused = false
  private var localRecordingPath: String? = null

  
  private var visualizerThread: Thread? = null
  private var isVisualizing = false
  private var visualizerChannel: MethodChannel? = null


  companion object {
    private const val SAMPLE_RATE = 44100
    private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private const val REQUEST_PERMISSION_CODE = 1001
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "your_plugin/audio")
    methodChannel.setMethodCallHandler(this)
    

    



        visualizerChannel = MethodChannel(flutterPluginBinding.binaryMessenger,  "your_plugin/visualizer")
        visualizerChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVisualizer" -> {
                    startMicAmplitudeStream()
                    result.success(null)
                }
                "stopVisualizer" -> {
                    stopMicAmplitudeStream()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    context = flutterPluginBinding.applicationContext
  }



  
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      // "requestPermissions" -> requestPermissions(result)
      "startRecording" -> startRecording(call, result)
      "stopRecording" -> stopRecording(result)
      "pauseRecording" -> pauseRecording(result)
      "resumeRecording" -> resumeRecording(result)
      // "startVisualizer" -> startMicAmplitudeStream()
      // "stopVisualizer" -> stopVisualizer()
      else -> result.notImplemented()
    }
  }



  private fun startRecording(call: MethodCall, result: Result) {
    val filePath = call.argument<String>("filePath")
    localRecordingPath =filePath
    if (filePath == null) {
      result.error("INVALID_ARGUMENT", "File path is required", null)
      return
    }

    try {
      stopRecording(null) // Stop any existing recording
      
      mediaRecorder = MediaRecorder().apply {
        setAudioSource(MediaRecorder.AudioSource.MIC)
        setOutputFormat(MediaRecorder.OutputFormat.AAC_ADTS)
        setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        setAudioEncodingBitRate(96000) 
         setAudioSamplingRate(44100) 
        setOutputFile(filePath)
        prepare()
        start()
      }
      
      isRecording = true
      isPaused = false
      result.success(true)
    } catch (e: Exception) {
      result.error("RECORDING_ERROR", e.message, null)
    }
  }

  private fun stopRecording(result: Result?) {
    try {
      mediaRecorder?.apply {
        if (isRecording) {
          stop()
          release()
        }
      }
      mediaRecorder = null
      isRecording = false
      isPaused = false
      result?.success(mapOf("localPath" to localRecordingPath ))
    } catch (e: Exception) {
      result?.error("STOP_ERROR", e.message, null)
    }
  }

  private fun pauseRecording(result: Result) {
    try {
      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
        mediaRecorder?.pause()
        isPaused = true
        result?.success(mapOf("localPath" to localRecordingPath))
      } else {
        result.error("UNSUPPORTED", "Pause not supported on this Android version", null)
      }
    } catch (e: Exception) {
      result.error("PAUSE_ERROR", e.message, null)
    }
  }

  private fun resumeRecording(result: Result) {
    try {
      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
        mediaRecorder?.resume()
        isPaused = false
        result.success(true)
      } else {
        result.error("UNSUPPORTED", "Resume not supported on this Android version", null)
      }
    } catch (e: Exception) {
      result.error("RESUME_ERROR", e.message, null)
    }
  }




private fun startMicAmplitudeStream() {
    val sampleRate = 44100
    val bufferSize = AudioRecord.getMinBufferSize(
        sampleRate,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_16BIT
    )

    val audioRecord = AudioRecord(
        MediaRecorder.AudioSource.MIC,
        sampleRate,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_16BIT,
        bufferSize
    )

    isVisualizing = true
    visualizerThread = Thread {
        val buffer = ShortArray(bufferSize)
        audioRecord.startRecording()

        while (isVisualizing) {
            val read = audioRecord.read(buffer, 0, buffer.size)
            if (read > 0) {
                // Calculate average amplitude (RMS)
                val rms = buffer.take(read).map { it.toDouble() * it }.average()
                val amplitude = sqrt(rms) / Short.MAX_VALUE
                 Handler(Looper.getMainLooper()).post {
                        visualizerChannel?.invokeMethod("onAmplitude", amplitude)
                    }
            }
            Thread.sleep(50) // ~20fps
        }

        audioRecord.stop()
        audioRecord.release()
    }
    visualizerThread?.start()
}




      private fun stopMicAmplitudeStream() {
        isVisualizing = false
        visualizerThread?.join()
    }


  // ActivityAware methods
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    // visualizerChannel.setStreamHandler(null)
         visualizerChannel = null
  }
}