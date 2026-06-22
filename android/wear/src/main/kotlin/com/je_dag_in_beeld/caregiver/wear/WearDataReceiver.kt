package com.je_dag_in_beeld.caregiver.wear

import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class WearDataReceiver : DataClient.OnDataChangedListener {

    private val gson = Gson()

    fun init(context: android.content.Context) {
        SessionRepository.init(context)
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED) {
                val dataItem = event.dataItem
                if (dataItem.uri.path == "/watch_session") {
                    val dataMap = DataMapItem.fromDataItem(dataItem).dataMap

                    val action = dataMap.getString("action") ?: ""
                    val currentIndex = dataMap.getInt("currentIndex", 0)
                    val totalSteps = dataMap.getInt("totalSteps", 0)
                    val setName = dataMap.getString("setName") ?: ""
                    val userId = dataMap.getString("userId") ?: ""
                    val pictogramsJson = dataMap.getString("pictograms") ?: "[]"

                    val pictogramListType = object : TypeToken<List<PictogramStep>>() {}.type
                    val pictogramSteps: List<PictogramStep> = try {
                        gson.fromJson(pictogramsJson, pictogramListType)
                    } catch (e: Exception) {
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
            }
        }
    }
}
