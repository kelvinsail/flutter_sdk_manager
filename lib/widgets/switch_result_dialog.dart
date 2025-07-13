import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class SwitchResultDialog extends StatefulWidget {
  final String version;
  final String sdkPath;
  final String sdkRootPath;
  final bool symbolicLinkCreated;
  final String? errorMessage;

  const SwitchResultDialog({
    super.key,
    required this.version,
    required this.sdkPath,
    required this.sdkRootPath,
    required this.symbolicLinkCreated,
    this.errorMessage,
  });

  @override
  State<SwitchResultDialog> createState() => _SwitchResultDialogState();
}

class _SwitchResultDialogState extends State<SwitchResultDialog> {
  int _selectedTabIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  widget.symbolicLinkCreated ? Icons.check_circle : Icons.info,
                  color: widget.symbolicLinkCreated ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Flutter SDK 版本切换',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 状态信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.symbolicLinkCreated 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.symbolicLinkCreated ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已切换到版本: ${widget.version}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('SDK路径: ${widget.sdkPath}'),
                  if (widget.symbolicLinkCreated) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        const Text('符号链接创建成功'),
                      ],
                    ),
                  ],
                  if (widget.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '符号链接创建失败: ${widget.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 选项卡
            Row(
              children: [
                _buildTabButton('推荐方案', 0),
                _buildTabButton('脚本方案', 1),
                _buildTabButton('手动配置', 2),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 内容区域
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildRecommendedTab(),
                  _buildScriptTab(),
                  _buildManualTab(),
                ],
              ),
            ),
            
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _openSdkDirectory,
                  child: const Text('打开SDK目录'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecommendedTab() {
    final linkPath = path.join(widget.sdkRootPath, 'current', 'bin');
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '推荐方案：符号链接',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          if (widget.symbolicLinkCreated) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                                 color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('符号链接已创建成功！'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('现在只需要将以下路径添加到系统PATH环境变量中：'),
                  const SizedBox(height: 8),
                  _buildCopyableText(linkPath),
                  const SizedBox(height: 12),
                  const Text(
                    '优势：以后每次切换版本时，符号链接会自动更新，无需重新配置PATH。',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                                 color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('符号链接创建失败'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('错误信息: ${widget.errorMessage ?? "未知错误"}'),
                  const SizedBox(height: 12),
                  const Text('可能的原因：'),
                  const Text('• 权限不足（需要管理员权限）'),
                  const Text('• 目标路径已存在'),
                  const Text('• 系统不支持符号链接'),
                  const SizedBox(height: 12),
                  const Text('建议：尝试以管理员身份运行应用程序，或使用其他切换方案。'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _runScript,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('运行切换脚本'),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          _buildPathInstructions(),
        ],
      ),
    );
  }
  
  Widget _buildScriptTab() {
    final scriptsDir = path.join(widget.sdkRootPath, 'scripts');
    final isWindows = Platform.isWindows;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '脚本方案：自动生成切换脚本',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
                     Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.blue.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(8),
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Row(
                   children: [
                     Icon(Icons.code, color: Colors.blue),
                     SizedBox(width: 8),
                     Text('切换脚本已生成'),
                   ],
                 ),
                const SizedBox(height: 12),
                Text('脚本目录: $scriptsDir'),
                const SizedBox(height: 12),
                
                if (isWindows) ...[
                  const Text('Windows 批处理脚本：'),
                  const SizedBox(height: 8),
                  _buildCopyableText('switch_to_${widget.version}.bat'),
                  const SizedBox(height: 4),
                  _buildCopyableText('switch_flutter.bat'),
                  const SizedBox(height: 12),
                  const Text('使用方法：'),
                  const Text('1. 点击下方"运行脚本"按钮'),
                  const Text('2. 或双击运行脚本文件'),
                  const Text('3. 或在命令提示符中运行脚本'),
                  const Text('4. 脚本会临时设置PATH环境变量'),
                ] else ...[
                  const Text('Unix/Linux Shell 脚本：'),
                  const SizedBox(height: 8),
                  _buildCopyableText('switch_to_${widget.version}.sh'),
                  const SizedBox(height: 12),
                  const Text('使用方法：'),
                  const Text('1. 点击下方"运行脚本"按钮'),
                  Text('2. 或在终端中运行: source ./scripts/switch_to_${widget.version}.sh'),
                  Text('3. 或者: ./scripts/switch_to_${widget.version}.sh'),
                  const Text('4. 脚本会设置当前会话的PATH环境变量'),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 运行脚本提示框
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '点击"运行脚本"按钮将在新的终端窗口中运行切换脚本，自动设置Flutter环境变量',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _runScript,
                icon: const Icon(Icons.play_arrow),
                label: const Text('运行脚本'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openScriptsDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text('打开脚本目录'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildManualTab() {
    final binPath = path.join(widget.sdkPath, 'bin');
    final isWindows = Platform.isWindows;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '手动配置：直接修改系统PATH环境变量',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Text('需要添加到PATH的路径：'),
          const SizedBox(height: 8),
          _buildCopyableText(binPath),
          const SizedBox(height: 24),
          
          if (isWindows) ...[
            const Text(
              'Windows 系统配置步骤：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStepCard([
              '右键点击"此电脑"图标',
              '选择"属性"',
              '点击"高级系统设置"',
              '在"系统属性"对话框中点击"环境变量"',
              '在"系统变量"部分找到"Path"变量',
              '点击"编辑"',
              '点击"新建"',
              '粘贴上面的路径',
              '点击"确定"保存所有更改',
            ]),
            const SizedBox(height: 16),
            const Text(
              '或者使用命令行（临时设置）：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildCopyableText('set PATH=$binPath;%PATH%'),
          ] else ...[
            const Text(
              'Unix/Linux 系统配置步骤：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStepCard([
              '打开终端',
              '编辑shell配置文件（~/.bashrc 或 ~/.zshrc）',
              '添加以下行：export PATH="$binPath:\$PATH"',
              '保存文件',
              '运行 source ~/.bashrc 或重新打开终端',
            ]),
            const SizedBox(height: 16),
            const Text(
              '或者临时设置（仅当前会话有效）：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildCopyableText('export PATH="$binPath:\$PATH"'),
          ],
          
          const SizedBox(height: 24),
          const Text(
            '验证配置：',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCopyableText('flutter --version'),
        ],
      ),
    );
  }
  
  Widget _buildCopyableText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepCard(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(step)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildPathInstructions() {
    final isWindows = Platform.isWindows;
    
    return Container(
      padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
         color: Colors.blue.withValues(alpha: 0.1),
         borderRadius: BorderRadius.circular(8),
       ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('PATH环境变量配置说明'),
            ],
          ),
          const SizedBox(height: 12),
          
          if (isWindows) ...[
            const Text('Windows 快速配置：'),
            const Text('1. 按 Win + R 打开运行对话框'),
            const Text('2. 输入 sysdm.cpl 并回车'),
            const Text('3. 点击"环境变量"按钮'),
            const Text('4. 在系统变量中找到"Path"'),
            const Text('5. 点击"编辑" > "新建"'),
            const Text('6. 粘贴上面的路径'),
          ] else ...[
            const Text('Unix/Linux 快速配置：'),
            const Text('1. 打开终端'),
            const Text('2. 编辑 ~/.bashrc 或 ~/.zshrc'),
            const Text('3. 添加 export PATH="路径:\$PATH"'),
            const Text('4. 保存并运行 source ~/.bashrc'),
          ],
        ],
      ),
    );
  }
  
  void _runScript() async {
    final scriptsDir = path.join(widget.sdkRootPath, 'scripts');
    final isWindows = Platform.isWindows;
    
    try {
      String scriptPath;
      List<String> command;
      
      if (isWindows) {
        // Windows 批处理脚本
        scriptPath = path.join(scriptsDir, 'switch_to_${widget.version}.bat');
        command = ['cmd', '/c', 'start', 'cmd', '/k', scriptPath];
      } else {
        // Unix/Linux Shell 脚本
        scriptPath = path.join(scriptsDir, 'switch_to_${widget.version}.sh');
        // 在新的终端窗口中运行脚本
        if (Platform.isMacOS) {
          command = ['open', '-a', 'Terminal', scriptPath];
        } else {
          // Linux - 尝试不同的终端
          command = ['x-terminal-emulator', '-e', 'bash', scriptPath];
        }
      }
      
      // 检查脚本文件是否存在
      final scriptFile = File(scriptPath);
      if (!scriptFile.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('脚本文件不存在: $scriptPath'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // 运行脚本
      final process = await Process.start(
        command[0],
        command.sublist(1),
        workingDirectory: scriptsDir,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWindows 
              ? '脚本正在新的命令提示符窗口中运行...' 
              : '脚本正在新的终端窗口中运行...'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // 等待进程结束（但不阻塞UI）
      process.exitCode.then((exitCode) {
        if (exitCode != 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('脚本运行可能失败，退出码: $exitCode'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('运行脚本失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _openSdkDirectory() async {
    try {
      final isWindows = Platform.isWindows;
      
      if (isWindows) {
        await Process.run('explorer', [widget.sdkPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [widget.sdkPath]);
      } else {
        // Linux
        await Process.run('xdg-open', [widget.sdkPath]);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已打开SDK目录'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开SDK目录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _openScriptsDirectory() async {
    try {
      final scriptsDir = path.join(widget.sdkRootPath, 'scripts');
      final isWindows = Platform.isWindows;
      
      if (isWindows) {
        await Process.run('explorer', [scriptsDir]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [scriptsDir]);
      } else {
        // Linux
        await Process.run('xdg-open', [scriptsDir]);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已打开脚本目录'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开脚本目录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 