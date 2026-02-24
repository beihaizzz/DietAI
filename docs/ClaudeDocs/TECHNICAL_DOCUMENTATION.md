# DietAI 技术说明文档

## 📋 目录

1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [核心功能模块](#3-核心功能模块)
4. [数据库设计](#4-数据库设计)
5. [API接口设计](#5-api接口设计)
6. [AI Agent系统](#6-ai-agent系统)
7. [前端应用](#7-前端应用)
8. [部署架构](#8-部署架构)
9. [技术栈详情](#9-技术栈详情)
10. [开发指南](#10-开发指南)

---

## 1. 项目概述

### 1.1 项目定位

**DietAI** 是一个基于人工智能的智能饮食健康管理系统，旨在通过计算机视觉和自然语言处理技术，帮助用户科学管理饮食、追踪营养摄入、实现健康目标。

### 1.2 核心价值

- **AI图像识别**: 拍照即可识别食物类型和估算营养成分
- **智能营养分析**: 基于LangGraph的多步骤分析工作流
- **个性化建议**: 根据用户健康目标和身体状况定制营养方案
- **实时对话**: AI营养师24/7在线咨询
- **数据可视化**: 营养趋势分析和健康评分

### 1.3 技术特点

- **前后端分离**: FastAPI后端 + Flutter跨平台移动端
- **AI驱动**: 集成OpenAI GPT-4、阿里Qwen等多模态大模型
- **流式响应**: SSE (Server-Sent Events) 实现实时分析反馈
- **RAG增强**: 向量数据库检索营养知识库
- **微服务架构**: Docker容器化部署，易扩展
- **生产级别**: 完整的认证、缓存、错误处理机制

---

## 2. 技术架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   认证   │  │ 食物识别 │  │ AI对话   │  │ 健康报告 │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP/REST API
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   FastAPI Backend (Port 8000)                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  API Routers Layer                                    │  │
│  │  Auth │ User │ Food │ Health │ Chat │ Analysis       │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌─────────────────┴────────────────┐                      │
│  │      Business Logic Layer         │                      │
│  │  Services, Utils, Cache           │                      │
│  └─────────────────┬────────────────┘                      │
│                     │                                        │
│  ┌─────────────────┴────────────────┐                      │
│  │      Data Access Layer            │                      │
│  │  SQLAlchemy ORM, Models           │                      │
│  └──────────────────────────────────┘                      │
└─────────────────┬──────────────┬─────────┬─────────────────┘
                  │              │         │
        ┌─────────▼────┐  ┌─────▼────┐  ┌▼────────┐
        │ PostgreSQL    │  │  Redis   │  │  MinIO  │
        │   (主数据库)  │  │  (缓存)  │  │ (存储)  │
        └──────────────┘  └──────────┘  └─────────┘
                  │
        ┌─────────▼──────────────────────────────────────┐
        │    LangGraph AI Agent System (Port 2024)       │
        │  ┌──────────────────┐  ┌──────────────────┐   │
        │  │ Nutrition Agent  │  │   Chat Agent     │   │
        │  │ (图片分析流程)   │  │  (对话流程)     │   │
        │  └─────────┬────────┘  └─────────┬────────┘   │
        │            │                      │             │
        │  ┌─────────▼──────────────────────▼────────┐  │
        │  │  OpenAI GPT-4 / Qwen / Claude Models   │  │
        │  └──────────────────────────────────────────┘  │
        │  ┌──────────────────────────────────────────┐  │
        │  │  Chroma Vector Store (营养知识库)        │  │
        │  └──────────────────────────────────────────┘  │
        └────────────────────────────────────────────────┘
```

### 2.2 数据流向

#### 食物分析流程

```
User拍照 → Flutter上传 → FastAPI接收
  → 存储到MinIO → 调用LangGraph Agent
  → 视觉模型识别 → 提取营养成分 → RAG检索知识
  → 生成建议 → SSE流式返回 → 保存数据库 → 缓存Redis
```

#### AI对话流程

```
User发送消息 → FastAPI接收 → 创建会话
  → 调用Chat Agent → 加载用户上下文
  → 分析意图 → 生成回复 → SSE流式返回
  → 保存对话历史 → 缓存上下文
```

### 2.3 技术分层

| 层级 | 技术组件 | 职责 |
|------|----------|------|
| **表现层** | Flutter + Riverpod | UI渲染、状态管理、用户交互 |
| **API网关层** | FastAPI Routers | 路由分发、参数验证、响应格式化 |
| **业务逻辑层** | Services, Utils | 业务规则、权限控制、数据转换 |
| **AI决策层** | LangGraph Agents | 多步骤工作流、模型调用、知识检索 |
| **数据访问层** | SQLAlchemy ORM | CRUD操作、事务管理、关系映射 |
| **数据存储层** | PostgreSQL, Redis, MinIO | 持久化、缓存、对象存储 |
| **基础设施层** | Docker Compose | 容器编排、网络隔离、服务发现 |

---

## 3. 核心功能模块

### 3.1 用户认证与授权模块

**文件位置**: `routers/auth_router.py`, `shared/utils/auth.py`

**功能点**:
- 用户注册与邮箱验证
- 密码加密 (bcrypt, 12轮)
- JWT双令牌机制 (Access Token 30分钟 + Refresh Token 7天)
- Token自动刷新
- 密码修改与找回

**技术实现**:
```python
# JWT Payload结构
{
    "sub": "user_id",           # 用户ID
    "username": "string",       # 用户名
    "exp": 1234567890,          # 过期时间
    "type": "access|refresh"    # 令牌类型
}
```

**安全措施**:
- 密码强度验证 (最短8位, 必须包含字母和数字)
- 防暴力破解 (失败次数限制)
- Token黑名单机制
- HTTPS传输加密

### 3.2 食物识别与营养分析模块

**文件位置**: `routers/food_router.py`, `agent/agent.py`

**核心API**:
- `POST /api/foods/records` - 创建食物记录并分析
- `GET /api/foods/records` - 获取历史记录
- `GET /api/foods/{id}` - 获取详情
- `GET /api/foods/nutrition/daily` - 每日营养汇总
- `GET /api/foods/nutrition/trend` - 营养趋势(7天/30天)

**分析工作流**:
```
1. state_init              初始化状态和图片数据
2. analyze_image           GPT-4 Vision识别食物
3. extract_nutrition       提取营养成分数据
4. retrieve_nutrition_knowledge    RAG检索营养知识
5. generate_dependencies   生成建议依据
6. generate_advice         生成个性化营养建议
7. format_response         格式化输出结果
```

**SSE流式输出**:
```javascript
// 前端接收事件
data: {"step": "analyze_image", "content": "正在识别食物..."}
data: {"step": "extract_nutrition", "content": "提取营养成分中..."}
data: {"step": "generate_advice", "content": "生成营养建议..."}
data: {"step": "complete", "result": {...}}
```

**营养指标**:
- 宏量营养素: 热量(kcal), 蛋白质(g), 脂肪(g), 碳水化合物(g), 膳食纤维(g), 糖(g)
- 微量营养素: 维生素A/C/D, 钙, 铁, 钠, 钾, 胆固醇
- 健康评级: E(差) → D(较差) → C(一般) → B(良好) → A(优秀)

### 3.3 健康分析模块

**文件位置**: `routers/health_router.py`

**分析维度**:

| 指标 | 计算公式 | 说明 |
|------|----------|------|
| **BMR** (基础代谢率) | 男: 10×体重 + 6.25×身高 - 5×年龄 + 5<br>女: 10×体重 + 6.25×身高 - 5×年龄 - 161 | 每日静息消耗 |
| **TDEE** (总消耗) | BMR × 活动系数(1.2-1.9) | 包含活动消耗 |
| **BMI** | 体重(kg) / 身高²(m) | 18.5-24标准 |
| **营养均衡度** | 蛋白质15-20%, 脂肪20-30%, 碳水50-65% | 宏量营养比例 |
| **健康评分** | 综合BMI、营养均衡、目标进度 | 1-5级评分 |

**个性化建议**:
- 基于健康目标调整 (减重/增重/增肌/减脂)
- 考虑疾病史和过敏史
- 参考最近饮食习惯
- 结合体重变化趋势

### 3.4 AI对话模块

**文件位置**: `routers/chat_router.py`, `agent/chat_agent.py`

**对话类型**:
1. **营养咨询** - 询问食物营养价值、饮食搭配建议
2. **健康评估** - 分析当前饮食结构、提出改进方案
3. **食物识别** - 图片问答形式的食物识别
4. **运动建议** - 根据饮食和目标推荐运动方案

**上下文管理**:
```python
{
    "user_profile": {          # 用户基本信息
        "age": 25,
        "gender": "male",
        "height": 175,
        "weight": 70,
        "activity_level": 3
    },
    "health_goals": [...],     # 健康目标
    "recent_meals": [...],     # 最近7天饮食
    "diseases": [...],         # 疾病史
    "allergies": [...]         # 过敏信息
}
```

**会话管理**:
- 每个会话关联LangGraph Thread ID
- 对话历史持久化到数据库
- 上下文缓存到Redis (过期时间30分钟)
- 支持多轮对话

### 3.5 用户档案管理模块

**文件位置**: `routers/user_router.py`, `shared/models/user_models.py`

**管理内容**:
- **基本资料**: 姓名、性别、生日、身高、体重、BMI
- **活动级别**: 久坐(1.2) → 轻度(1.375) → 中度(1.55) → 重度(1.725) → 超重度(1.9)
- **健康目标**: 减重/增重/维持/增肌/减脂, 目标值, 目标日期
- **疾病信息**: 疾病名称、严重程度、诊断日期、是否当前
- **过敏信息**: 过敏原类型、名称、严重程度、反应描述
- **体重记录**: 体重、体脂率、肌肉量、BMI、测量时间

---

## 4. 数据库设计

### 4.1 ER关系图

```
┌─────────────┐
│    Users    │
└──────┬──────┘
       │ 1
       │
       ├────────────┐
       │ 1        * │
       ▼            ▼
┌──────────────┐  ┌──────────────────┐
│UserProfile   │  │  HealthGoal      │
│(1:1)         │  │  (1:N)           │
└──────────────┘  └──────────────────┘
       │
       ├────────────┬─────────────┬──────────────┐
       │ *          │ *           │ *            │
       ▼            ▼             ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐
│FoodRecord│  │ Disease  │  │ Allergy  │  │WeightRecord│
└────┬─────┘  └──────────┘  └──────────┘  └────────────┘
     │ 1
     │ *
     ▼
┌────────────────┐
│NutritionDetail │
└────────────────┘
     │
     ▼
┌──────────────────────┐
│DailyNutritionSummary │
└──────────────────────┘

┌─────────────────────┐
│ConversationSession  │
└──────┬──────────────┘
       │ 1
       │ *
       ▼
┌─────────────────────┐
│ConversationMessage  │
└─────────────────────┘
       │ 1
       │ *
       ▼
┌─────────────────────┐
│ConversationContext  │
└─────────────────────┘
```

### 4.2 核心表结构

#### users (用户表)

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | BIGINT | 主键 | PK, AUTO_INCREMENT |
| username | VARCHAR(50) | 用户名 | UNIQUE, NOT NULL |
| email | VARCHAR(255) | 邮箱 | UNIQUE, NOT NULL |
| password_hash | VARCHAR(255) | 密码哈希 | NOT NULL |
| avatar_url | VARCHAR(500) | 头像URL | NULL |
| status | INTEGER | 状态(1=正常,2=禁用) | DEFAULT 1 |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 更新时间 | ON UPDATE NOW() |

#### user_profiles (用户资料表)

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | BIGINT | 主键 | PK |
| user_id | BIGINT | 用户ID | FK → users.id, UNIQUE |
| real_name | VARCHAR(50) | 真实姓名 | NULL |
| gender | INTEGER | 性别(1=男,2=女) | NULL |
| birth_date | DATE | 出生日期 | NULL |
| height | DECIMAL(5,2) | 身高(cm) | NULL |
| weight | DECIMAL(5,2) | 体重(kg) | NULL |
| bmi | DECIMAL(5,2) | BMI指数 | NULL |
| activity_level | INTEGER | 活动级别(1-5) | DEFAULT 3 |

#### food_records (食物记录表)

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | BIGINT | 主键 | PK |
| user_id | BIGINT | 用户ID | FK → users.id |
| record_date | DATE | 记录日期 | NOT NULL |
| meal_type | INTEGER | 餐次(1-5) | NOT NULL |
| food_name | VARCHAR(200) | 食物名称 | NOT NULL |
| portion_size | VARCHAR(50) | 份量 | NULL |
| image_url | VARCHAR(500) | 图片URL | NULL |
| analysis_status | INTEGER | 分析状态(1-4) | DEFAULT 1 |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |

**索引**:
- `idx_user_date` (user_id, record_date) - 查询用户某日记录
- `idx_user_meal` (user_id, meal_type) - 按餐次筛选

#### nutrition_details (营养详情表)

| 字段 | 类型 | 说明 | 单位 |
|------|------|------|------|
| id | BIGINT | 主键 | - |
| food_record_id | BIGINT | 食物记录ID (FK) | - |
| calories | DECIMAL(8,2) | 热量 | kcal |
| protein | DECIMAL(8,2) | 蛋白质 | g |
| fat | DECIMAL(8,2) | 脂肪 | g |
| carbohydrates | DECIMAL(8,2) | 碳水化合物 | g |
| dietary_fiber | DECIMAL(8,2) | 膳食纤维 | g |
| sugar | DECIMAL(8,2) | 糖 | g |
| vitamin_a | DECIMAL(8,2) | 维生素A | μg |
| vitamin_c | DECIMAL(8,2) | 维生素C | mg |
| vitamin_d | DECIMAL(8,2) | 维生素D | μg |
| calcium | DECIMAL(8,2) | 钙 | mg |
| iron | DECIMAL(8,2) | 铁 | mg |
| sodium | DECIMAL(8,2) | 钠 | mg |
| potassium | DECIMAL(8,2) | 钾 | mg |
| cholesterol | DECIMAL(8,2) | 胆固醇 | mg |

#### conversation_sessions (对话会话表)

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | BIGINT | 主键 | PK |
| user_id | BIGINT | 用户ID | FK → users.id |
| session_type | INTEGER | 会话类型(1-4) | NOT NULL |
| langgraph_thread_id | VARCHAR(255) | LangGraph线程ID | NULL |
| title | VARCHAR(200) | 会话标题 | NULL |
| status | INTEGER | 状态(1=active,2=ended) | DEFAULT 1 |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| last_message_at | TIMESTAMP | 最后消息时间 | NULL |

### 4.3 数据库优化

**索引策略**:
- 用户ID + 日期复合索引 (高频查询)
- 外键字段单独索引
- 状态字段索引 (用于筛选)

**分区策略**:
- 食物记录表按月分区 (record_date)
- 对话消息表按月分区 (created_at)

**归档策略**:
- 6个月前的食物记录归档到冷存储
- 3个月前的对话消息归档

---

## 5. API接口设计

### 5.1 接口规范

**请求头**:
```
Authorization: Bearer {access_token}
Content-Type: application/json
Accept: application/json
```

**统一响应格式**:
```json
{
  "success": true,
  "message": "操作成功",
  "data": {...},
  "error_code": null,
  "timestamp": "2025-01-18T10:30:00Z"
}
```

**错误响应**:
```json
{
  "success": false,
  "message": "用户不存在",
  "error_code": "USER_NOT_FOUND",
  "details": {...},
  "timestamp": "2025-01-18T10:30:00Z"
}
```

### 5.2 认证接口

#### POST /api/auth/register
**请求**:
```json
{
  "username": "string (3-50字符)",
  "email": "string (有效邮箱)",
  "password": "string (8-50字符,需包含字母和数字)"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

#### POST /api/auth/login
**请求**:
```json
{
  "username": "testuser",
  "password": "password123"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "expires_in": 1800
  }
}
```

### 5.3 食物分析接口

#### POST /api/foods/records
**请求** (multipart/form-data):
```
record_date: "2025-01-18"
meal_type: 2 (1=早餐, 2=午餐, 3=晚餐, 4=加餐, 5=夜宵)
image: <file> (支持jpg/png, 最大10MB)
food_name: "红烧肉"  (可选, AI可识别)
portion_size: "一碗" (可选)
```

**响应** (SSE流):
```
event: message
data: {"step": "analyzing", "message": "正在识别食物..."}

event: message
data: {"step": "extracting", "message": "提取营养成分..."}

event: complete
data: {
  "food_record_id": 123,
  "food_name": "红烧肉",
  "nutrition": {
    "calories": 450,
    "protein": 25,
    "fat": 30,
    ...
  },
  "advice": {
    "recommendations": ["建议减少油脂摄入", ...],
    "warnings": ["胆固醇含量较高", ...],
    "alternative_foods": ["鸡胸肉", "鱼肉"]
  },
  "health_level": 3  // C级
}
```

#### GET /api/foods/nutrition/daily
**请求参数**:
```
date: "2025-01-18" (可选, 默认今天)
```

**响应**:
```json
{
  "success": true,
  "data": {
    "summary_date": "2025-01-18",
    "total_calories": 1850,
    "total_protein": 75.5,
    "total_fat": 60.2,
    "total_carbohydrates": 220.8,
    "meal_count": 3,
    "health_level": 4,  // B级
    "target_calories": 2000,
    "completion_rate": 0.925,
    "balance_analysis": {
      "protein_percentage": 16.3,
      "fat_percentage": 29.3,
      "carbohydrate_percentage": 54.4
    }
  }
}
```

### 5.4 健康分析接口

#### POST /api/health/analysis
**请求**:
```json
{
  "analysis_type": "bmr | tdee | nutrition_balance | health_level"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "bmr": 1650.5,
    "tdee": 2558.3,
    "current_intake": 1850,
    "deficit": 708.3,
    "nutrition_balance": {
      "protein": "正常 (16.3%, 建议15-20%)",
      "fat": "正常 (29.3%, 建议20-30%)",
      "carbohydrate": "正常 (54.4%, 建议50-65%)"
    },
    "health_score": 85,
    "suggestions": [
      "继续保持当前饮食结构",
      "可适当增加蛋白质摄入"
    ]
  }
}
```

### 5.5 AI对话接口

#### POST /api/chat/send-message-stream
**请求**:
```json
{
  "session_id": 123,
  "message": "今天吃了一碗红烧肉,热量会超标吗?"
}
```

**响应** (SSE流):
```
event: message
data: {"content": "根据您的健康目标..."}

event: message
data: {"content": "红烧肉的热量约450kcal..."}

event: complete
data: {
  "message_id": 456,
  "full_response": "根据您的健康目标和今天的饮食记录，红烧肉的热量约450kcal...",
  "metadata": {
    "session_type": 1,
    "response_time": 2.3
  }
}
```

### 5.6 接口限流

| 接口类型 | 限制 |
|----------|------|
| 认证接口 | 10次/分钟/IP |
| 食物分析 | 30次/小时/用户 |
| AI对话 | 60次/小时/用户 |
| 查询接口 | 100次/分钟/用户 |

---

## 6. AI Agent系统

### 6.1 LangGraph架构

**配置文件**: `langgraph.json`
```json
{
  "graphs": {
    "nutrition_agent": "./agent/agent.py:graph",
    "chat_agent": "./agent/chat_agent.py:chat_graph"
  },
  "dependencies": ["."],
  "env": ".env"
}
```

**启动命令**:
```bash
langgraph dev --port 2024
```

**服务端点**:
- `http://127.0.0.1:2024` - LangGraph服务
- `/runs/stream` - 流式执行Agent
- `/threads/{thread_id}/state` - 获取会话状态

### 6.2 营养分析Agent (nutrition_agent)

**文件**: `agent/agent.py`

**状态图**:
```python
from langgraph.graph import StateGraph

graph = StateGraph(AgentState)
graph.add_node("state_init", state_init)
graph.add_node("analyze_image", analyze_image)
graph.add_node("extract_nutrition", extract_nutrition)
graph.add_node("retrieve_nutrition_knowledge", retrieve_nutrition_knowledge)
graph.add_node("generate_dependencies", generate_dependencies)
graph.add_node("generate_advice", generate_advice)
graph.add_node("format_response", format_response)

graph.set_entry_point("state_init")
graph.add_edge("state_init", "analyze_image")
graph.add_edge("analyze_image", "extract_nutrition")
graph.add_edge("extract_nutrition", "retrieve_nutrition_knowledge")
graph.add_edge("retrieve_nutrition_knowledge", "generate_dependencies")
graph.add_edge("generate_dependencies", "generate_advice")
graph.add_edge("generate_advice", "format_response")
graph.add_edge("format_response", END)
```

**节点功能详解**:

| 节点 | 模型 | 输入 | 输出 | 耗时 |
|------|------|------|------|------|
| **state_init** | - | image_data (base64) | 初始化状态 | <0.1s |
| **analyze_image** | GPT-4 Vision | 食物图片 | 食物描述、份量估算 | 2-3s |
| **extract_nutrition** | GPT-4 / o3-mini | 食物描述 | NutritionAnalysis结构化数据 | 2-4s |
| **retrieve_nutrition_knowledge** | Chroma Vector DB | 食物名称 | 相关营养知识文档 | 0.5-1s |
| **generate_dependencies** | GPT-4 | 营养数据+知识 | AdviceDependencies依据 | 1-2s |
| **generate_advice** | GPT-4 | 营养数据+依据+用户档案 | NutritionAdvice个性化建议 | 2-3s |
| **format_response** | - | 所有数据 | 最终响应JSON | <0.1s |

**结构化输出**:

```python
class NutritionAnalysis(BaseModel):
    food_items: List[str] = Field(description="识别到的食物列表")
    total_calories: float = Field(description="总热量(kcal)")
    macronutrients: Macronutrients
    vitamins_minerals: VitaminsMinerals
    health_level: HealthLevelEnum  # Enum: 1-5

class NutritionAdvice(BaseModel):
    recommendations: List[str] = Field(min_items=3, max_items=5)
    dietary_tips: List[str]
    warnings: List[str]
    alternative_foods: List[str]
```

### 6.3 对话Agent (chat_agent)

**文件**: `agent/chat_agent.py`

**状态图**:
```python
chat_graph = StateGraph(ChatState)
chat_graph.add_node("initialize_chat", initialize_chat)
chat_graph.add_node("analyze_context", analyze_context)
chat_graph.add_node("generate_response", generate_response)
chat_graph.add_node("format_chat_response", format_chat_response)

chat_graph.set_entry_point("initialize_chat")
chat_graph.add_edge("initialize_chat", "analyze_context")
chat_graph.add_edge("analyze_context", "generate_response")
chat_graph.add_edge("generate_response", "format_chat_response")
chat_graph.add_edge("format_chat_response", END)
```

**系统提示词模板**:
```python
CHAT_SYSTEM_PROMPT = """
你是DietAI的AI营养师，专业、友好、耐心。

用户档案:
- 年龄: {age}岁, 性别: {gender}
- 身高: {height}cm, 体重: {weight}kg, BMI: {bmi}
- 活动级别: {activity_level}
- 健康目标: {health_goals}
- 疾病史: {diseases}
- 过敏信息: {allergies}

最近饮食:
{recent_meals}

对话类型: {session_type}

回复要求:
1. 简洁专业,避免过于学术化
2. 结合用户档案提供个性化建议
3. 必要时引用营养数据支持观点
4. 关注用户安全,对疾病和过敏信息敏感
5. 鼓励健康生活方式
"""
```

### 6.4 RAG系统 (检索增强生成)

**向量数据库**: Chroma
**嵌入模型**: OpenAI text-embedding-3-small
**知识库路径**: `agent/VectorStore/`

**知识库内容**:
- 常见食物营养成分表 (10000+ 条)
- 中国居民膳食指南
- 世界卫生组织营养建议
- 食物相克与搭配知识
- 疾病饮食禁忌

**检索流程**:
```python
# 1. 向量化查询
query_embedding = embeddings.embed_query(food_name)

# 2. 相似度搜索
docs = vectorstore.similarity_search(
    food_name,
    k=5,  # 返回最相关的5个文档
    filter={"category": "nutrition"}
)

# 3. 重排序 (可选)
reranked_docs = reranker.rerank(query, docs)

# 4. 注入提示词
context = "\n".join([doc.page_content for doc in reranked_docs])
prompt = f"参考以下营养知识:\n{context}\n\n生成建议..."
```

### 6.5 模型配置

**支持的模型**:

| 用途 | 模型选项 | 配置方式 |
|------|----------|----------|
| **视觉识别** | gpt-4-vision-preview<br>qwen-vl-max | `VISION_MODEL` 环境变量 |
| **营养分析** | gpt-4-turbo<br>o3-mini<br>qwen-max | `ANALYSIS_MODEL` 环境变量 |
| **对话生成** | gpt-4-turbo<br>claude-3-opus<br>qwen-turbo | `CHAT_MODEL` 环境变量 |
| **嵌入向量** | text-embedding-3-small<br>text-embedding-3-large | `EMBEDDING_MODEL` 环境变量 |

**LRU缓存**:
```python
@lru_cache(maxsize=10)
def load_vision_model(model_name: str):
    # 缓存已加载的模型实例,避免重复初始化
    return ChatOpenAI(model=model_name)
```

### 6.6 Agent调用示例

```python
# FastAPI调用LangGraph Agent
from langgraph_sdk import get_client

client = get_client(url="http://127.0.0.1:2024")

# 创建流式运行
async for chunk in client.runs.stream(
    thread_id=thread_id,
    assistant_id="nutrition_agent",
    input={
        "image_data": base64_image,
        "user_preferences": {...}
    },
    stream_mode="updates"
):
    # 实时推送进度到前端 (SSE)
    yield f"data: {json.dumps(chunk)}\n\n"
```

---

## 7. 前端应用

### 7.1 Flutter项目结构

```
frontend_flutter/lib/
├── main.dart                      # 应用入口
├── core/                          # 核心功能
│   ├── services/
│   │   ├── api_service.dart      # HTTP客户端封装
│   │   ├── auth_service.dart     # 认证服务
│   │   └── storage_service.dart  # 本地存储
│   ├── providers/
│   │   ├── auth_provider.dart    # 认证状态
│   │   └── user_provider.dart    # 用户状态
│   └── config/
│       └── app_config.dart       # 应用配置
├── features/                      # 功能模块
│   ├── auth/                      # 认证模块
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── login_page.dart
│   │   │   │   └── register_page.dart
│   │   │   └── widgets/
│   │   └── providers/
│   ├── food/                      # 食物模块
│   │   ├── models/
│   │   │   ├── food_record.dart
│   │   │   └── nutrition_detail.dart
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── food_list_page.dart
│   │   │   │   ├── food_detail_page.dart
│   │   │   │   └── analysis_result_page.dart
│   │   │   └── widgets/
│   │   └── providers/
│   ├── camera/                    # 拍照模块
│   │   ├── presentation/
│   │   │   ├── camera_page.dart
│   │   │   └── image_preview_page.dart
│   │   └── services/
│   │       └── camera_service.dart
│   ├── chat/                      # 聊天模块
│   │   ├── models/
│   │   ├── presentation/
│   │   │   ├── chat_page.dart
│   │   │   └── widgets/
│   │   │       ├── message_bubble.dart
│   │   │       └── input_field.dart
│   │   └── providers/
│   └── health/                    # 健康模块
│       ├── models/
│       ├── presentation/
│       │   ├── health_dashboard_page.dart
│       │   └── widgets/
│       │       ├── nutrition_chart.dart
│       │       └── health_score_card.dart
│       └── providers/
├── shared/                        # 共享组件
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── loading_indicator.dart
│   │   └── error_widget.dart
│   ├── themes/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
└── routes/
    └── app_router.dart            # Go Router路由配置
```

### 7.2 核心依赖

**pubspec.yaml**:
```yaml
dependencies:
  # 状态管理
  flutter_riverpod: ^2.3.6

  # 路由导航
  go_router: ^9.0.0

  # 网络请求
  dio: ^5.2.1
  retrofit: ^4.0.1

  # 相机与图片
  camera: ^0.10.5
  image_picker: ^1.0.0
  image_cropper: ^4.0.0

  # UI组件
  fl_chart: ^0.62.0        # 图表
  cached_network_image: ^3.2.3
  shimmer: ^3.0.0          # 骨架屏

  # 本地存储
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^8.0.0

  # 工具
  intl: ^0.18.1            # 国际化
  logger: ^2.0.1           # 日志
  freezed_annotation: ^2.4.0  # 不可变类
```

### 7.3 状态管理 (Riverpod)

**示例: 食物记录提供者**:
```dart
@riverpod
class FoodRecords extends _$FoodRecords {
  @override
  Future<List<FoodRecord>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getFoodRecords();
  }

  Future<void> createRecord({
    required DateTime date,
    required int mealType,
    required File image,
    String? foodName,
  }) async {
    final apiService = ref.read(apiServiceProvider);

    // 上传并分析
    await apiService.createFoodRecord(
      date: date,
      mealType: mealType,
      image: image,
      foodName: foodName,
    );

    // 刷新列表
    ref.invalidateSelf();
  }
}
```

### 7.4 API服务封装

**Dio配置**:
```dart
class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000/api',
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor());
  }

  // SSE流式请求
  Stream<Map<String, dynamic>> createFoodRecordStream({
    required DateTime date,
    required int mealType,
    required File image,
  }) async* {
    final formData = FormData.fromMap({
      'record_date': date.toIso8601String(),
      'meal_type': mealType,
      'image': await MultipartFile.fromFile(image.path),
    });

    final response = await _dio.post(
      '/foods/records',
      data: formData,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    await for (final chunk in response.data.stream.transform(utf8.decoder)) {
      if (chunk.startsWith('data: ')) {
        final json = jsonDecode(chunk.substring(6));
        yield json;
      }
    }
  }
}
```

### 7.5 UI组件示例

**营养图表组件**:
```dart
class NutritionChart extends ConsumerWidget {
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySummary = ref.watch(dailyNutritionProvider(date));

    return dailySummary.when(
      loading: () => ShimmerLoading(),
      error: (err, stack) => ErrorWidget(error: err),
      data: (summary) => PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: summary.totalProtein * 4,
              title: '蛋白质',
              color: Colors.blue,
            ),
            PieChartSectionData(
              value: summary.totalFat * 9,
              title: '脂肪',
              color: Colors.orange,
            ),
            PieChartSectionData(
              value: summary.totalCarbohydrates * 4,
              title: '碳水',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. 部署架构

### 8.1 Docker Compose服务

**docker-compose.yml**:
```yaml
services:
  dietai-backend:          # FastAPI应用
    build: .
    ports: ["8000:8000"]
    depends_on: [postgres, redis, minio]

  postgres:                # PostgreSQL 15
    image: postgres:15-alpine
    ports: ["5432:5432"]
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./infrastructure/docker/init.sql:/docker-entrypoint-initdb.d/init.sql

  redis:                   # Redis 7
    image: redis:7-alpine
    ports: ["6379:6379"]
    command: redis-server --appendonly yes

  minio:                   # MinIO对象存储
    image: minio/minio:latest
    ports: ["9000:9000", "9001:9001"]
    command: server /data --console-address ":9001"

  nginx:                   # Nginx (生产环境)
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    profiles: [production]
```

### 8.2 网络拓扑

```
Internet
    │
    ▼
┌───────────┐
│  Nginx    │ :80/:443 (生产环境)
│ (反向代理) │
└─────┬─────┘
      │
      ▼
┌──────────────────┐
│ DietAI Backend   │ :8000
│   (FastAPI)      │
└─────┬────────────┘
      │
  ┌───┴────┬─────────┬─────────┐
  ▼        ▼         ▼         ▼
┌─────┐ ┌─────┐ ┌─────┐ ┌──────────┐
│PgSQL│ │Redis│ │MinIO│ │LangGraph │
│:5432│ │:6379│ │:9000│ │  :2024   │
└─────┘ └─────┘ └─────┘ └──────────┘
```

### 8.3 生产环境配置

**环境变量 (.env.prod)**:
```bash
# 应用配置
DIETAI_DEBUG=false
DIETAI_HOST=0.0.0.0
DIETAI_PORT=8000
DIETAI_VERSION=1.0.0

# 数据库
DIETAI_DATABASE_URL=postgresql://dietai:STRONG_PASSWORD@postgres:5432/dietai_db

# Redis
DIETAI_REDIS_HOST=redis
DIETAI_REDIS_PORT=6379
DIETAI_REDIS_PASSWORD=REDIS_STRONG_PASSWORD
DIETAI_REDIS_DB=0

# MinIO
DIETAI_MINIO_ENDPOINT=minio:9000
DIETAI_MINIO_ACCESS_KEY=MINIO_ACCESS_KEY
DIETAI_MINIO_SECRET_KEY=MINIO_SECRET_KEY
DIETAI_MINIO_SECURE=true
DIETAI_MINIO_BUCKET=dietai-bucket

# 安全
DIETAI_JWT_SECRET_KEY=ULTRA_STRONG_SECRET_KEY_CHANGE_ME
DIETAI_JWT_ALGORITHM=HS256
DIETAI_JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
DIETAI_JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
DIETAI_CORS_ORIGINS=https://dietai.example.com,https://app.dietai.com

# AI服务
DIETAI_AI_SERVICE_URL=http://langgraph:2024
OPENAI_API_KEY=sk-...
DASHSCOPE_API_KEY=sk-...  # Qwen模型

# 日志
DIETAI_LOG_LEVEL=INFO
```

### 8.4 持续部署流程

```
1. 代码推送到GitHub
    ↓
2. GitHub Actions触发
    ├── 运行pytest测试
    ├── 运行代码质量检查
    └── 构建Docker镜像
    ↓
3. 推送镜像到Registry
    ↓
4. SSH连接到生产服务器
    ↓
5. Docker Compose拉取新镜像
    ↓
6. 滚动更新服务
    ├── 停止旧容器
    ├── 运行数据库迁移
    ├── 启动新容器
    └── 健康检查
    ↓
7. 通知部署结果
```

### 8.5 监控与日志

**日志收集**:
- 应用日志: 输出到 `./logs/app.log`
- 访问日志: Nginx access.log
- 错误日志: Nginx error.log
- 数据库日志: PostgreSQL slow query log

**监控指标**:
- 服务健康: `/health` 端点
- API响应时间: `X-Process-Time` header
- 数据库连接池: SQLAlchemy statistics
- Redis缓存命中率
- MinIO存储使用量

**告警配置**:
- 服务宕机 → 邮件 + 短信
- API响应超时 (>5s) → 邮件
- 数据库连接失败 → 邮件 + 短信
- 磁盘使用超过80% → 邮件

---

## 9. 技术栈详情

### 9.1 后端技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| **Web框架** | FastAPI | 0.110+ | 高性能异步Web框架 |
| **ASGI服务器** | Uvicorn | 0.27+ | 生产级ASGI服务器 |
| **ORM** | SQLAlchemy | 2.0+ | 数据库ORM映射 |
| **数据库迁移** | Alembic | 1.13+ | 数据库版本管理 |
| **数据库驱动** | psycopg2-binary | 2.9+ | PostgreSQL驱动 |
| **密码哈希** | passlib[bcrypt] | 1.7+ | 密码加密 |
| **JWT** | python-jose | 3.3+ | JWT令牌生成 |
| **Redis客户端** | redis | 5.0+ | Redis连接 |
| **对象存储** | minio | 7.2+ | MinIO SDK |
| **HTTP客户端** | httpx | 0.28+ | 异步HTTP请求 |
| **数据验证** | pydantic | 2.0+ | 数据模型验证 |
| **配置管理** | pydantic-settings | 2.0+ | 环境变量管理 |
| **SSE** | sse-starlette | 1.6+ | 服务器推送事件 |

### 9.2 AI技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| **Agent框架** | LangGraph | 0.3.5+ | 状态图工作流 |
| **LLM框架** | LangChain | 0.3.26+ | LLM应用开发 |
| **OpenAI集成** | langchain-openai | 0.3.8+ | GPT-4调用 |
| **Anthropic集成** | langchain-anthropic | 0.3.16+ | Claude调用 |
| **Qwen集成** | langchain-qwq<br>dashscope | 0.2.0+<br>1.23+ | 阿里通义千问 |
| **向量数据库** | Chroma | - | 嵌入向量存储 |
| **LangGraph CLI** | langgraph-cli[inmem] | 0.2.10+ | Agent开发工具 |
| **LangGraph SDK** | langgraph-sdk | 0.1.0+ | Python SDK |

### 9.3 前端技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| **框架** | Flutter | 3.10+ | 跨平台UI框架 |
| **状态管理** | flutter_riverpod | 2.3+ | 响应式状态管理 |
| **路由** | go_router | 9.0+ | 声明式路由 |
| **网络请求** | dio | 5.2+ | HTTP客户端 |
| **API生成** | retrofit | 4.0+ | RESTful API封装 |
| **相机** | camera | 0.10+ | 相机功能 |
| **图片选择** | image_picker | 1.0+ | 图片选择器 |
| **图表** | fl_chart | 0.62+ | 数据可视化 |
| **缓存图片** | cached_network_image | 3.2+ | 网络图片缓存 |
| **本地存储** | shared_preferences | 2.2+ | 键值对存储 |
| **安全存储** | flutter_secure_storage | 8.0+ | 加密存储 |

### 9.4 数据存储技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| **关系数据库** | PostgreSQL | 15 | 主数据存储 |
| **缓存** | Redis | 7 | 内存缓存 |
| **对象存储** | MinIO | latest | 图片文件存储 |
| **向量存储** | Chroma | - | 嵌入向量检索 |

### 9.5 基础设施技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| **容器化** | Docker | 20+ | 应用容器化 |
| **编排** | Docker Compose | 2.0+ | 多容器编排 |
| **反向代理** | Nginx | 1.24+ | 负载均衡、HTTPS |
| **CI/CD** | GitHub Actions | - | 持续集成部署 |

---

## 10. 开发指南

### 10.1 本地开发环境搭建

#### 后端开发

```bash
# 1. 克隆项目
git clone https://github.com/yourorg/dietai.git
cd dietai

# 2. 安装uv包管理器
pip install uv

# 3. 安装依赖
uv sync

# 4. 配置环境变量
cp .env.example .env.dev
# 编辑.env.dev配置数据库、Redis等

# 5. 启动数据服务 (Docker)
docker-compose up -d postgres redis minio

# 6. 运行数据库迁移
alembic upgrade head

# 7. 启动后端服务
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 8. 启动LangGraph Agent服务
langgraph dev --port 2024
```

#### 前端开发

```bash
# 1. 进入Flutter项目
cd frontend_flutter

# 2. 获取依赖
flutter pub get

# 3. 运行代码生成
flutter packages pub run build_runner build --delete-conflicting-outputs

# 4. 运行应用
flutter run -d chrome          # Web浏览器
flutter run -d windows         # Windows桌面
flutter run                    # 连接的移动设备
```

### 10.2 数据库迁移

```bash
# 创建新迁移
alembic revision --autogenerate -m "添加新字段"

# 应用迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1

# 查看历史
alembic history
```

### 10.3 测试

```bash
# 后端测试
pytest                                    # 运行所有测试
pytest tests/test_auth.py                # 指定文件
pytest --cov=. --cov-report=html        # 覆盖率报告

# 前端测试
flutter test                              # 运行所有测试
flutter test test/widget_test.dart       # 指定文件
```

### 10.4 代码规范

**Python (后端)**:
- PEP 8代码风格
- 类型注解 (Type Hints)
- Docstring文档 (Google Style)
- 最大行长: 120字符

```python
def create_food_record(
    user_id: int,
    record_date: date,
    meal_type: int,
    image_data: bytes
) -> FoodRecord:
    """创建食物记录并分析营养成分.

    Args:
        user_id: 用户ID
        record_date: 记录日期
        meal_type: 餐次类型 (1-5)
        image_data: 图片字节数据

    Returns:
        FoodRecord: 创建的食物记录对象

    Raises:
        ValueError: 参数验证失败
        RuntimeError: AI分析失败
    """
    ...
```

**Dart (前端)**:
- Effective Dart规范
- Null Safety
- 使用const构造函数
- 最大行长: 80字符

```dart
/// 创建食物记录提供者
@riverpod
class FoodRecords extends _$FoodRecords {
  @override
  Future<List<FoodRecord>> build() async {
    return await ref.read(apiServiceProvider).getFoodRecords();
  }
}
```

### 10.5 Git工作流

```bash
# 1. 创建功能分支
git checkout -b feature/add-exercise-module

# 2. 开发并提交
git add .
git commit -m "feat: 添加运动模块"

# 3. 推送分支
git push origin feature/add-exercise-module

# 4. 创建Pull Request

# 5. Code Review通过后合并到main
```

**提交消息规范** (Conventional Commits):
- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更新
- `style`: 代码格式
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

### 10.6 常见问题

**Q: LangGraph Agent无法连接**
```bash
# 检查服务是否启动
curl http://127.0.0.1:2024/health

# 重启LangGraph服务
langgraph dev --port 2024
```

**Q: 数据库连接失败**
```bash
# 检查Docker服务
docker-compose ps

# 重启PostgreSQL
docker-compose restart postgres
```

**Q: MinIO上传失败**
```bash
# 检查MinIO控制台
open http://localhost:9001

# 检查Bucket是否存在
mc ls myminio/dietai-bucket
```

---

## 11. 附录

### 11.1 项目文件清单

**核心文件** (25个关键文件):
1. `main.py` - FastAPI应用入口
2. `routers/auth_router.py` - 认证路由
3. `routers/user_router.py` - 用户路由
4. `routers/food_router.py` - 食物路由
5. `routers/health_router.py` - 健康路由
6. `routers/chat_router.py` - 对话路由
7. `routers/analysis_chat_router.py` - 分析聊天路由
8. `agent/agent.py` - 营养分析Agent
9. `agent/chat_agent.py` - 对话Agent
10. `agent/utils/nodes.py` - Agent节点函数
11. `agent/utils/states.py` - Agent状态定义
12. `agent/utils/prompts.py` - 提示词模板
13. `shared/models/user_models.py` - 用户数据模型
14. `shared/models/food_models.py` - 食物数据模型
15. `shared/models/conversation_models.py` - 对话数据模型
16. `shared/config/settings.py` - 全局配置
17. `shared/config/redis_config.py` - Redis配置
18. `shared/config/minio_config.py` - MinIO配置
19. `shared/utils/auth.py` - 认证工具
20. `pyproject.toml` - 项目依赖
21. `docker-compose.yml` - Docker编排
22. `langgraph.json` - LangGraph配置
23. `CLAUDE.md` - 开发指南
24. `frontend_flutter/lib/main.dart` - Flutter入口
25. `frontend_flutter/pubspec.yaml` - Flutter依赖

### 11.2 性能指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| API响应时间 | <500ms | 普通查询接口 |
| 食物分析时间 | 5-10s | 包含AI模型推理 |
| 对话响应时间 | 2-5s | 流式输出首字 |
| 数据库查询 | <100ms | 单表查询 |
| 缓存命中率 | >80% | Redis缓存 |
| 并发用户 | 1000+ | 单实例支持 |

### 11.3 安全清单

- ✅ 密码bcrypt加密 (12轮)
- ✅ JWT令牌认证
- ✅ SQL注入防护 (SQLAlchemy ORM)
- ✅ XSS防护 (输入验证)
- ✅ CSRF防护 (Token验证)
- ✅ CORS配置
- ✅ HTTPS传输加密
- ✅ 敏感数据加密存储
- ✅ API限流
- ✅ 日志脱敏

### 11.4 扩展路线图

**短期** (1-3个月):
- [ ] 添加运动记录模块
- [ ] 集成可穿戴设备数据
- [ ] 优化AI模型推理速度
- [ ] 添加社交分享功能

**中期** (3-6个月):
- [ ] 多语言支持 (i18n)
- [ ] 食物数据库扩充到50000+条
- [ ] 添加食谱推荐功能
- [ ] 引入Kubernetes部署

**长期** (6-12个月):
- [ ] 构建私有化部署方案
- [ ] 训练专用营养分析模型
- [ ] 开发Web端应用
- [ ] 接入医疗机构API

---

## 总结

DietAI是一个**生产级别的AI驱动健康管理系统**,具备:
- **完整的技术栈**: 前后端分离, AI Agent, 微服务架构
- **先进的AI能力**: 多模态大模型, RAG知识检索, 流式响应
- **企业级特性**: 认证授权, 缓存策略, 错误处理, 日志监控
- **可扩展设计**: 容器化部署, 水平扩展, 模块化架构

---

**文档版本**: 1.0.0
**更新日期**: 2025-01-18
**维护团队**: DietAI Team
