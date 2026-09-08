package com.je_dag_in_beeld.caregiver.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import coil.compose.AsyncImage

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
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundLight),
        contentAlignment = Alignment.Center
    ) {
        val isRound = LocalConfiguration.current.isScreenRound

        // On a round screen, a 70%-diameter square is fully contained inside
        // the physical circle (the exact inscribed-square ratio is 70.71%).
        // These proportional insets keep the counter, image and label away
        // from every curved edge across different watch sizes.
        val horizontalInset = if (isRound) maxWidth * 0.15f else maxWidth * 0.04f
        val verticalInset = if (isRound) maxHeight * 0.15f else maxHeight * 0.04f

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = horizontalInset, vertical = verticalInset),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Step counter
            Text(
                text = "${state.currentIndex + 1} / ${state.totalSteps}",
                style = MaterialTheme.typography.caption1,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colors.onBackground,
                maxLines = 1
            )

            Spacer(modifier = Modifier.height(2.dp))

            // The whole image card stays within the round-screen safe width.
            currentStep?.let { step ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f, fill = true)
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
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit
                    )
                }

                Spacer(modifier = Modifier.height(2.dp))

                // Keyword label
                Text(
                    text = step.keyword,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    color = Black,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}
