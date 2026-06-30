package com.je_dag_in_beeld.caregiver.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import coil.compose.AsyncImage
import androidx.lifecycle.viewmodel.compose.viewModel

private val AccentRed = Color(0xFFFF3B30)
private val AccentGreen = Color(0xFF34C759)
private val White = Color(0xFFFFFFFF)
private val Black = Color(0xFF000000)
private val BackgroundLight = Color(0xFFF2F2F7)

@Composable
fun WearApp(
    onNext: () -> Unit,
    onPrev: () -> Unit
) {
    val state by SessionRepository.sessionState.collectAsState()

    if (state.isActive && state.totalSteps > 0) {
        SessionScreen(state, onNext, onPrev)
    } else {
        IdleScreen()
    }
}

@Composable
fun SessionScreen(
    state: SessionState,
    onNext: () -> Unit,
    onPrev: () -> Unit
) {
    val currentStep = if (
        state.steps.isNotEmpty() &&
        state.currentIndex in state.steps.indices
    ) {
        state.steps[state.currentIndex]
    } else {
        null
    }
    val isLastStep = state.currentIndex == state.totalSteps - 1
    val isFirstStep = state.currentIndex == 0

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundLight),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 2.dp, vertical = 2.dp),
            verticalArrangement = Arrangement.SpaceBetween,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Step counter
            Text(
                text = "${state.currentIndex + 1} / ${state.totalSteps}",
                style = MaterialTheme.typography.caption1,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colors.onBackground,
                modifier = Modifier.padding(top = 2.dp)
            )

            // Pictogram image (larger)
            currentStep?.let { step ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(6f)
                        .padding(horizontal = 2.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(White)
                        .padding(4.dp),
                    contentAlignment = Alignment.Center
                ) {
                    AsyncImage(
                        model = step.imageUrl,
                        contentDescription = step.keyword,
                        modifier = Modifier.fillMaxSize()
                    )
                }

                // Keyword label
                Text(
                    text = step.keyword,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    color = Black,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }

            // Navigation buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Previous button
                Button(
                    onClick = {
                        android.util.Log.d("SessionScreen", "Previous button clicked, isFirstStep = $isFirstStep")
                        onPrev()
                    },
                    enabled = !isFirstStep,
                    modifier = Modifier
                        .size(36.dp)
                        .weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = if (isFirstStep) AccentRed.copy(alpha = 0.5f) else AccentRed,
                        contentColor = White
                    ),
                    shape = RoundedCornerShape(18.dp)
                ) {
                    Text(
                        text = "‹",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                // Next button
                Button(
                    onClick = {
                        android.util.Log.d("SessionScreen", "Next button clicked, isLastStep = $isLastStep")
                        onNext()
                    },
                    modifier = Modifier
                        .size(36.dp)
                        .weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AccentGreen,
                        contentColor = White
                    ),
                    shape = RoundedCornerShape(18.dp)
                ) {
                    Text(
                        text = if (isLastStep) "✓" else "›",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
