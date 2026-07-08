package com.je_dag_in_beeld.caregiver.wear

import android.util.Log
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class WearDataReceiver : DataClient.OnDataChangedListener {
    private val TAG = "WearDataReceiver"
    private val gson = Gson()

    fun init(context: android.content.Context) {
        SessionRepository.init(context)
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d(TAG, "onDataChanged: ${dataEvents.count} data events received")
        for (event in dataEvents) {
            Log.d(TAG, "onDataChanged: event type=${event.type}, uri=${event.dataItem.uri}")
            if (event.type == DataEvent.TYPE_CHANGED) {
                try {
                    val dataItem = event.dataItem
                    if (dataItem.uri.path == "/watch_session") {
                        val dataMap = DataMapItem.fromDataItem(dataItem).dataMap

                        val action = dataMap.getString("action") ?: ""
                        val currentIndex = dataMap.getInt("currentIndex", 0)
                        val totalSteps = dataMap.getInt("totalSteps", 0)
                        val setName = dataMap.getString("setName") ?: ""
                        val userId = dataMap.getString("userId") ?: ""
                        val pictogramsJson = dataMap.getString("pictograms") ?: "[]"

                        Log.d(TAG, "watch_session: action=$action, currentIndex=$currentIndex, totalSteps=$totalSteps")

                        val pictogramListType = object : TypeToken<List<PictogramStep>>() {}.type
                        val pictogramSteps: List<PictogramStep> = try {
                            gson.fromJson(pictogramsJson, pictogramListType)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to parse pictogramsJson", e)
                            emptyList()
                        }

                        val sessionData = SessionState(
                            setName = setName,
                            currentIndex = currentIndex,
                            totalSteps = totalSteps,
                            steps = pictogramSteps,
                            userId = userId
                        )

                        SessionRepository.updateSession(action, sessionData)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing watch_session", e)
                }
            } else if (event.type == DataEvent.TYPE_DELETED) {
                val dataItem = event.dataItem
                if (dataItem.uri.path == "/watch_session") {
                    SessionRepository.updateSession("END", SessionState())
                }
            }
        }
    }
}
