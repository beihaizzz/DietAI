import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../shared/presentation/widgets/app_button.dart';
import '../../../../shared/presentation/widgets/app_input.dart';
import '../../../../shared/domain/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        final authState = ref.read(authStateProvider);
        
        if (authState.hasValue && authState.value != null) {
          // 登录成功，检查引导状态
          final onboardingState = ref.read(onboardingProvider);
          
          if (onboardingState.isCompleted) {
            print('✅ 用户已完成引导，跳转到主页');
            context.go('/');
          } else {
            print('✅ 用户未完成引导，跳转到引导流程');
            context.go('/onboarding');
          }
          
          // 显示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('登录成功！'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else if (authState.hasError) {
          // 显示错误信息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      // 监听认证状态变化
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Logo和标题区域
              _buildHeader(),
              
              const SizedBox(height: 48),
              
              // 登录表单
              _buildLoginForm(),
              
              const SizedBox(height: 32),
              
              // 注册提示
              _buildRegisterPrompt(),
              
              const SizedBox(height: 16),
              
              // 临时测试按钮，用于调试引导流程
              ElevatedButton(
                onPressed: () {
                  print('📝 直接跳转到引导页面进行测试');
                  context.go('/onboarding');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
                child: Text(
                  '测试引导流程',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo容器
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🍳',
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 欢迎文案
        Text(
          '欢迎回来！',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 副标题
        Text(
          '登录您的账户继续使用',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 用户名输入框
          AppInput(
            controller: _usernameController,
            label: '用户名/邮箱',
            placeholder: '请输入用户名或邮箱',
            prefixIcon: Icons.person_outline,
            type: AppInputType.email,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入用户名或邮箱';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // 密码输入框
          AppInput(
            controller: _passwordController,
            label: '密码',
            placeholder: '请输入您的密码',
            prefixIcon: Icons.lock_outline,
            type: AppInputType.password,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密码';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // 登录按钮
          AppButton(
            text: '登录',
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账户？',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.push('/register');
          },
          child: Text(
            '立即注册',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
} 