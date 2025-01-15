import "dart:io";
import "package:device_info_plus/device_info_plus.dart";

class DeviceInfo {
  static List<String> data = [];
  static DeviceInfoPlugin dInfo = DeviceInfoPlugin();

  static Future<List<String>> getDeviceInfo() async {
    if (Platform.isWindows) {
      var info = await dInfo.windowsInfo;
      data = [info.deviceId, info.computerName, "windows"];
    }
    else if (Platform.isIOS) {
      var info = await dInfo.iosInfo;
      data = [info.identifierForVendor!, info.name, "ios"];
    }
    else if (Platform.isAndroid) {
      var info = await dInfo.androidInfo;
      data = ["${info.manufacturer}_${info.model}_${info.device}_${info.hardware}", info.product, "android"];
    }
    else if (Platform.isMacOS) {
      var info = await dInfo.macOsInfo;
      data = [info.systemGUID!, info.computerName, "macos"];
    }
    else {
      var info = await dInfo.linuxInfo;
      data = [info.machineId!, info.prettyName, "linux"];
    }
    return data;
  }
}