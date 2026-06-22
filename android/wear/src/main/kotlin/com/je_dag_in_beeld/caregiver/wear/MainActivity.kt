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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        dataReceiver.init(this)
        setContent {
            WearApp(viewModel)
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
fun WearApp(viewModel: SessionViewModel) {
    val state by viewModel.sessionState.collectAsState()

    MaterialTheme {
        if (state.isActive) {
            SessionScreen(state = state)
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
    WearApp(mockViewModel)
}
