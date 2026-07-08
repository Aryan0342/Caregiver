package com.je_dag_in_beeld.caregiver.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
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
import androidx.compose.ui.input.pointer.pointerInput
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
                        .weight(8f)
                        .padding(horizontal = 2.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(White)
                        .pointerInput(Unit) {
                            var totalDrag = 0f
                            detectHorizontalDragGestures(
                                onDragStart = { totalDrag = 0f },
                                onHorizontalDrag = { change, dragAmount ->
                                    change.consume()
                                    totalDrag += dragAmount
                                },
                                onDragEnd = {
                                    val threshold = 60f
                                    if (totalDrag > threshold) {
                                        android.util.Log.d("SessionScreen", "Swipe right detected -> prev")
                                        onPrev()
                                    } else if (totalDrag < -threshold) {
                                        android.util.Log.d("SessionScreen", "Swipe left detected -> next")
                                        onNext()
                                    }
                                }
                            )
                        }
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
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    color = Black,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }
    }
}
