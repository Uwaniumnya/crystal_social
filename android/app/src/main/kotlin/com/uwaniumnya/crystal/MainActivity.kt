package com.uwaniumnya.crystal

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    // Spotify SDK temporarily disabled - all Spotify functionality commented out
    // This allows the app to build without the spotify_sdk dependency
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Basic Flutter activity - Spotify functionality temporarily disabled
        /*
        Spotify implementation was temporarily disabled to resolve build issues.
        
        To re-enable Spotify functionality:
        1. Uncomment spotify_sdk in pubspec.yaml
        2. Resolve the AAR compilation issues  
        3. Restore the Spotify method channel and implementation
        */
    }
}
