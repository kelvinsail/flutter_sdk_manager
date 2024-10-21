import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fvm/model/local_sdk_vm.dart';
import 'package:fvm/model/sdk_info.dart';
import 'package:fvm/view/local_sdk_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Version Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: const LocalSdkListPage(title: 'Flutter Version Manager'),
    );
  }
}
