import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/local_sdk_vm.dart';
import '../model/sdk_info.dart';

///本地sdk列表
class LocalSdkListPage extends StatefulWidget {
  const LocalSdkListPage({super.key, required this.title});

  final String title;

  @override
  State<LocalSdkListPage> createState() => _LocalSdkListPageState();
}

class _LocalSdkListPageState extends State<LocalSdkListPage> with LocalSDKMixin {

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 0,
          title: Text(widget.title),
          actions: [
            InkWell(
              onTap: () {
                getFlutterSDKList();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.refresh,
                    color: Colors.white),
              ),
            )
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                selectSDKDirPath();
              },
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), child: Text("本地SDK文件夹路径：$sdkDirPath", textAlign: TextAlign.start,),),
            ),
            Container(height: 1, width: MediaQuery.of(context).size.width, color: Colors.black12,),
            Expanded(child: ListView.builder(
              itemBuilder: (context, index) {
                SdkInfo sdk = sdkList[index];
                return InkWell(
                  onDoubleTap: () {
                    switchSDK(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    height: 100,
                    child: Row(
                      children: [
                        Expanded(child: Text(sdk.version)),
                        if (sdk.isActive)
                          const Icon(
                              Icons.radio_button_checked,
                              color: Colors.blue
                          )
                      ],
                    ),
                  ),
                );
              },
              itemCount: sdkList.length,
            ))
          ],
        ));
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

}
