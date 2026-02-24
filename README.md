# DietAI - 智能饮食健康管理系统

基于多模态 AI 的饮食健康管理系统。拍照识别食物、分析营养成分、提供个性化饮食建议，帮助用户科学管理日常饮食。

## 功能概览

- **AI 食物识别** - 上传食物图片，自动识别种类并分析营养成分（卡路里、蛋白质、碳水、脂肪等）
- **智能营养顾问** - 对话式 AI 助手，根据用户健康状况和饮食记录提供个性化建议
- **饮食记录追踪** - 记录每日饮食，按天/周/月生成营养摄入统计
- **健康目标管理** - 支持减重、增肌、减脂等目标设定与进度追踪
- **营养知识检索** - 基于 RAG 的营养知识库，提供专业饮食指导

## 技术架构

```
Flutter 移动端 (iOS / Android / Windows / Web)
                    |
                    v
    FastAPI 后端服务 (:8000)
    /api/auth  /api/foods  /api/health  /api/chat  /api/goals
                    |
        +-----------+-----------+
        |           |           |
        v           v           v
  LangGraph     PostgreSQL    MinIO
  Agent(:2024)  (:5432)       (:9000)
     |
     +--------+--------+
     |                  |
     v                  v
  ChromaDB           Redis
  (向量知识库)        (:6379 缓存)
```

### 后端

| 组件 | 技术 | 说明 |
|------|------|------|
| Web 框架 | FastAPI | 异步 REST API |
| ORM | SQLAlchemy 2.0 | 数据库操作 |
| 数据库 | PostgreSQL 15 | 主数据存储 |
| 缓存 | Redis 7 | 查询缓存 |
| 对象存储 | MinIO | 食物图片存储 |
| 认证 | JWT (python-jose) | Token 认证 |

### AI Agent

| 组件 | 技术 | 说明 |
|------|------|------|
| Agent 框架 | LangGraph | 多步骤 AI 工作流编排 |
| LLM 集成 | LangChain | 支持 OpenAI / Anthropic / 通义千问 |
| 向量数据库 | ChromaDB | 营养知识 RAG 检索 |
| 模型路由 | LiteLLM | 多模型统一调用 |

### 前端

| 组件 | 技术 | 说明 |
|------|------|------|
| UI 框架 | Flutter | 跨平台移动端 |
| 状态管理 | Riverpod | 响应式状态 |
| 路由 | Go Router | 声明式路由 |
| HTTP | Dio | 网络请求 |

## 项目结构

```
DietAI/
├── agent/                        # LangGraph AI Agent 系统
│   ├── agent.py                  # 营养分析 Agent (nutrition_agent)
│   ├── chat_agent.py             # 对话 Agent (chat_agent)
│   ├── enhanced_nutrition/       # 增强营养分析 Agent
│   ├── goal_tracking/            # 目标追踪 Agent
│   ├── memory/                   # 用户记忆管理
│   ├── common_utils/             # Agent 公共工具 (图片/模型/RAG/Redis)
│   ├── utils/                    # Agent 节点、状态、提示词、结构体
│   └── VectorStore/              # ChromaDB 向量知识库持久化数据
├── routers/                      # FastAPI 路由层
│   ├── auth_router.py            # 认证 (注册/登录)
│   ├── user_router.py            # 用户信息
│   ├── food_router.py            # 食物记录与分析
│   ├── health_router.py          # 健康数据统计
│   ├── goal_router.py            # 目标追踪
│   ├── chat_router.py            # AI 对话
│   └── analysis_chat_router.py   # 分析页面对话
├── shared/                       # 共享模块
│   ├── config/                   # 配置 (settings/redis/minio)
│   ├── models/                   # 数据模型 (user/food/conversation)
│   ├── services/                 # 业务服务 (agent 编排)
│   ├── tasks/                    # 后台任务 (调度/记忆事件)
│   └── utils/                    # 工具 (auth/营养计算)
├── frontend_flutter/             # Flutter 前端应用
├── infrastructure/               # 基础设施 (Docker/SQL)
├── main.py                       # FastAPI 应用入口
├── langgraph.json                # LangGraph Agent 图定义
├── docker-compose.yml            # Docker 服务编排
├── Dockerfile                    # 后端容器镜像
└── pyproject.toml                # Python 依赖管理
```

## 快速开始

### 环境要求

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) (Python 包管理器)
- Docker & Docker Compose
- Flutter 3.x (前端开发)
- 至少一个 AI 模型 API Key (OpenAI / Anthropic / 通义千问)

### 1. 克隆项目

```bash
git clone https://github.com/beihaizzz/DietAI.git
cd DietAI
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填入 AI 模型的 API Key（至少填一个）：

```bash
# 推荐 OpenAI
OPENAI_API_KEY=sk-your-key-here

