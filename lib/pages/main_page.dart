import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdk_providers.dart';
import 'local_sdk_page.dart';
import 'remote_sdk_page.dart';
import 'settings_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex = 0;

  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.computer,
      label: '本地版本',
      page: const LocalSdkPage(),
    ),
    _NavigationItem(
      icon: Icons.cloud_download,
      label: '云端版本',
      page: const RemoteSdkPage(),
    ),
    _NavigationItem(
      icon: Icons.settings,
      label: '设置',
      page: const SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // 标题栏
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flutter_dash,
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'FVM-CN',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 导航列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = index == _selectedIndex;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: ListTile(
                          selected: isSelected,
                          selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          leading: Icon(
                            item.icon,
                            size: 22,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 右侧内容区域
          Expanded(
            child: Column(
              children: [
                // 内容标题栏
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _navigationItems[_selectedIndex].icon,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _navigationItems[_selectedIndex].label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // 刷新按钮
                      if (_selectedIndex != 2) // 不在设置页面时显示刷新按钮
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            // 触发对应页面的刷新
                            _refreshCurrentPage();
                          },
                          tooltip: '刷新',
                        ),
                    ],
                  ),
                ),
                // 页面内容
                Expanded(
                  child: _navigationItems[_selectedIndex].page,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshCurrentPage() {
    // 根据当前选中的页面刷新对应的数据
    switch (_selectedIndex) {
      case 0: // 本地版本页面
        ref.invalidate(localSdkProvider);
        ref.invalidate(currentSdkProvider);
        break;
      case 1: // 云端版本页面
        ref.invalidate(remoteSdkProvider);
        ref.invalidate(localSdkProvider);
        break;
      default:
        // 设置页面不需要刷新
        break;
    }
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.page,
  });
} 