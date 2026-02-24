# DietAI Agent 产品优化方向

> 从用户需求和产品价值角度，分析 Agent 系统的优化思路

---

## 一、当前 Agent 能力盘点

### Nutrition Agent（核心功能）
| 阶段 | 能力 | 输出 |
|------|------|------|
| 图像分析 | 识别食物、份量、烹饪方式 | 食物描述文本 |
| 营养提取 | 卡路里、宏量营养素、微量元素 | 结构化营养数据 |
| 知识检索 | ChromaDB RAG 查询营养知识 | 相关文档片段 |
| 建议生成 | 基于用户偏好的个性化建议 | 饮食建议、替代食物 |

### Chat Agent（辅助功能）
- 营养咨询（Type 1）：饮食建议、膳食搭配
- 健康评估（Type 2）：健康状况分析、趋势评估
- 食物识别（Type 3）：图片识别、营养查询
- 运动营养（Type 4）：健身指导、运动营养

### 已有的个性化数据
- 过敏原及严重程度
- 疾病/医疗状况
- 健康目标（减重/增肌/维持）
- 对话历史
- 近期饮食记录

---

## 二、核心产品问题：从"工具"到"伙伴"

### 当前定位问题
```
当前：用户拍照 → 获得营养数据 → 结束
期望：用户设定目标 → 获得持续指导 → 达成目标 → 形成习惯
```

**核心洞察**：用户要的不是营养数据，而是**健康结果**

---

## 三、Agent 优化方向

### 方向一：目标驱动的主动式 Agent

#### 现状
- Agent 是被动响应式：用户问什么答什么
- 缺少主动推送和提醒能力

#### 优化思路
```
新增 Goal-Tracking Agent
├── 每日目标监控：追踪卡路里/蛋白质摄入进度
├── 智能提醒：接近目标时提示，超标时预警
├── 缺口分析：今天还需要多少蛋白质？推荐什么食物？
└── 周期复盘：周报/月报生成，趋势分析
```

#### 具体功能
| 功能 | 描述 | 用户价值 |
|------|------|----------|
| 每日目标仪表盘 | 基于用户目标计算每日卡路里/宏量目标 | 清晰知道每天该吃多少 |
| 实时进度追踪 | 每餐后更新剩余配额 | 即时反馈，避免超标 |
| 智能餐食建议 | "距离目标还差30g蛋白质，建议晚餐..." | 不用自己算，直接给方案 |
| 异常检测 | 连续3天蛋白质摄入不足，主动提醒 | 发现盲点，纠正习惯 |

---

### 方向二：膳食规划 Agent

#### 现状
- 只能分析已吃的食物
- 不能帮用户规划"该吃什么"

#### 优化思路
```
新增 Meal-Planning Agent
├── 每日推荐：根据目标+已吃+偏好，推荐下一餐
├── 周计划生成：7天膳食计划，考虑营养均衡
├── 食谱推荐：针对营养缺口推荐具体做法
└── 购物清单：自动生成一周采购清单
```

#### 具体功能
| 功能 | 描述 | 用户价值 |
|------|------|----------|
| "下一餐吃什么" | 基于当日缺口推荐具体食物组合 | 解决选择困难 |
| 周膳食计划 | 一键生成7天计划，可调整 | 省心省脑 |
| 智能替换 | 不喜欢某道菜？推荐同等营养价值的替代 | 灵活不死板 |
| 食材复用 | 避免食材浪费，跨餐复用食材 | 经济实惠 |

---

### 方向三：深度个性化 Agent

#### 现状
- 个性化仅限于过敏原、疾病、目标
- 不了解用户的口味偏好、生活习惯、预算等

#### 优化思路
```
增强 Personalization Engine
├── 偏好学习：从历史记录学习用户口味
├── 时间感知：工作日vs周末，早餐vs晚餐
├── 预算感知：推荐符合消费能力的方案
├── 场景感知：在家做饭 vs 外出就餐
└── 健康周期：女性经期、运动恢复期等
```

