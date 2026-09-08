package com.je_dag_in_beeld.caregiver.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text

@Composable
fun IdleScreen() {
    val isRound = LocalConfiguration.current.isScreenRound

    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        // A square that is 70% of a circle's diameter fits completely inside
        // a round display. Keep the idle message inside that safe region so
        // no glyphs can be cropped on small round watches.
        val horizontalInset = if (isRound) maxWidth * 0.15f else maxWidth * 0.06f
        val verticalInset = if (isRound) maxHeight * 0.15f else maxHeight * 0.06f

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = horizontalInset, vertical = verticalInset),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Start a session on your phone",
                style = MaterialTheme.typography.title2,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colors.onBackground
            )
        }
    }
}
