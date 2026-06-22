package com.je_dag_in_beeld.caregiver

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import com.google.gson.Gson

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.jedaginbeeld.wear"
    private val WEAR_PATH = "/watch_session"

    private lateinit var dataClient: DataClient
    private var methodChannel: MethodChannel? = null
    private val gson = Gson()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        dataClient = Wearable.getDataClient(this)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendToWear" -> {
                    val data = call.argument<Map<String, Any>>("data")
                    if (data != null) {
                        sendDataToWear(data)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Data is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun sendDataToWear(data: Map<String, Any>) {
        try {
            val putDataMapRequest = PutDataMapRequest.create(WEAR_PATH)
            val dataMap = putDataMapRequest.dataMap

            // Extract and put individual fields with null handling
            data["action"]?.let {
                if (it is String) dataMap.putString("action", it)
            }

            data["currentIndex"]?.let {
                if (it is Int) dataMap.putInt("currentIndex", it)
            }

            data["totalSteps"]?.let {
                if (it is Int) dataMap.putInt("totalSteps", it)
            }

            data["setName"]?.let {
                if (it is String) dataMap.putString("setName", it)
            }

            data["userId"]?.let {
                if (it is String) dataMap.putString("userId", it)
            }

            data["pictograms"]?.let {
                dataMap.putString("pictograms", gson.toJson(it))
            }

            // Add timestamp (required to ensure data item is considered changed)
            dataMap.putLong("timestamp", System.currentTimeMillis())

            val putDataRequest = putDataMapRequest.asPutDataRequest()
            putDataRequest.setUrgent()

            dataClient.putDataItem(putDataRequest)
        } catch (e: Exception) {
            // Silently fail
        }
    }
}
