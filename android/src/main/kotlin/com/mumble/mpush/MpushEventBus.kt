package com.mumble.mpush

import android.os.Handler
import android.os.Looper
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData

object MpushEventBus {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val notificationArrivedLiveData = MutableLiveData<String>()

    fun notificationArrived(): LiveData<String> {
        return notificationArrivedLiveData
    }

    fun postNotificationArrived(payload: String) {
        mainHandler.post {
            notificationArrivedLiveData.value = payload
        }
    }
}
