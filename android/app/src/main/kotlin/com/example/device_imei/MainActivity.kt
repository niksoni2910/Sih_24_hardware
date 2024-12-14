package com.example.device_imei

import android.os.Bundle
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.util.Base64


class MainActivity : FlutterActivity() {
    private val CHANNEL = "native_ecc"

    private fun retrievePrivateKey(alias: String): String? {
        return try {
            // Load the Android Keystore
            val keyStore = KeyStore.getInstance("AndroidKeyStore")
            keyStore.load(null)

            // Retrieve the private key entry
            val privateKeyEntry = keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
            if (privateKeyEntry != null) {
                // Encode the private key in Base64
                val privateKey = privateKeyEntry.privateKey
                return Base64.getEncoder().encodeToString(privateKey.encoded)
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
}

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "generateKeyPair" -> {
                    val keyPair = generateECCKeyPair()
                    if (keyPair != null) {
                        val publicKey = Base64.getEncoder().encodeToString(keyPair.public.encoded)
                        val privateKey = retrievePrivateKey("my_ec_key_pair")
                        result.success(mapOf("publicKey" to publicKey))

                        if (privateKey != null) {
                            result.success(mapOf("publicKey" to publicKey, "privateKey" to privateKey))
                        } else {
                            result.error("ERROR", "Failed to retrieve private key", null)
                        }
                    } else {
                        result.error("ERROR", "Key generation failed", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun generateECCKeyPair(): KeyPair? {
        return try {
            // Initialize KeyPairGenerator with Elliptic Curve (EC) algorithm and AndroidKeyStore provider
            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC,
                "AndroidKeyStore"
            )

            // Define the parameters for the key generation
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                "my_ec_key_pair", // Alias for the key pair
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
            ).run {
                setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
                setUserAuthenticationRequired(false) // Set to true if user authentication is required

                setIsStrongBoxBacked(true) // Use StrongBox if available (optional)
                build()
            }

            // Initialize the KeyPairGenerator with the specified parameters
            keyPairGenerator.initialize(keyGenParameterSpec)

            // Generate the key pair
            keyPairGenerator.genKeyPair()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
}
}