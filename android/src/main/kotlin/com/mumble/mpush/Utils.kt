package com.mumble.mpush

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo

class Utils {
    companion object {

        fun getApplicationName(context: Context): String? {
            val applicationInfo: ApplicationInfo = context.applicationInfo
            val stringId = applicationInfo.labelRes
            return if (stringId == 0) applicationInfo.nonLocalizedLabel.toString() else context.getString(stringId)
        }

        fun getLauncherActivity(context: Context): Intent? {
            val packageManager = context.packageManager
            return packageManager.getLaunchIntentForPackage(context.packageName)
        }

        fun getDrawableResourceId(context: Context, name: String): Int {
            return context.resources.getIdentifier(name, "drawable", context.packageName)
        }

    }
}