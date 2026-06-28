package com.je_dag_in_beeld.caregiver

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val TAG = "PhoneMainActivity"
    private val CHANNEL = "com.jedaginbeeld.wear"
    private val WEAR_PATH = "/watch_session"

    private var dataClient: DataClient? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        WatchNavigationService.methodChannel = methodChannel
        Log.d(TAG, "MethodChannel set in WatchNavigationService")
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendToWear" -> {
                    try {
                        val data = call.argument<Map<String, Any>>("data")
                        if (data != null) {
                            sendDataToWear(data, result)
                        } else {
                            result.error("INVALID_ARGUMENT", "Data is required", null)
                        }
                    } catch (e: Exception) {
                        result.error("WEAR_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            if (dataClient == null) dataClient = Wearable.getDataClient(this)
            Log.d(TAG, "DataClient initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Wearable clients", e)
        }
    }

    private fun sendDataToWear(data: Map<String, Any>, result: MethodChannel.Result) {
        if (dataClient == null) {
            result.error("WEAR_ERROR", "DataClient not initialized", null)
            return
        }

        try {
            val putDataMapRequest = PutDataMapRequest.create(WEAR_PATH)
            val dataMap = putDataMapRequest.dataMap

            // Extract and put individual fields with defaults
            data["action"]?.let {
                if (it is String) dataMap.putString("action", it)
            }

            data["userId"]?.let {
                if (it is String) dataMap.putString("userId", it)
            }

            val currentIndex = (data["currentIndex"] as? Int) ?: 0
            dataMap.putInt("currentIndex", currentIndex)

            val totalSteps = (data["totalSteps"] as? Int) ?: 0
            dataMap.putInt("totalSteps", totalSteps)

            val setName = (data["setName"] as? String) ?: ""
            dataMap.putString("setName", setName)

            data["pictograms"]?.let { pictogramsList ->
                if (pictogramsList is List<*>) {
                    val jsonArray = JSONArray()
                    for (item in pictogramsList) {
                        if (item is Map<*, *>) {
                            jsonArray.put(JSONObject(item))
                        }
                    }
                    dataMap.putString("pictograms", jsonArray.toString())
                }
            }

            // Add timestamp (required to ensure data item is considered changed)
            dataMap.putLong("timestamp", System.currentTimeMillis())

            val putDataRequest = putDataMapRequest.asPutDataRequest()
            putDataRequest.setUrgent()

            dataClient?.putDataItem(putDataRequest)
                ?.addOnSuccessListener {
                    Log.d(TAG, "sendDataToWear: success")
                    result.success(null)
                }
                ?.addOnFailureListener { e ->
                    Log.e(TAG, "sendDataToWear: failed", e)
                    result.error("WEAR_ERROR", e.message, null)
                }
        } catch (e: Exception) {
            Log.e(TAG, "sendDataToWear: exception", e)
            result.error("WEAR_ERROR", e.message, null)
        }
    }
}
