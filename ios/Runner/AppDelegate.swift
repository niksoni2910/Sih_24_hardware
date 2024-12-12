import Flutter
import UIKit
import Security

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "native_ecc", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "generateKeyPair" {
        let keyPair = self.generateECCKeyPair()
        result(keyPair)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func generateECCKeyPair() -> [String: String] {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
      kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: false
      ]
    ]

    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      return ["error": "Key generation failed"]
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      return ["error": "Public key generation failed"]
    }

    let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error)! as Data
    let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error)! as Data

    return [
      "privateKey": privateKeyData.base64EncodedString(),
      "publicKey": publicKeyData.base64EncodedString()
    ]
  }
}
