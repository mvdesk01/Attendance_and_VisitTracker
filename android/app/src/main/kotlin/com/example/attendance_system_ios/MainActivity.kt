package com.mtech.attendance

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


// * MainActivity inherits from [FlutterFragmentActivity] instead of [FlutterActivity].
// * This is necessary if the application uses plugins that require a FragmentActivity,
// * such as local_auth or other UI-related native components.
// */
class MainActivity: FlutterFragmentActivity() {
    // Unique identifier for the MethodChannel bridge between Dart and Kotlin
    private val CHANNEL = "battery_optimization"

//     * configureFlutterEngine is called when the Flutter engine is initialized.
//     * Use this method to register platform-specific plugins and set up Method Channels.
//     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize MethodChannel to listen for calls from the Flutter side
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // Handle specific method calls defined in Dart
            if (call.method == "requestIgnoreBatteryOptimizations") {
                // Open the system intent to request exemption from battery optimization
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                val packageName = applicationContext.packageName
                if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                        Uri.parse("package:$packageName"))
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                }
                result.success(true)
            } else if (call.method == "isIgnoringBatteryOptimizations") {
                // Check whether the app is currently on the battery optimization whitelist.
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                val packageName = applicationContext.packageName
                result.success(pm.isIgnoringBatteryOptimizations(packageName))
            } else {
                result.notImplemented()
            }
        }
    }
}




/*import android.annotation.SuppressLint
import io.flutter.embedding.android.FlutterActivity*/

/*    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }*/

/*    override fun onPause() {
        super.onPause()
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onResume() {
        super.onResume()
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }*/

   /* private val CHANNEL = "com.flutter_attendance/play_integrity_check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                   *//* "checkAppIntegrity" -> {
                        checkAppIntegrity(result)
//                        result.success(null)
                    }*//*

                    "getIntegrityToken" -> {
                        getIntegrityToken {
                                token -> result.success(token)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @SuppressLint("NewApi")
    private fun getIntegrityToken(callback: (String?) -> Unit) {
        // Generate a secure nonce
        val nonce = generateNonce()

        val integrityManager = IntegrityManagerFactory.create(this)
        val integrityTokenRequest = IntegrityTokenRequest.builder().setNonce(nonce).build()

        // Request the IntegrityTokenResponse
        val integrityTokenResponse: Task<IntegrityTokenResponse> =
            integrityManager.requestIntegrityToken(integrityTokenRequest)

        // Handle the response
        integrityTokenResponse.addOnSuccessListener { response ->
            // Extract the token from the IntegrityTokenResponse
            val token = response.token() // Correctly extract the token
            callback(token) // Pass the token to the callback
        }.addOnFailureListener { exception ->
            // Handle the error
            callback(null) // Pass null to the callback on failure
            exception.printStackTrace() // Log the error
        }
    }

    @SuppressLint("NewApi")
    private fun generateNonce(): String {
        val randomBytes = ByteArray(32) // Generate 32 random bytes
        SecureRandom().nextBytes(randomBytes) // Fill with random values
        println("Nonce byte length: ${randomBytes.size}") // Log raw byte length

        // Encode to Base64 URL-safe string without padding
        val encodedNonce = Base64.encodeToString(randomBytes, Base64.URL_SAFE or Base64.NO_WRAP)
        println("Nonce string length: ${encodedNonce.length}") // Log Base64 string length

        return encodedNonce
    }



*//*    private fun checkAppIntegrity(result: MethodChannel.Result) {
        SafetyNet.getClient(this).attest(ByteArray(0), "AIzaSyAYQht4WuDQD-bQkisaYvTzB65gwfXz7xA")  //API Key
            .addOnSuccessListener { response ->
                var integrityToken = response.jwsResult
                if (integrityToken != null) {
                    result.success(integrityToken)
                } else {
                    result.error("ERROR", "Integrity token is null", null)
                }
            }
            .addOnFailureListener { e ->
                result.error("ERROR", "SafetyNet request failed", null)
            }
    }*/

/*import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Base64
import com.google.android.gms.tasks.Task
//import com.google.android.play.core.integrity.IntegrityManager
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import com.google.android.play.core.integrity.IntegrityTokenResponse
import java.security.SecureRandom*/