#### 数据维度扩展
```python
# 当前用户画像
user_context = {
    "allergies": [...],
    "diseases": [...],
    "health_goals": [...]
}

# 扩展后的用户画像
user_context = {
    # 基础信息
    "allergies": [...],
    "diseases": [...],
    "health_goals": [...],

    # 偏好学习
    "favorite_foods": [...],           # 高频出现的食物
    "disliked_foods": [...],           # 低评分/跳过的食物
    "cuisine_preferences": [...],       # 菜系偏好
    "spice_tolerance": "medium",        # 辣度接受度

    # 生活模式
    "meal_times": {"breakfast": "7:30", "lunch": "12:00", ...},
    "cooking_skill": "intermediate",
    "time_availability": {"weekday": "low", "weekend": "high"},
    "budget_level": "medium",

    # 健康周期
    "menstrual_cycle": {...},           # 可选
    "workout_schedule": [...],          # 运动计划
    "sleep_pattern": {...}              # 作息规律
}
```

---

### 方向四：知识增强 Agent

#### 现状
- RAG 知识库内容有限
- 建议缺乏科学依据的引用

#### 优化思路
```
增强 Knowledge System
├── 知识库扩充：营养学论文、膳食指南、食物数据库
├── 引用追溯：建议附带科学依据来源
├── 食物交互：A+B 的搭配益处/禁忌
├── 药食交互：服药期间的饮食禁忌
└── 时令推荐：当季食材、本地化建议
```

#### 知识图谱结构
```
食物节点
├── 营养成分（宏量/微量）
├── 升糖指数（GI值）
├── 抗炎指数
├── 过敏原标签
├── 食物搭配
│   ├── 协同增效（铁+维C）
│   └── 拮抗禁忌（钙+草酸）
└── 药物交互
    ├── 华法林 + 维生素K
    └── 他汀类 + 柚子
```

---

### 方向五：多模态增强 Agent

#### 现状
- 仅支持图片输入
- 不支持条形码、语音、菜单等

#### 优化思路
```
多模态输入扩展
├── 条形码扫描：预包装食品精确识别
├── 语音输入："我刚吃了一碗米饭和红烧肉"
├── 菜单识别：拍餐厅菜单，推荐健康选择
├── 食谱解析：导入食谱URL，计算营养
└── 批量识别：一张图多道菜，分别分析
```

---

### 方向六：社交与激励 Agent

#### 现状
- 纯工具属性，缺乏粘性机制
- 无社交元素

#### 优化思路
```
新增 Engagement Agent
├── 成就系统：连续打卡、营养均衡达成等徽章
├── 进度可视化：周/月营养雷达图
├── 挑战模式："7天高蛋白挑战"
├── 社区分享：健康饮食打卡圈
└── 专家连接：预约营养师咨询
```

---

## 四、Agent 工作流重构建议

### 当前工作流
```
analyze_image → extract_nutrition → retrieve_knowledge → generate_advice → format_response
```

### 建议的增强工作流
```
                                    ┌─────────────────────┐
                                    │   Goal Tracking     │
                                    │   Agent (新增)       │
                                    └──────────┬──────────┘
                                               │
┌──────────┐    ┌──────────┐    ┌──────────┐   │   ┌──────────┐    ┌──────────┐
│  Multi   │───▶│  Food    │───▶│ Nutrition│───┼──▶│ Personal │───▶│  Action  │
│  Modal   │    │  Identify│    │ Analysis │   │   │  Advice  │    │  Output  │
│  Input   │    │          │    │          │   │   │          │    │          │
└──────────┘    └──────────┘    └──────────┘   │   └──────────┘    └──────────┘
    │                                          │         │
    │           ┌──────────────────────────────┘         │
    │           │                                        │
    ▼           ▼                                        ▼
┌──────────────────────────────────────────────────────────────┐
│                    User Context Engine                        │
│  (历史记录、偏好学习、目标进度、健康周期、预算约束)              │
└──────────────────────────────────────────────────────────────┘
```

---

## 五、优先级排序

### P0 - 核心价值（MVP必备）
| 功能 | 预期效果 | 实现复杂度 |
|------|----------|------------|
| 每日目标设定 | 用户留存率 +40% | 低 |
| 实时进度追踪 | 日活提升 +30% | 中 |
| 下一餐推荐 | 使用频次 +50% | 中 |
| 营养缺口提示 | 用户满意度提升 | 低 |

### P1 - 体验提升
| 功能 | 预期效果 | 实现复杂度 |
|------|----------|------------|
| 周膳食计划 | 付费转化关键功能 | 高 |
| 偏好学习 | 推荐准确率提升 | 中 |
| 成就系统 | 长期留存提升 | 低 |
| 周报生成 | 分享传播增长 | 中 |

