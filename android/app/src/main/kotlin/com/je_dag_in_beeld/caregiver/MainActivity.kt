package com.je_dag_in_beeld.caregiver

import android.util.Log
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterFragmentActivity() {
    private val tag = "PhoneMainActivity"
    private val channelName = "com.jedaginbeeld.wear"
    private val wearPath = "/watch_session"

    private var dataClient: DataClient? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
        WatchNavigationService.methodChannel = methodChannel
        Log.d(tag, "MethodChannel set in WatchNavigationService")

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
                    } catch (exception: Exception) {
                        result.error("WEAR_ERROR", exception.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            if (dataClient == null) {
                dataClient = Wearable.getDataClient(this)
            }
            Log.d(tag, "DataClient initialized")
        } catch (exception: Exception) {
            Log.e(tag, "Failed to initialize Wearable clients", exception)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.setMethodCallHandler(null)
        WatchNavigationService.methodChannel = null
        methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun sendDataToWear(data: Map<String, Any>, result: MethodChannel.Result) {
        val client = dataClient
        if (client == null) {
            result.error("WEAR_ERROR", "DataClient not initialized", null)
            return
        }

        try {
            val putDataMapRequest = PutDataMapRequest.create(wearPath)
            val dataMap = putDataMapRequest.dataMap

            (data["action"] as? String)?.let { dataMap.putString("action", it) }
            (data["userId"] as? String)?.let { dataMap.putString("userId", it) }
            dataMap.putInt("currentIndex", (data["currentIndex"] as? Int) ?: 0)
            dataMap.putInt("totalSteps", (data["totalSteps"] as? Int) ?: 0)
            dataMap.putString("setName", (data["setName"] as? String) ?: "")

            (data["pictograms"] as? List<*>)?.let { pictograms ->
                val jsonArray = JSONArray()
                for (item in pictograms) {
                    if (item is Map<*, *>) {
                        jsonArray.put(JSONObject(item))
                    }
                }
                dataMap.putString("pictograms", jsonArray.toString())
            }

            dataMap.putLong("timestamp", System.currentTimeMillis())
            val request = putDataMapRequest.asPutDataRequest().setUrgent()

            client.putDataItem(request)
                .addOnSuccessListener {
                    Log.d(tag, "sendDataToWear: success")
                    result.success(null)
                }
                .addOnFailureListener { exception ->
                    Log.e(tag, "sendDataToWear: failed", exception)
                    result.error("WEAR_ERROR", exception.message, null)
                }
        } catch (exception: Exception) {
            Log.e(tag, "sendDataToWear: exception", exception)
            result.error("WEAR_ERROR", exception.message, null)
        }
    }
}
