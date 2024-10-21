import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fvm/model/sdk_info.dart';
import 'package:fvm/utils/sp_manager.dart';

mixin LocalSDKMixin<T extends StatefulWidget> on State<T> {
  String? sdkDirPath;
  final List<SdkInfo> sdkList = [];

  @override
  void initState() {

    super.initState();
  }

  void initData() async {
    sdkDirPath = await SpManager().getString("sdk_dir_path", defaultValue: null);
    print("initData: $sdkDirPath");
    if (sdkDirPath?.isNotEmpty == true) {
      getFlutterSDKList();
    }
  }

  ///选取文件夹路径
  void selectSDKDirPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory?.isNotEmpty == true) {
      setState(() {
        sdkDirPath = selectedDirectory;
        SpManager().setString("sdk_dir_path", selectedDirectory!);
        getFlutterSDKList();
      });
    } else {
      _showToast("路径为空");
    }
  }

  ///获取本地sdk列表
  getFlutterSDKList() async {
    try {
      print("getFlutterSDKList: $sdkDirPath");
      if (sdkDirPath?.isNotEmpty != true) {
        setState(() {
          sdkList.clear();
        });
        selectSDKDirPath();
        return;
      }

      Stream<FileSystemEntity> fileList = Directory(sdkDirPath!).list();
      List<SdkInfo> dirList = [];
      await for (FileSystemEntity fileSystemEntity in fileList) {
        if (fileSystemEntity is Directory) {
          File versionFile = File("${fileSystemEntity.path}/version");
          bool isSDK = await versionFile.exists();
          if (isSDK) {
            String version = await versionFile.readAsString();
            dirList.add(SdkInfo(version, fileSystemEntity.path,
                fileSystemEntity.path.endsWith("/flutter")));
          }
        }
      }
      setState(() {
        sdkList.clear();
        sdkList.addAll(dirList);
        if (sdkList.isNotEmpty) {
          sdkList.sort((sdk1, sdk2) {
            return sdk1.version.compareTo(sdk2.version);
          });
        }
      });
      _showToast("刷新成功");
    } catch (e) {
      //debug模式下，且未与原生混编，用SnackBar弹出一个提示
      _showToast(e.toString());
    }
  }

  _showToast(String text) {
    final snackBar = SnackBar(content: Text(text));
    // 从组件树种找到ScaffoldMessager，并用它去show一个snackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  ///切换sdk
  switchSDK(newSelected) async {
    if (sdkList[newSelected].isActive) {
      return;
    }
    for (int i = 0; i < sdkList.length; i++) {
      SdkInfo sdk = sdkList[i];
      if (sdk.isActive) {
        Directory sdkDir = Directory(sdk.path);
        sdkDir.rename("${sdk.path}_${sdk.version}");
      }
    }
    SdkInfo newSelectedSDK = sdkList[newSelected];
    Directory newSelectedSdkDir = Directory(newSelectedSDK.path);
    newSelectedSdkDir.rename(
        newSelectedSDK.path.replaceAll("_${newSelectedSDK.version}", ""));
    await getFlutterSDKList();
  }
}