import Flutter
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "native_ecc", binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }

            if call.method == "generateKeyPair" {
                do {
                    let keyPair = try self.generateECCKeyPair()
                    result(keyPair)
                } catch {
                    result(
                        FlutterError(
                            code: "UNAVAILABLE",
                            message: "Key pair generation failed.",
                            details: error.localizedDescription))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func generateECCKeyPair() throws -> [String: String] {
        let tag = "com.example.device_imei.keypair".data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false,
                kSecAttrApplicationTag as String: tag,
            ],
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw NSError(
                domain: "KeyGeneration", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get public key"])
        }

        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data?,
            let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
        else {
            throw NSError(
                domain: "KeyGeneration", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to export keys"])
        }

        return [
            "privateKey": privateKeyData.base64EncodedString(),
            "publicKey": publicKeyData.base64EncodedString(),
        ]
    }
}
