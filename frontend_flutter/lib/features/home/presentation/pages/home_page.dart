import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../services/food_service.dart';
import '../../../../shared/domain/models/food_model.dart';
import '../../../../shared/domain/models/api_response.dart';
import '../../../../shared/presentation/widgets/error_handler.dart';
import '../widgets/food_record_modal.dart';
import '../../../camera/presentation/pages/camera_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import 'meal_selection_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
  double _targetCalories = 2027; // 改为可变状态
  final FoodService _foodService = FoodService();
  
  // 状态变量
  bool _isLoading = true;
  DailySummary? _dailySummary;
  List<FoodRecord> _todayRecords = [];
  
  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }
  
  Future<void> _loadDataForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      
      // 并行获取指定日期的数据
      final results = await Future.wait([
        _foodService.getDailySummary(dateString),
        _foodService.getFoodRecordsByDay(dateString),
      ]);
      
      final summaryResult = results[0] as ApiResponse<DailySummary>;
      final recordsResult = results[1] as ApiResponse<List<FoodRecord>>;
      
      if (summaryResult.success && summaryResult.data != null) {
        _dailySummary = summaryResult.data!;
      } else {
        _dailySummary = null;
      }
      
      if (recordsResult.success && recordsResult.data != null) {
        _todayRecords = recordsResult.data!;
      } else {
        _todayRecords = [];
      }
      
    } catch (e) {
      print('加载日期数据失败: $e');
      if (mounted) {
        NetworkErrorHandler.handleApiError(context, e, onRetry: () => _loadDataForDate(date));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadTodayData() async {
    await _loadDataForDate(_selectedDate);
  }
  
  Future<void> _refreshData() async {
    await _loadTodayData();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentCalories = _dailySummary?.totalCalories ?? 0.0;
    final remainingCalories = (_targetCalories - currentCalories).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildAppBar(),
            
            // 日期选择器
            _buildDateSelector(),
            
            // 主要内容区域
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 加载状态
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        // 卡路里目标卡片
                        _buildCalorieCard(remainingCalories, currentCalories),
                        
                        const SizedBox(height: 24),
                        
                        // 食物摄入部分
                        _buildFoodIntakeSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dateText = isToday 
        ? '今天' 
        : DateFormat('M月d日').format(_selectedDate);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // 标题
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          
          const Spacer(),
          
          // 右侧徽章
          Row(
            children: [
              // AI教练徽章
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(
                        sessionType: 1,
                        title: '营养顾问',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3ECC7A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.bot,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'AI教练',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // AI聊天按钮
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(
                        sessionType: 1,
                        title: 'AI助手',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2BAF74),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.messageCircle,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 通知徽章 (0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F61),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 3 - index));
          final isSelected = _isSameDay(date, _selectedDate);
          final dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              _loadDataForDate(date);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3ECC7A) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[date.weekday % 7],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieCard(int remainingCalories, double currentCalories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部信息
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '卡路里摄入',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '每日目标 ${_targetCalories.round()} kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              IconButton(
                onPressed: _showEditCalorieGoalDialog,
                icon: const Icon(LucideIcons.edit2, size: 20),
                color: Colors.grey[600],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 卡路里圆圈显示
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  // 背景圆圈
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 8,
                      ),
                    ),
                  ),
                  // 进度圆圈
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: currentCalories / _targetCalories > 1.0 
                          ? 1.0 
                          : currentCalories / _targetCalories,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        remainingCalories >= 0 
                            ? const Color(0xFF3ECC7A)
                            : Colors.orange,
                      ),
                    ),
                  ),
                  // 中心文字
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          remainingCalories >= 0 
                              ? '$remainingCalories'
                              : '${remainingCalories.abs()}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          remainingCalories >= 0 ? '剩余 kcal' : '超出 kcal',
                          style: TextStyle(
                            fontSize: 14,
                            color: remainingCalories >= 0 
                                ? Colors.grey 
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 宏观营养素卡片
          _buildMacroNutrientsCard(),
        ],
      ),
    );
  }

  Widget _buildFoodIntakeSection() {
    final meals = [
      {'name': '早餐', 'icon': LucideIcons.coffee, 'color': const Color(0xFF8B4513), 'type': 1},
      {'name': '午餐', 'icon': LucideIcons.salad, 'color': const Color(0xFF3ECC7A), 'type': 2},
      {'name': '晚餐', 'icon': LucideIcons.utensils, 'color': const Color(0xFF1E90FF), 'type': 3},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '食物摄入',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 餐次列表
        ...meals.map((meal) => _buildMealItem(
          meal['name'] as String,
          meal['icon'] as IconData,
          meal['color'] as Color,
          meal['type'] as int,
        )),
      ],
    );
  }

  Widget _buildMealItem(String name, IconData icon, Color color, int mealType) {
    // 获取该餐次的食物记录
    final mealRecords = _todayRecords.where((record) => record.mealType == mealType).toList();
    final mealCalories = mealRecords.fold<double>(
      0.0, 
      (sum, record) {
        // 优先使用 analysisResult 中的卡路里数据，如果没有则使用 nutritionDetail
        final calories = record.analysisResult?.nutritionFacts.totalCalories ?? 
                        record.nutritionDetail?.calories ?? 0.0;
        return sum + calories;
      },
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 餐次信息
          Expanded(
            child: GestureDetector(
              onTap: () => _showMealRecordsModal(name, mealType),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  
                  if (mealRecords.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.zap,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${mealCalories.round()} kcal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mealRecords.length} 项食物',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      '还没有记录',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // 记录按钮
          GestureDetector(
            onTap: () => _showFoodRecordModal(name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF5E3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: const Color(0xFF3ECC7A),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '记录',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3ECC7A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMealRecordsModal(String mealName, int mealType) {
    final mealRecords = _todayRecords.where((record) => record.mealType == mealType).toList();
    
    if (mealRecords.isEmpty) {
      _showFoodRecordModal(mealName);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 顶部拖拽指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题栏
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '$mealName记录',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showFoodRecordModal(mealName);
                    },
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('添加'),
                  ),
                ],
              ),
            ),

            // 记录列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: mealRecords.length,
                itemBuilder: (context, index) {
                  final record = mealRecords[index];
                  return _buildMealRecordItem(record);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealRecordItem(FoodRecord record) {
    final calories = record.analysisResult?.nutritionFacts.totalCalories ?? 
                    record.nutritionDetail?.calories ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // 食物图片
          if (record.imageUrl != null && record.imageUrl!.isNotEmpty)
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  record.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        LucideIcons.image,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: Icon(
                LucideIcons.utensils,
                color: Colors.grey[400],
                size: 24,
              ),
            ),

          // 食物信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.foodName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${calories.round()} kcal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editFoodRecordName(record),
                icon: const Icon(LucideIcons.edit2, size: 18),
                color: Colors.blue,
              ),
              IconButton(
                onPressed: () => _deleteFoodRecord(record),
                icon: const Icon(LucideIcons.trash2, size: 18),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editFoodRecordName(FoodRecord record) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _FoodNameDialog(
        initialValue: record.foodName,
      ),
    );

    if (result != null && result != record.foodName) {
      // TODO: 调用API更新食物记录名称
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('食物名称已更新为: $result'),
        ),
      );
      // 刷新数据
      _refreshData();
    }
  }

  Future<void> _deleteFoodRecord(FoodRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除食物记录'),
        content: Text('确定要删除"${record.foodName}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: 调用API删除记录
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('食物记录已删除')),
      );
      // 刷新数据
      _refreshData();
    }
  }

  void _showFoodRecordModal(String mealName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodRecordModal(
        mealName: mealName,
        onRecordMethod: (method) {
          Navigator.pop(context);
          _handleRecordMethod(method, mealName);
        },
      ),
    );
  }

  void _handleRecordMethod(String method, String mealName) {
    // 首先跳转到餐次选择页面（除非从特定餐次触发）
    if (mealName == '早餐' || mealName == '午餐' || mealName == '晚餐') {
      // 从特定餐次触发，直接执行对应逻辑
      final mealType = _getMealTypeFromName(mealName);
      _executeRecordMethod(method, mealName, mealType);
    } else {
      // 从底部加号触发，需要先选择餐次
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MealSelectionPage(recordMethod: method),
        ),
      ).then((result) {
        if (result != null) {
          final selectedMealName = result['mealName'] as String;
          final selectedMealType = result['mealType'] as int;
          _executeRecordMethod(method, selectedMealName, selectedMealType);
        }
      });
    }
  }

  void _executeRecordMethod(String method, String mealName, int mealType) {
    // 处理不同的记录方式
    switch (method) {
      case 'ai_scan':
        // 跳转到相机页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraPage(
              mealName: mealName,
              mealType: mealType,
            ),
          ),
        ).then((_) {
          // 当从相机页面返回时刷新数据
          _refreshData();
        });
        break;
      case 'text_describe':
        // 打开文字描述界面
        print('向AI描述餐食 - $mealName');
        break;
      case 'voice_record':
        // 打开语音记录界面
        print('语音记录 - $mealName');
        break;
      case 'saved_meals':
        // 跳转到保存的菜品界面
        Navigator.pushNamed(context, '/saved-meals');
        break;
      case 'barcode_scan':
        // 打开条形码扫描界面
        print('条形码扫描 - $mealName');
        break;
    }
  }

  int _getMealTypeFromName(String mealName) {
    switch (mealName) {
      case '早餐':
        return 1;
      case '午餐':
        return 2;
      case '晚餐':
        return 3;
      case '加餐':
        return 4;
      case '夜宵':
        return 5;
      default:
        return 1; // 默认早餐
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 显示编辑卡路里目标对话框
  Future<void> _showEditCalorieGoalDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _CalorieGoalDialog(
        initialValue: _targetCalories.round().toString(),
      ),
    );

    if (result != null) {
      setState(() {
        _targetCalories = result;
      });
      
      // TODO: 这里可以调用API保存到用户资料
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('卡路里目标已设置为 ${result.round()} kcal'),
        ),
      );
    }
  }

  Widget _buildMacroNutrientsCard() {
    final protein = _dailySummary?.totalProtein ?? 0.0;
    final carbs = _dailySummary?.totalCarbohydrates ?? 0.0;
    final fat = _dailySummary?.totalFat ?? 0.0;
    
    // 目标值（可以后续配置化）
    const targetProtein = 150.0;
    const targetCarbs = 250.0;
    const targetFat = 65.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日宏观营养素',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildNutrientProgress('蛋白质', protein, targetProtein, const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          _buildNutrientProgress('碳水化合物', carbs, targetCarbs, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildNutrientProgress('脂肪', fat, targetFat, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildNutrientProgress(String name, double current, double target, Color color) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${current.round()}g / ${target.round()}g',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 卡路里目标编辑对话框
class _CalorieGoalDialog extends StatefulWidget {
  final String initialValue;

  const _CalorieGoalDialog({required this.initialValue});

  @override
  State<_CalorieGoalDialog> createState() => _CalorieGoalDialogState();
}

class _CalorieGoalDialogState extends State<_CalorieGoalDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置每日卡路里目标'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '请输入您的每日卡路里摄入目标',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '卡路里目标',
              suffixText: 'kcal',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Text(
            '建议范围：1200-3000 kcal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value != null && value >= 800 && value <= 5000) {
              Navigator.pop(context, value);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请输入有效的卡路里值 (800-5000)'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3ECC7A),
          ),
          child: const Text(
            '保存',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// 食物名称编辑对话框
class _FoodNameDialog extends StatefulWidget {
  final String initialValue;

  const _FoodNameDialog({required this.initialValue});

  @override
  State<_FoodNameDialog> createState() => _FoodNameDialogState();
}

class _FoodNameDialogState extends State<_FoodNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑食物名称'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '食物名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            maxLength: 100,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, name);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3ECC7A),
          ),
          child: const Text(
            '保存',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}