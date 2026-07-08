package com.je_dag_in_beeld.caregiver.wear

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class SessionViewModel : ViewModel() {

    val sessionState: StateFlow<SessionState> = SessionRepository.sessionState

    init {
        viewModelScope.launch {
            sessionState.collect { state ->
                // Optional logging or side effects
            }
        }
    }
}
