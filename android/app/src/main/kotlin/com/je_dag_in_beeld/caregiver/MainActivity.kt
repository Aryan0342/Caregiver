package com.je_dag_in_beeld.caregiver

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WatchNavigationService.methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.jedaginbeeld.wear",
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        WatchNavigationService.methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
