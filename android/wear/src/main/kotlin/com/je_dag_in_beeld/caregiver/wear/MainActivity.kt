package com.je_dag_in_beeld.caregiver.wear

import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.wear.compose.material.MaterialTheme
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class MainActivity : ComponentActivity() {
    private val TAG = "WearMainActivity"

    private val viewModel: SessionViewModel by viewModels()
    private val dataReceiver = WearDataReceiver()
    private val gson = Gson()

    private fun sendNavigationToPhone(action: String) {
        Log.d(TAG, "sendNavigationToPhone: action = $action")
        val nodeClient = Wearable.getNodeClient(this)
        val messageClient = Wearable.getMessageClient(this)
        nodeClient.connectedNodes.addOnSuccessListener { nodes ->
            Log.d(TAG, "sendNavigationToPhone: connected nodes = ${nodes.size}")
            val path = "/navigation"
            val data = """{"action":"$action"}""".toByteArray(Charsets.UTF_8)   
            for (node in nodes) {
                Log.d(TAG, "sendNavigationToPhone: sending to node ${node.id}")
                messageClient.sendMessage(node.id, path, data)
                    .addOnSuccessListener { 
                        Log.d(TAG, "sendNavigationToPhone: success")
                    }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "sendNavigationToPhone: failed", e)
                    }
            }
        }.addOnFailureListener { e ->
            Log.e(TAG, "sendNavigationToPhone: failed to get nodes", e)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate")
        dataReceiver.init(this)
        setContent {
            WearApp(viewModel) { action ->
                Log.d(TAG, "WearApp: onNavigation called with action = $action")
                sendNavigationToPhone(action)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume")
        Wearable.getDataClient(this).addListener(dataReceiver)
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "onPause")
        Wearable.getDataClient(this).removeListener(dataReceiver)
    }
}

@Composable
fun WearApp(
    viewModel: SessionViewModel,
    onNavigation: (String) -> Unit
) {
    val state by viewModel.sessionState.collectAsState()

    MaterialTheme {
        if (state.isActive) {
            SessionScreen(
                state = state,
                onNext = { onNavigation("next") },
                onPrev = { onNavigation("prev") }
            )
        } else {
            IdleScreen()
        }
    }
}

@Preview(
    showSystemUi = true,
    device = "id:wearos_small_round"
)
@Composable
fun WearAppPreview() {
    val mockViewModel = SessionViewModel()
    WearApp(mockViewModel) { /* do nothing in preview */ }
}
