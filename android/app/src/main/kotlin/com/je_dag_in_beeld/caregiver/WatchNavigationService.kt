package com.je_dag_in_beeld.caregiver

import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class WatchNavigationService : WearableListenerService() {
    private val TAG = "WatchNavigationService"
    private val NAVIGATION_PATH = "/navigation"

    companion object {
        var methodChannel: io.flutter.plugin.common.MethodChannel? = null
        const val CHANNEL = "com.jedaginbeeld.wear"
    }

    override fun onDataChanged(dataEvents: com.google.android.gms.wearable.DataEventBuffer) {
        Log.d(TAG, "onDataChanged: ${dataEvents.count} data events received")
        for (event in dataEvents) {
            Log.d(TAG, "event: type=${event.type}, uri=${event.dataItem.uri}")
            if (event.type == DataEvent.TYPE_CHANGED && event.dataItem.uri.path == NAVIGATION_PATH) {
                try {
                    val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                    val action = dataMap.getString("action") ?: return
                    Log.d(TAG, "Received navigation action: $action")
                    if (action == "next" || action == "prev") {
                        methodChannel?.invokeMethod("onWatchNavigation", mapOf("action" to action))
                        Log.d(TAG, "Sent to Flutter via method channel")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing navigation data", e)
                }
            }
        }
    }
}