# 或 Anthropic Claude
ANTHROPIC_API_KEY=your-key-here

# 或阿里通义千问
DASHSCOPE_API_KEY=your-key-here
```

后端服务使用 `.env.dev` 配置文件（环境变量前缀为 `DIETAI_`），默认值已内置于 `shared/config/settings.py`，一般无需修改。如需自定义：

```bash
# 创建 .env.dev（可选）
cp .env.example .env.dev

# 可配置项示例（均有默认值）：
DIETAI_DATABASE_URL=postgresql://postgres:123456@localhost:5432/dietai_db
DIETAI_REDIS_HOST=localhost
DIETAI_REDIS_PASSWORD=123456
DIETAI_MINIO_ENDPOINT=localhost:9090
DIETAI_AI_SERVICE_URL=http://127.0.0.1:2024
```

### 3. 启动基础设施服务

```bash
# 启动 PostgreSQL、Redis、MinIO
docker-compose up -d postgres redis minio
```

验证服务状态：

```bash
docker-compose ps
```

### 4. 启动后端服务

```bash
# 安装 Python 依赖
uv sync

# 初始化数据库表（自动在启动时执行，也可手动迁移）
uv run alembic upgrade head

# 启动后端
uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 5. 启动 AI Agent 服务

```bash
# 在另一个终端启动 LangGraph 开发服务器
uv run langgraph dev --port 2024
```

### 6. 启动前端（可选）

```bash
cd frontend_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome     # Web
flutter run -d windows    # Windows 桌面
flutter run -d android    # Android
```

前端 API 地址配置在 `frontend_flutter/lib/config/` 中，默认指向 `http://localhost:8000/api`。

### 验证部署

```bash
# 健康检查
curl http://localhost:8000/health

# 访问 API 文档
# Swagger UI: http://localhost:8000/docs
# ReDoc:      http://localhost:8000/redoc
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| FastAPI 后端 | 8000 | REST API + API 文档 |
| LangGraph Agent | 2024 | AI 分析服务 |
| PostgreSQL | 5432 | 数据库 |
| Redis | 6379 | 缓存 |
| MinIO API | 9000 | 对象存储 |
| MinIO Console | 9001 | 存储管理界面 (minioadmin/minioadmin) |

## Agent 系统

项目包含 4 个 LangGraph Agent，定义在 `langgraph.json` 中：

| Agent | 入口 | 功能 |
|-------|------|------|
| `nutrition_agent` | `agent/agent.py` | 食物图片识别 + 营养分析 + 饮食建议 |
| `enhanced_nutrition_agent` | `agent/enhanced_nutrition/` | 增强版营养分析 |
| `chat_agent` | `agent/chat_agent.py` | 对话式 AI 营养顾问 |
| `goal_tracking_agent` | `agent/goal_tracking/` | 健康目标追踪 |

调用 Agent 时可通过 `configurable` 指定模型：

```python
config = {
    "configurable": {
        "vision_model_provider": "openai",      # openai / anthropic / qwen
        "vision_model": "gpt-4.1-nano-2025-04-14",
        "analysis_model_provider": "openai",
        "analysis_model": "o3-mini-2025-01-31"
    }
}
```

## 常用开发命令

```bash
# 后端
uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000   # 启动开发服务器
uv run alembic revision --autogenerate -m "描述"                # 生成数据库迁移
uv run alembic upgrade head                                     # 执行迁移
uv run pytest                                                   # 运行测试
uv run pytest --cov=. --cov-report=html                        # 测试覆盖率

# Agent
uv run langgraph dev --port 2024                                # 启动 Agent 开发服务器

# 前端
cd frontend_flutter && flutter pub get                          # 安装依赖
dart run build_runner build --delete-conflicting-outputs        # 代码生成
flutter test                                                    # 运行测试

# Docker
docker-compose up -d postgres redis minio                       # 仅启动基础设施
docker-compose up -d                                            # 启动全部服务
docker-compose logs -f dietai-backend                           # 查看后端日志
docker-compose down                                             # 停止服务
docker-compose down -v                                          # 停止并清理数据
```

## 常见问题

**Q: AI 分析功能不可用？**
1. 确认 LangGraph Agent 服务已启动（端口 2024）
2. 确认 `.env` 中至少配置了一个有效的 API Key
3. 确认网络可以访问对应的 AI API

**Q: 数据库连接失败？**
```bash
docker-compose ps postgres          # 检查容器状态
docker-compose logs postgres        # 查看日志
```

**Q: MinIO 图片上传失败？**
- 访问 http://localhost:9001 检查 MinIO 控制台
- 默认账号密码：`minioadmin` / `minioadmin`

## 许可证

本项目仅供学习与比赛评审使用，未经授权不得用于商业用途。
