package com.je_dag_in_beeld.caregiver.wear

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
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
                    handleNavigation("next")
                },
                onPrev = {
                    handleNavigation("prev")
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

    private fun handleNavigation(action: String) {
        Log.d(TAG, "handleNavigation: $action")
        val currentState = SessionRepository.sessionState.value
        val currentIndex = currentState.currentIndex
        val totalSteps = currentState.totalSteps
        val newIndex = when (action) {
            "next" -> (currentIndex + 1).coerceAtMost(totalSteps - 1)
            "prev" -> (currentIndex - 1).coerceAtLeast(0)
            else -> currentIndex
        }
        Log.d(TAG, "handleNavigation: $currentIndex -> $newIndex (total: $totalSteps)")
        SessionRepository.navigateToIndex(newIndex)
    }
}
