// lib/widgets/desktop_window_wrapper.dart
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
//import 'package:window_manager/window_manager.dart';

class DesktopWindowWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  
  const DesktopWindowWrapper({
    super.key,
    required this.child,
    this.title = '视频播放器',
  });

  @override
  Widget build(BuildContext context) {
    // 检查是否在桌面平台
    if (Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      return WindowBorder(
        color: Colors.black,
        width: 1,
        child: Scaffold(
          body: Column(
            children: [
              // 自定义标题栏
              WindowTitleBarBox(
                child: Row(
                  children: [
                    Expanded(
                      child: MoveWindow(
                        child: Container(
                          height: 32,
                          color: Colors.grey.shade900,
                          padding: const EdgeInsets.only(left: 16),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const WindowButtons(),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }
    
    // 非桌面平台直接返回child
    return child;
  }
}

// 窗口按钮组件
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(),
        MaximizeWindowButton(),
        CloseWindowButton(),
      ],
    );
  }
}