package com.je_dag_in_beeld.caregiver.wear

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

class MainActivity : ComponentActivity() {
    private val TAG = "WearMainActivity"
    private val dataReceiver = WearDataReceiver()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        SessionRepository.init(this)
        setContent {
            WearApp(
                onNext = {
                    sendNavigationToPhone("next")
                },
                onPrev = {
                    sendNavigationToPhone("prev")
                }
            )
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            Wearable.getDataClient(this).addListener(dataReceiver)
            Log.d(TAG, "Data listener added")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add data listener", e)
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            Wearable.getDataClient(this).removeListener(dataReceiver)
            Log.d(TAG, "Data listener removed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove data listener", e)
        }
    }

    private fun sendNavigationToPhone(action: String) {
        Log.d(TAG, "sendNavigationToPhone via DataLayer: action = $action")
        try {
            val putDataMapRequest = PutDataMapRequest.create("/navigation")
            putDataMapRequest.dataMap.putString("action", action)
            putDataMapRequest.dataMap.putLong("timestamp", System.currentTimeMillis())
            val request = putDataMapRequest.asPutDataRequest().setUrgent()
            Wearable.getDataClient(this).putDataItem(request)
                .addOnSuccessListener { Log.d(TAG, "Navigation sent via DataLayer: $action") }
                .addOnFailureListener { e -> Log.e(TAG, "Failed to send navigation via DataLayer", e) }
        } catch (e: Exception) {
            Log.e(TAG, "sendNavigationToPhone exception", e)
        }
    }
}
