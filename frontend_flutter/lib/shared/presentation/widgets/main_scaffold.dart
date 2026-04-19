import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/home/presentation/widgets/food_record_modal.dart';
import '../../../features/camera/presentation/pages/camera_page.dart';

/// 主脚手架组件 - 包含底部导航栏
class MainScaffold extends StatelessWidget {
  final Widget child;
  
  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
  
  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: LucideIcons.home,
                label: '首页',
                route: AppConstants.homeRoute,
                isActive: currentLocation == AppConstants.homeRoute,
              ),
              _buildNavItem(
                context,
                icon: LucideIcons.clock,
                label: '历史',
                route: AppConstants.historyRoute,
                isActive: currentLocation == AppConstants.historyRoute,
              ),
              _buildAddButton(context),
              _buildNavItem(
                context,
                icon: LucideIcons.activity,
                label: '健康',
                route: AppConstants.healthRoute,
                isActive: currentLocation == AppConstants.healthRoute,
              ),
              _buildNavItem(
                context,
                icon: LucideIcons.user,
                label: '我的',
                route: AppConstants.profileRoute,
                isActive: currentLocation == AppConstants.profileRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    final color = isActive ? AppColors.primary : AppColors.textTertiary;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppColors.primaryWithOpacity(0.1) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 创建加号按钮
  Widget _buildAddButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFoodRecordModal(context),
              borderRadius: BorderRadius.circular(28),
              child: const Icon(
                LucideIcons.plus,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '记录',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
  
  /// 显示食物记录模态框
  void _showFoodRecordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodRecordModal(
        mealName: '选择餐次',
        onRecordMethod: (method) {
          Navigator.pop(context);
          _handleRecordMethod(context, method);
        },
      ),
    );
  }
  
  /// 处理记录方法
  void _handleRecordMethod(BuildContext context, String method) {
    switch (method) {
      case 'ai_scan':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraPage(
              mealName: '食物记录',
              mealType: 1,
            ),
          ),
        );
        break;
      case 'text_describe':
        // TODO: 实现文字描述功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文字描述功能开发中...')),
        );
        break;
      case 'voice_record':
        // TODO: 实现语音记录功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音记录功能开发中...')),
        );
        break;
      case 'saved_meals':
        // TODO: 实现保存餐食功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存餐食功能开发中...')),
        );
        break;
      case 'barcode_scan':
        // TODO: 实现条形码扫描功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('条形码扫描功能开发中...')),
        );
        break;
    }
  }
} 