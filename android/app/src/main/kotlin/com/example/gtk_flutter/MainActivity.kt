package com.example.gtk_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.transistorsoft.flutter.backgroundfetch.BackgroundFetchPlugins

class MainActivity: FlutterActivity() {
        override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        BackgroundFetchPlugin.setPluginRegistrant(this)
    }
}
