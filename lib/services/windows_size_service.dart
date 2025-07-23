import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'package:window_size/window_size.dart';

///桌面端窗口尺寸大小约束工具类
class WindowSizeService {
  // static const double minWidth = 600;
  // static const double minHeight = 700;

  Future<PlatformWindow> _getPlatformWindow() async {
    return await window_size.getWindowInfo();
  }

  void _setWindowSize(PlatformWindow platformWindow) {
    // final Rect frame = Rect.fromCenter(
    //   center: Offset(
    //     platformWindow.frame.center.dx,
    //     platformWindow.frame.center.dy,
    //   ),
    //   width: minWidth * 3,
    //   height: minHeight,
    // );
    //
    // window_size.setWindowFrame(frame);

    setWindowTitle(
      'Flutter Version Manager',
    );

    // /// 此处的判断是指，只要是苹果或者微软，那么设置其最大尺寸和最小尺寸， 可以另作调整
    // if (Platform.isMacOS || Platform.isWindows) {
    //   window_size.setWindowMinSize(Size(minWidth, minHeight));
    //   // window_size.setWindowMaxSize(Size(width , height ));
    // }
  }

  Future<void> initialize() async {
    PlatformWindow platformWindow = await _getPlatformWindow();

    if (platformWindow.screen != null) {
        _setWindowSize(platformWindow);
    }
  }

  void setWindowTitle(String title) {
    window_size.setWindowTitle(title);
  }
}
