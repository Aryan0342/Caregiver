package com.je_dag_in_beeld.caregiver.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Image
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import coil.compose.AsyncImage

@Composable
fun SessionScreen(state: SessionState) {
    val currentStep = if (state.steps.isNotEmpty() && state.currentIndex in state.steps.indices) {
        state.steps[state.currentIndex]
    } else {
        null
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "${state.currentIndex + 1} / ${state.totalSteps}",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        currentStep?.let { step ->
            AsyncImage(
                model = step.imageUrl,
                contentDescription = step.keyword,
                modifier = Modifier.size(120.dp),
            )

            Text(
                text = step.keyword,
                style = MaterialTheme.typography.title2,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 12.dp)
            )
        }
    }
}
