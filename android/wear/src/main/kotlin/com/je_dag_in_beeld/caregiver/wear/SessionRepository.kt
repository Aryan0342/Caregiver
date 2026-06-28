package com.je_dag_in_beeld.caregiver.wear

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.core.content.edit
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object SessionRepository {
    private const val TAG = "SessionRepository"
    private const val PREFS_NAME = "watch_session_prefs"
    private const val KEY_USER_ID = "user_id"

    private val _sessionState = MutableStateFlow(SessionState())
    val sessionState: StateFlow<SessionState> = _sessionState.asStateFlow()

    private lateinit var sharedPrefs: SharedPreferences
    private var firestoreListener: ListenerRegistration? = null
    private var listenerStarted = false

    fun init(context: Context) {
        Log.d(TAG, "init() called")
        sharedPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val auth = com.google.firebase.auth.FirebaseAuth.getInstance()
        if (auth.currentUser == null) {
            Log.d(TAG, "Not authenticated, signing in anonymously")
            auth.signInAnonymously()
                .addOnSuccessListener {
                    Log.d(TAG, "Anonymous auth success: ${it.user?.uid}")
                    initAfterAuth()
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Anonymous auth failed", e)
                    initAfterAuth()
                }
        } else {
            Log.d(TAG, "Already authenticated: ${auth.currentUser?.uid}")
            initAfterAuth()
        }
    }

    private fun initAfterAuth() {
        val savedUserId = sharedPrefs.getString(KEY_USER_ID, "") ?: ""
        Log.d(TAG, "initAfterAuth(): savedUserId = $savedUserId")
        _sessionState.value = _sessionState.value.copy(userId = savedUserId)
        if (savedUserId.isNotEmpty()) {
            startFirestoreListener(savedUserId)
        } else {
            FirebaseFirestore.getInstance()
                .collection("watch_sessions")
                .limit(1)
                .get()
                .addOnSuccessListener { querySnapshot ->
                    Log.d(TAG, "Watch sessions query: ${querySnapshot.documents.size} docs found")
                    if (!querySnapshot.isEmpty) {
                        val userId = querySnapshot.documents[0].id
                        Log.d(TAG, "Found userId from Firestore: $userId")
                        sharedPrefs.edit {
                            putString(KEY_USER_ID, userId)
                        }
                        _sessionState.value = _sessionState.value.copy(userId = userId)
                        startFirestoreListener(userId)
                    }
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Failed to query watch_sessions", e)
                }
        }
    }

    private fun startFirestoreListener(userId: String) {
        Log.d(TAG, "startFirestoreListener() called with userId = $userId")
        firestoreListener?.remove()
        firestoreListener = FirebaseFirestore.getInstance()
            .collection("watch_sessions")
            .document(userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e(TAG, "Firestore error: ${error.message}", error)
                    return@addSnapshotListener
                }
                if (snapshot == null || !snapshot.exists()) {
                    Log.d(TAG, "Snapshot null or doesn't exist")
                    return@addSnapshotListener
                }
                Log.d(TAG, "Snapshot exists, data=${snapshot.data}")
                val isActive = snapshot.getBoolean("isActive") ?: false
                val setName = snapshot.getString("setName") ?: ""
                val currentIndex = snapshot.getLong("currentIndex")?.toInt() ?: 0
                val totalSteps = snapshot.getLong("totalSteps")?.toInt() ?: 0
                val pictoList = snapshot.get("pictograms") as? List<Map<String, Any>> ?: emptyList()
                val pictogramSteps = pictoList.map {
                    PictogramStep(
                        index = (it["index"] as Long).toInt(),
                        keyword = it["keyword"] as String,
                        imageUrl = it["imageUrl"] as String
                    )
                }
                val newState = SessionState(
                    isActive = isActive,
                    setName = setName,
                    currentIndex = currentIndex,
                    totalSteps = totalSteps,
                    steps = pictogramSteps,
                    userId = userId
                )
                Log.d(TAG, "Updating session state to $newState")
                _sessionState.value = newState
            }
        listenerStarted = true
    }

    fun updateSession(action: String, data: SessionState) {
        Log.d(TAG, "updateSession() called with action = $action, data = $data")
        val newState = when (action) {
            "START" -> data.copy(isActive = true)
            "INDEX_CHANGE" -> {
                Log.d(TAG, "INDEX_CHANGE received: data.currentIndex=${data.currentIndex}, current state index=${_sessionState.value.currentIndex}")
                _sessionState.value.copy(currentIndex = data.currentIndex)
            }
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
            if (!listenerStarted) {
                startFirestoreListener(data.userId)
            }
        }
    }

    fun navigateToIndex(newIndex: Int) {
        val userId = _sessionState.value.userId
        if (userId.isEmpty()) {
            Log.e(TAG, "navigateToIndex: userId is empty, cannot update Firestore")
            return
        }
        val currentState = _sessionState.value
        val clampedIndex = newIndex.coerceIn(0, (currentState.totalSteps - 1).coerceAtLeast(0))
        Log.d(TAG, "navigateToIndex: updating Firestore to index=$clampedIndex")
        FirebaseFirestore.getInstance()
            .collection("watch_sessions")
            .document(userId)
            .update(
                mapOf(
                    "currentIndex" to clampedIndex,
                    "updatedAt" to com.google.firebase.Timestamp.now()
                )
            )
            .addOnSuccessListener { Log.d(TAG, "navigateToIndex: Firestore updated to $clampedIndex") }
            .addOnFailureListener { e -> Log.e(TAG, "navigateToIndex: Firestore update failed", e) }
    }
}
