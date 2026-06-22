package com.je_dag_in_beeld.caregiver.wear

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object SessionRepository {
    private const val PREFS_NAME = "watch_session_prefs"
    private const val KEY_USER_ID = "user_id"

    private val _sessionState = MutableStateFlow(SessionState())
    val sessionState: StateFlow<SessionState> = _sessionState.asStateFlow()

    private lateinit var sharedPrefs: SharedPreferences

    fun init(context: Context) {
        sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val savedUserId = sharedPrefs.getString(KEY_USER_ID, "") ?: ""
        _sessionState.value = _sessionState.value.copy(userId = savedUserId)
    }

    fun updateSession(action: String, data: SessionState) {
        val newState = when (action) {
            "START" -> data.copy(isActive = true)
            "INDEX_CHANGE" -> _sessionState.value.copy(
                currentIndex = data.currentIndex
            )
            "END" -> _sessionState.value.copy(
                isActive = false
            )
            else -> _sessionState.value
        }

        _sessionState.value = newState

        if (data.userId.isNotEmpty()) {
            sharedPrefs.edit {
                putString(KEY_USER_ID, data.userId)
            }
        }
    }
}
