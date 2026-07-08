package com.je_dag_in_beeld.caregiver

import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class WatchNavigationService : WearableListenerService() {
    private val TAG = "WatchNavigationService"

    companion object {
        var methodChannel: io.flutter.plugin.common.MethodChannel? = null
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d(TAG, "onDataChanged: ${dataEvents.count} events")
        for (event in dataEvents) {
            Log.d(TAG, "event path: ${event.dataItem.uri.path}, type: ${event.type}")
            if (event.type == DataEvent.TYPE_CHANGED &&
                event.dataItem.uri.path == "/navigation") {
                try {
                    val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                    val action = dataMap.getString("action") ?: continue
                    Log.d(TAG, "Navigation received: $action")
                    val channel = methodChannel
                    if (channel != null) {
                        android.os.Handler(mainLooper).post {
                            channel.invokeMethod(
                                "onWatchNavigation",
                                mapOf("action" to action)
                            )
                            Log.d(TAG, "MethodChannel invoked: $action")
                        }
                    } else {
                        Log.e(TAG, "MethodChannel is null — MainActivity not yet initialized")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing navigation", e)
                }
            }
        }
    }
}
