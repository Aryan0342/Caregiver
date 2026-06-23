package com.je_dag_in_beeld.caregiver.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.wear.compose.material.MaterialTheme
import com.google.android.gms.wearable.Wearable

class MainActivity : ComponentActivity() {

    private val viewModel: SessionViewModel by viewModels()
    private val dataReceiver = WearDataReceiver()

    private fun sendNavigationToPhone(action: String) {
        val nodeClient = Wearable.getNodeClient(this)
        val messageClient = Wearable.getMessageClient(this)
        nodeClient.connectedNodes.addOnSuccessListener { nodes ->
            val path = "/navigation"
            val data = """{"action":"$action"}""".toByteArray(Charsets.UTF_8)
            for (node in nodes) {
                messageClient.sendMessage(node.id, path, data)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        dataReceiver.init(this)
        setContent {
            WearApp(viewModel) { action ->
                sendNavigationToPhone(action)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Wearable.getDataClient(this).addListener(dataReceiver)
    }

    override fun onPause() {
        super.onPause()
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
