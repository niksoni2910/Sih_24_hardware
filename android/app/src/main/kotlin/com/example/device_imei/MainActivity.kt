package com.example.device_imei

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.util.Base64

class MainActivity: FlutterActivity() {
    private val CHANNEL = "native_ecc"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "generateKeyPair") {
                val keyPair = generateECCKeyPair()
                if (keyPair != null) {
                    val publicKey = Base64.getEncoder().encodeToString(keyPair.public.encoded)
                    val privateKey = Base64.getEncoder().encodeToString(keyPair.private.encoded)
                    result.success(mapOf("publicKey" to publicKey, "privateKey" to privateKey))
                } else {
                    result.error("ERROR", "Key generation failed", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun generateECCKeyPair(): KeyPair? {
        return try {
            val keyPairGenerator = KeyPairGenerator.getInstance("EC")
            keyPairGenerator.initialize(256)
            keyPairGenerator.genKeyPair()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
