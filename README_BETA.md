# DietAI - 智能饮食健康管理系统（Beta 版）

## 项目简介

DietAI 是一个基于人工智能的饮食健康管理系统，通过拍照识别食物、分析营养成分、提供个性化饮食建议，帮助用户科学管理饮食健康。

### 核心功能

- **AI 食物识别**：拍照上传食物图片，自动识别食物种类
- **营养成分分析**：精准分析食物的卡路里、蛋白质、碳水化合物、脂肪等营养成分
- **智能饮食建议**：基于用户健康目标和饮食记录，提供个性化营养建议
- **AI 营养顾问**：智能对话式营养咨询，解答饮食健康相关问题
- **饮食记录追踪**：记录每日饮食，生成营养摄入报告

### 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter 移动端应用                         │
│               (iOS / Android / Windows / Web)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI 后端服务                          │
│          /api/auth  /api/foods  /api/health  /api/chat      │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌───────────────────┐ ┌─────────────┐ ┌─────────────────┐
│  LangGraph Agent  │ │ PostgreSQL  │ │  MinIO 对象存储  │
│  (AI 分析引擎)     │ │  (数据存储)  │ │   (图片存储)     │
└───────────────────┘ └─────────────┘ └─────────────────┘
         │
         ▼
┌───────────────────┐ ┌─────────────┐
│  ChromaDB 向量库   │ │    Redis    │
│  (营养知识检索)    │ │   (缓存)    │
└───────────────────┘ └─────────────┘
```

---

## 快速开始

### 系统要求

- **Docker Desktop** (v20.10+) 或 Docker Engine + Docker Compose
- **至少 4GB 可用内存**
- **网络连接**（用于调用 AI API）

### 一、配置环境变量

1. 复制环境变量模板：

```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，填入 OpenAI API Key：

```bash
OPENAI_API_KEY=sk-your-actual-api-key-here
```

> **注意**：至少需要配置一个 AI 模型的 API Key（推荐 OpenAI）

### 二、启动服务

#### 方式一：一键启动（推荐）

```bash
# 启动所有服务
docker-compose up -d

# 查看启动状态
docker-compose ps

# 查看日志
docker-compose logs -f dietai-backend
```

#### 方式二：分步启动

```bash
# 1. 启动基础设施服务
docker-compose up -d postgres redis minio

# 2. 等待数据库就绪（约10秒）
sleep 10

# 3. 启动后端服务
docker-compose up -d dietai-backend
```

### 三、验证部署

1. **健康检查**：
```bash
curl http://localhost:8000/health
# 返回: {"status":"healthy","service":"DietAI API"}
```

2. **访问 API 文档**：
   - Swagger UI：http://localhost:8000/docs
   - ReDoc：http://localhost:8000/redoc

3. **访问 MinIO 控制台**：
   - 地址：http://localhost:9001
   - 用户名：`minioadmin`
   - 密码：`minioadmin`

### 四、启动 AI Agent 服务

AI 分析功能需要单独启动 LangGraph Agent 服务：

```bash
# 进入项目目录
cd DietAI

# 安装 Python 依赖（首次运行）
pip install uv
uv sync

# 启动 LangGraph 开发服务器
uv run langgraph dev --port 2024
```

> Agent 服务启动后，访问 http://localhost:2024 可查看 Agent 状态

---

## 服务端口说明

| 服务 | 端口 | 说明 |
|------|------|------|
| FastAPI 后端 | 8000 | REST API 服务 |
| LangGraph Agent | 2024 | AI 分析服务 |
| PostgreSQL | 5432 | 数据库 |
| Redis | 6379 | 缓存服务 |
| MinIO API | 9000 | 对象存储 API |
| MinIO Console | 9001 | 对象存储管理界面 |

---

## 前端应用

### Flutter 移动端

前端应用位于 `frontend_flutter/` 目录：

```bash
cd frontend_flutter

# 安装依赖
flutter pub get

# 生成代码
dart run build_runner build --delete-conflicting-outputs

# 运行应用
flutter run -d windows    # Windows 桌面
flutter run -d chrome     # Web 浏览器
flutter run -d android    # Android 设备
```

### 配置后端地址

编辑 `frontend_flutter/lib/config/` 中的配置文件，设置后端 API 地址：

```dart
const String apiBaseUrl = 'http://localhost:8000/api';
```

---

## API 使用示例

### 用户注册

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123", "name": "测试用户"}'
```

### 上传食物图片分析

```bash
curl -X POST http://localhost:8000/api/foods/analyze \
  -H "Authorization: Bearer <your-token>" \
  -F "image=@food_photo.jpg"
```

### AI 营养咨询

```bash
curl -X POST http://localhost:8000/api/chat/message \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "我今天应该吃什么来补充蛋白质？"}'
```

---

## 常见问题

### Q: Docker 启动失败？

```bash
# 查看详细错误日志
docker-compose logs

# 重新构建镜像
docker-compose build --no-cache

# 清理并重启
docker-compose down -v
docker-compose up -d
```

### Q: 数据库连接失败？

确保 PostgreSQL 容器正常运行：
```bash
docker-compose ps postgres
docker-compose logs postgres
```

### Q: AI 分析功能不可用？

1. 确保 LangGraph Agent 服务已启动（端口 2024）
2. 检查 `.env` 中的 `OPENAI_API_KEY` 是否正确
3. 确保网络可以访问 OpenAI API

### Q: 如何停止所有服务？

```bash
docker-compose down

# 如需清理数据
docker-compose down -v
```

---

## 项目结构

```
DietAI/
├── agent/                    # LangGraph AI Agent 系统
│   ├── agent.py             # 营养分析 Agent
│   ├── chat_agent.py        # 对话 Agent
│   ├── utils/               # Agent 工具函数
│   └── VectorStore/         # 营养知识向量库
├── routers/                  # FastAPI 路由
│   ├── auth_router.py       # 认证
│   ├── food_router.py       # 食物记录
│   ├── health_router.py     # 健康评估
│   └── chat_router.py       # AI 对话
├── shared/                   # 共享模块
│   ├── config/              # 配置
│   └── models/              # 数据模型
├── frontend_flutter/         # Flutter 前端
├── infrastructure/           # 基础设施配置
├── main.py                  # 应用入口
├── docker-compose.yml       # Docker 编排
├── Dockerfile               # 后端镜像
└── langgraph.json          # Agent 图定义
```

---

## 技术栈

### 后端
- **FastAPI** - 高性能 Web 框架
- **LangGraph** - AI Agent 编排框架
- **LangChain** - LLM 应用开发框架
- **SQLAlchemy** - ORM 数据库操作
- **PostgreSQL** - 关系型数据库
- **Redis** - 缓存服务
- **MinIO** - 对象存储
- **ChromaDB** - 向量数据库

### 前端
- **Flutter** - 跨平台 UI 框架
- **Riverpod** - 状态管理
- **Go Router** - 路由导航
- **Dio** - HTTP 客户端

### AI 模型
- **GPT-4 Vision** - 食物图像识别
- **GPT-4 / Claude** - 营养分析与建议生成
- **RAG** - 营养知识检索增强生成

---

## 开发团队

DietAI 项目组

---

## 许可证

本项目仅供比赛评审使用，未经授权不得用于商业用途。
