import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceInfoService {
  static Future<String> getDeviceInfoString() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceInfo = {};

    if (Platform.isAndroid) {
      deviceInfo = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
    } else if (Platform.isIOS) {
      deviceInfo = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
    }

    return deviceInfo.entries.map((e) => '${e.value}').join();
  }

  static Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return {
      'Security Patch': build.version.securityPatch,
      'SDK Version': build.version.sdkInt,
      'Release': build.version.release,
      'Preview SDK': build.version.previewSdkInt,
      'Incremental': build.version.incremental,
      'Board': build.board,
      'Bootloader': build.bootloader,
      'Brand': build.brand,
      'Device': build.device,
      'Display': build.display,
      'Fingerprint': build.fingerprint,
      'Hardware': build.hardware,
      'Host': build.host,
      'ID': build.id,
      'Manufacturer': build.manufacturer,
      'Model': build.model,
      'Product': build.product,
      'Type': build.type,
      'Is Physical Device': build.isPhysicalDevice,
      'Serial Number': build.serialNumber,
    };
  }

  static Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return {
      'Name': data.name,
      'System Name': data.systemName,
      'System Version': data.systemVersion,
      'Model': data.model,
      'Localized Model': data.localizedModel,
      'Identifier for Vendor': data.identifierForVendor,
      'Is Physical Device': data.isPhysicalDevice,
      'System': data.utsname.sysname,
      'Node Name': data.utsname.nodename,
      'Release': data.utsname.release,
      'Version': data.utsname.version,
      'Machine': data.utsname.machine,
    };
  }
}
