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

private val AccentRed = Color(0xFFFF3B30)
private val AccentGreen = Color(0xFF34C759)
private val White = Color(0xFFFFFFFF)
private val Black = Color(0xFF000000)
private val BackgroundLight = Color(0xFFF2F2F7)

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
                .padding(horizontal = 10.dp, vertical = 6.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Step counter
            Text(
                text = "${state.currentIndex + 1} / ${state.totalSteps}",
                style = MaterialTheme.typography.caption1,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colors.onBackground,
                modifier = Modifier.padding(bottom = 6.dp)
            )

            // Pictogram image
            currentStep?.let { step ->
                Box(
                    modifier = Modifier
                        .size(60.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(White)
                        .padding(6.dp),
                    contentAlignment = Alignment.Center
                ) {
                    AsyncImage(
                        model = step.imageUrl,
                        contentDescription = step.keyword,
                        modifier = Modifier.fillMaxSize()
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Keyword label
                Text(
                    text = step.keyword,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    color = Black
                )

                Spacer(modifier = Modifier.height(8.dp))
            }

            // Navigation buttons - LARGE TOUCH TARGETS
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Previous button
                Button(
                    onClick = {
                        // Large touch target, directly call onPrev
                        onPrev()
                    },
                    enabled = !isFirstStep,
                    modifier = Modifier
                        .height(50.dp)
                        .weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = if (isFirstStep) AccentRed.copy(alpha = 0.5f) else AccentRed,
                        contentColor = White
                    ),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        text = "‹ Vorige",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.W600
                    )
                }

                // Next button
                Button(
                    onClick = {
                        // Large touch target, directly call onNext
                        onNext()
                    },
                    modifier = Modifier
                        .height(50.dp)
                        .weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = AccentGreen,
                        contentColor = White
                    ),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        text = if (isLastStep) "Klaar" else "Volgende ›",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.W600
                    )
                }
            }
        }
    }
}
