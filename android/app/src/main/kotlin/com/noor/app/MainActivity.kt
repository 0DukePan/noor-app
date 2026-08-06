package com.noor.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * 🕌 MainActivity - Main entry point for Noor app
 * 
 * Registers the AdhanMethodChannel for native adhan functionality
 */
class MainActivity : FlutterActivity() {
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Adhan Method Channel
        AdhanMethodChannel(this, flutterEngine)
    }
}