### P2 - 差异化功能
| 功能 | 预期效果 | 实现复杂度 |
|------|----------|------------|
| 条形码扫描 | 使用便捷性提升 | 中 |
| 药食交互警告 | 健康安全保障 | 高 |
| 食谱推荐 | 内容丰富度 | 中 |
| 社区功能 | 用户生态构建 | 高 |

---

## 六、技术实现路径

### 阶段一：目标系统（2周）
```python
# 新增 Goal Agent 节点
def calculate_daily_targets(state: AgentState) -> AgentState:
    """根据用户目标计算每日营养配额"""
    user_profile = state["user_context"]

    # 基于 Mifflin-St Jeor 公式计算 BMR
    bmr = calculate_bmr(user_profile)

    # 根据目标调整 TDEE
    tdee = adjust_for_goal(bmr, user_profile["health_goals"])

    # 分配宏量营养素比例
    macros = allocate_macros(tdee, user_profile["goal_type"])

    state["daily_targets"] = {
        "calories": tdee,
        "protein": macros["protein"],
        "carbs": macros["carbs"],
        "fat": macros["fat"]
    }
    return state

def track_progress(state: AgentState) -> AgentState:
    """追踪当日进度，计算剩余配额"""
    consumed = state["daily_consumed"]
    targets = state["daily_targets"]

    state["remaining"] = {
        "calories": targets["calories"] - consumed["calories"],
        "protein": targets["protein"] - consumed["protein"],
        # ...
    }

    # 生成智能提示
    if state["remaining"]["protein"] > 30:
        state["suggestions"].append(
            f"今日蛋白质还差 {state['remaining']['protein']}g，"
            f"建议晚餐增加鸡胸肉或豆腐"
        )

    return state
```

### 阶段二：推荐系统（3周）
```python
# 新增 Recommendation Agent
def recommend_next_meal(state: AgentState) -> AgentState:
    """基于缺口推荐下一餐"""
    remaining = state["remaining"]
    preferences = state["user_preferences"]
    meal_type = state["next_meal_type"]  # breakfast/lunch/dinner

    # 构建推荐 prompt
    prompt = f"""
    用户今日营养剩余配额:
    - 卡路里: {remaining['calories']} kcal
    - 蛋白质: {remaining['protein']}g
    - 碳水: {remaining['carbs']}g

    用户偏好:
    - 喜欢的食物: {preferences['favorites']}
    - 不喜欢的: {preferences['dislikes']}
    - 过敏原: {preferences['allergies']}

    请推荐适合{meal_type}的3个食物组合方案...
    """

    recommendations = llm.invoke(prompt)
    state["meal_recommendations"] = recommendations
    return state
```

### 阶段三：偏好学习（2周）
```python
# 偏好学习模块
def update_user_preferences(user_id: int, food_record: FoodRecord):
    """从用户行为学习偏好"""

    # 分析高频食物
    frequent_foods = analyze_food_frequency(user_id)

    # 分析时间模式
    time_patterns = analyze_meal_times(user_id)

    # 更新用户画像
    update_user_profile(user_id, {
        "learned_preferences": {
            "favorite_foods": frequent_foods[:10],
            "typical_breakfast_time": time_patterns["breakfast"],
            "preferred_cuisines": extract_cuisines(frequent_foods)
        }
    })
```

---

## 七、成功指标

| 指标 | 当前基线 | 目标 | 衡量方式 |
|------|----------|------|----------|
| 日活用户 (DAU) | - | +30% | 每日打开 App 用户数 |
| 单用户日均使用次数 | 1.2 | 3.0 | 每日记录餐食次数 |
| 7日留存率 | - | 40% | 注册7天后仍活跃 |
| 30日留存率 | - | 25% | 注册30天后仍活跃 |
| 目标达成率 | - | 60% | 达成每日目标的天数比例 |
| NPS 净推荐值 | - | 50+ | 用户调研 |

---

## 八、总结

**核心转变**：
- 从"告诉你吃了什么" → "帮你吃得更好"
- 从"被动分析工具" → "主动健康伙伴"
- 从"单次使用" → "持续陪伴"

**关键行动**：
1. 立即实现目标追踪系统，提升用户粘性
2. 开发"下一餐推荐"，解决用户核心痛点
3. 构建偏好学习引擎，提升个性化体验
4. 完善知识图谱，增强建议可信度
