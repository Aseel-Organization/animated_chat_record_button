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
  // Visualizer
  // private var visualizerEventSink: EventChannel.EventSink? = null
  // private var visualizerHandler: Handler? = null
  // private var visualizerRunnable: Runnable? = null
  
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
    
    // visualizerChannel = EventChannel(flutterPluginBinding.binaryMessenger, "your_plugin/visualizer")
    // visualizerChannel.setStreamHandler(this)
    



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

  // private fun requestPermissions(result: Result) {
  //   val permissions = arrayOf(
  //     Manifest.permission.RECORD_AUDIO,
  //     Manifest.permission.WRITE_EXTERNAL_STORAGE
  //   )
    
  //   val hasPermissions = permissions.all { permission ->
  //     ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
  //   }
    
  //   if (hasPermissions) {
  //     result.success(true)
  //   } else {
  //     activity?.let { act ->
  //       ActivityCompat.requestPermissions(act, permissions, REQUEST_PERMISSION_CODE)
  //       result.success(false)
  //     } ?: result.success(false)
  //   }
  // }

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




// private fun startVisualizer(result: Result) {
//     try {
//         val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

//         audioRecord = AudioRecord(
//             MediaRecorder.AudioSource.MIC,
//             SAMPLE_RATE,
//             CHANNEL_CONFIG,
//             AUDIO_FORMAT,
//             bufferSize
//         )

//         audioRecord?.startRecording()

//         visualizerHandler = Handler(Looper.getMainLooper())
//         visualizerRunnable = object : Runnable {
//             override fun run() {
//                 if (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
//                     val buffer = ShortArray(bufferSize)
//                     val read = audioRecord?.read(buffer, 0, bufferSize) ?: 0

//                     if (read > 0) {
//                         val amplitudes = mutableListOf<Double>()

//                         for (i in 0 until read) {
//                             val amplitude = abs(buffer[i].toDouble()) / Short.MAX_VALUE
//                             amplitudes.add(amplitude.coerceIn(0.0, 1.0)) // Normalize between 0.0 and 1.0
//                         }

//                         visualizerEventSink?.success(amplitudes)
//                     }

//                     visualizerHandler?.postDelayed(this, 16) // ~60 FPS update
//                 }
//             }
//         }

//         visualizerHandler?.post(visualizerRunnable!!)
//         result.success(true)

//     } catch (e: Exception) {
//         result.error("VISUALIZER_ERROR", e.message, null)
//     }
// }

  // private fun startVisualizer(result: Result) {
  //   try {
  //     val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
      
  //     audioRecord = AudioRecord(
  //       MediaRecorder.AudioSource.MIC,
  //       SAMPLE_RATE,
  //       CHANNEL_CONFIG,
  //       AUDIO_FORMAT,
  //       bufferSize
  //     )
      
  //     audioRecord?.startRecording()
      
  //     visualizerHandler = Handler(Looper.getMainLooper())
  //     visualizerRunnable = object : Runnable {
  //       override fun run() {
  //         if (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
  //           val buffer = ShortArray(bufferSize)
  //           val read = audioRecord?.read(buffer, 0, bufferSize) ?: 0
            
  //           if (read > 0) {
  //             val amplitudes = mutableListOf<Double>()
  //             val chunkSize = read / 10 // Create 10 bars
              
  //             for (i in 0 until 10) {
  //               val start = i * chunkSize
  //               val end = minOf((i + 1) * chunkSize, read)
  //               var sum = 0.0
                
  //               for (j in start until end) {
  //                 sum += abs(buffer[j].toDouble())
  //               }
                
  //               val average = sum / (end - start)
  //               val db = if (average > 0) 20 * log10(average / Short.MAX_VALUE) else -80.0
  //               val normalized = maxOf(0.0, minOf(1.0, (db + 80) / 80))
  //               amplitudes.add(normalized)
  //             }
              
  //             visualizerEventSink?.success(amplitudes)
  //           }
            
  //           visualizerHandler?.postDelayed(this, 50) // Update every 50ms
  //         }
  //       }
  //     }
      
  //     visualizerHandler?.post(visualizerRunnable!!)
  //     result.success(true)
      
  //   } catch (e: Exception) {
  //     result.error("VISUALIZER_ERROR", e.message, null)
  //   }
  // }

  // private fun stopVisualizer(result: Result) {
  //   visualizerRunnable?.let { visualizerHandler?.removeCallbacks(it) }
  //   audioRecord?.stop()
  //   audioRecord?.release()
  //   audioRecord = null
  //   result.success(true)
  // }


      private fun stopMicAmplitudeStream() {
        isVisualizing = false
        visualizerThread?.join()
    }

  // EventChannel.StreamHandler methods
  // override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
  //   visualizerEventSink = events
  // }

  // override fun onCancel(arguments: Any?) {
  //   visualizerEventSink = null
  // }

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