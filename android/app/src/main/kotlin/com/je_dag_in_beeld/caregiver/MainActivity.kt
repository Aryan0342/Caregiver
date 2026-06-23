package com.je_dag_in_beeld.caregiver

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity(), MessageClient.OnMessageReceivedListener {
    private val CHANNEL = "com.jedaginbeeld.wear"
    private val WEAR_PATH = "/watch_session"
    private val NAVIGATION_PATH = "/navigation"

    private lateinit var dataClient: DataClient
    private lateinit var messageClient: MessageClient
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            dataClient = Wearable.getDataClient(this)
            messageClient = Wearable.getMessageClient(this)
        } catch (e: Exception) {
            // Handle Wearable APIs unavailable
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
            messageClient.addListener(this)
        } catch (e: Exception) {
            // Handle Wearable APIs unavailable
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            messageClient.removeListener(this)
        } catch (e: Exception) {
            // Handle Wearable APIs unavailable
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path == NAVIGATION_PATH) {
            try {
                val message = String(messageEvent.data, Charsets.UTF_8)
                val json = JSONObject(message)
                val action = json.optString("action")
                if (action == "next" || action == "prev") {
                    methodChannel?.invokeMethod("onWatchNavigation", mapOf("action" to action))
                }
            } catch (e: Exception) {
                // Handle parsing errors
            }
        }
    }

    private fun sendDataToWear(data: Map<String, Any>, result: MethodChannel.Result) {
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

            dataClient.putDataItem(putDataRequest)
                .addOnSuccessListener {
                    result.success(null)
                }
                .addOnFailureListener { e ->
                    result.error("WEAR_ERROR", e.message, null)
                }
        } catch (e: Exception) {
            result.error("WEAR_ERROR", e.message, null)
        }
    }
}
