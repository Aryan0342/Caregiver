package com.je_dag_in_beeld.caregiver.wear

data class PictogramStep(
    val index: Int,
    val keyword: String,
    val imageUrl: String
)

data class SessionState(
    val isActive: Boolean = false,
    val setName: String = "",
    val currentIndex: Int = 0,
    val totalSteps: Int = 0,
    val steps: List<PictogramStep> = emptyList(),
    val userId: String = ""
)
