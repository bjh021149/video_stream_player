// lib/widgets/shortcut_hint.dart
import 'package:flutter/material.dart';

class ShortcutHint extends StatelessWidget {
  final String keyName;
  final String description;
  
  const ShortcutHint({
    super.key,
    required this.keyName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.grey.shade600,
                width: 1,
              ),
            ),
            child: Text(
              keyName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        '键盘快捷键',
        style: TextStyle(color: Colors.white),
      ),
      content: const SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShortcutHint(keyName: '空格', description: '播放/暂停'),
            ShortcutHint(keyName: '← →', description: '快退/快进（按住3倍速）'),
            ShortcutHint(keyName: '↑ ↓', description: '音量增减'),
            ShortcutHint(keyName: 'ESC', description: '退出全屏/返回'),
            ShortcutHint(keyName: 'F11', description: '全屏切换'),
            SizedBox(height: 8),
            Divider(color: Colors.white24),
            SizedBox(height: 8),
            Text(
              '提示：也可以拖放视频文件到窗口直接播放',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}