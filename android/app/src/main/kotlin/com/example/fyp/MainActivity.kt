/*
package com.example.fyp

// Old import (comment this out or remove it)
// import io.flutter.embedding.android.FlutterActivity

// New import
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity : FlutterFragmentActivity() {
    // Your existing code (if any)
}
*/

package com.example.fyp

import android.os.Build
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Creating a notification channel for Android versions O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "drowsiness_detection_service", // Channel ID must match the ID in your initializeService()
                "Drowsiness Detection Service",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            channel.description = "Notification channel for Drowsiness Detection Service"

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}

