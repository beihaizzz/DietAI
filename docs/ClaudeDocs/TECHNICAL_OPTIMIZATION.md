# DietAI 技术优化方向

## 🔴 高优先级（安全 & 稳定性）

### 1. 安全漏洞修复
- **`routers/food_router.py:426`** 存在严重 Bug：
  ```python
  # 当前（错误）: user_id == User.id 逻辑永远为 True
  user = db.query(User).filter(user_id == User.id).first()
  # 应改为:
  user = db.query(User).filter(User.id == user_id).first()
  ```
- JWT 密钥、数据库密码硬编码在 `settings.py` 默认值中
- CORS 配置包含通配符 `"*"`，生产环境风险大
- 缺少登录接口的限流保护

### 2. Agent 系统错误处理
- `agent/utils/nodes.py` 中 LLM 调用缺乏 try-catch、超时和重试机制
- 模型初始化问题：`model_utils.py` 每次调用都重新加载 `.env`
- Configuration 默认值不一致（OpenAI provider 配 Qwen 模型名）

### 3. 异步代码规范化
- `food_router.py` 中 `async def` 函数内部使用同步操作
- SSE 流式响应实现复杂，缺少客户端断开处理

---

## 🟡 中优先级（可维护性）

### 4. 架构重构
当前 `food_router.py` 有 **1169 行**，职责过重，建议拆分：
```
routers/
├── food/
│   ├── records.py      # 记录的 CRUD
│   ├── nutrition.py    # 营养数据管理
│   └── analysis.py     # Agent 分析流程
```

引入服务层（Service Layer）分离业务逻辑：
```
services/
├── food_service.py
├── nutrition_service.py
└── agent_service.py
```

### 5. 测试覆盖
当前测试覆盖率约 **0%**，建议：
- 添加 Agent workflow 的单元测试
- API 端点集成测试
- 错误场景测试（Redis 断连、Agent 超时等）

### 6. 数据库改进
- 缺少 Alembic 迁移文件，Schema 变更无版本控制
- `user_models.py` 中有注释标注的字段未实际迁移
- 缺少 CHECK 约束（如 meal_type 1-5 范围）
- `DailyNutritionSummary` 可用物化视图替代，避免数据冗余

---

## 🟢 低优先级（性能优化）

### 7. 查询优化
- 存在潜在 N+1 查询问题，建议使用 `joinedload()` 预加载关联
- 连接池参数 `pool_size` 未显式配置

### 8. 缓存策略
- 缓存 Key 缺少环境隔离（dev/prod 共用命名空间）
- 缺少缓存命中率监控

### 9. 可观测性
- 添加结构化日志（JSON 格式 + Correlation ID）
- 集成 APM（如 OpenTelemetry）监控 Agent 调用耗时

---

## 建议的优先实施顺序

| 阶段 | 任务 |
|------|------|
| **Week 1** | 修复 food_router Bug、移除硬编码凭证、添加基础错误处理 |
| **Week 2** | Agent 系统增加重试/超时、实现 Rate Limiting |
| **Week 3** | 拆分 Router、添加 Service 层、编写核心测试 |
| **Week 4** | 数据库迁移规范化、缓存优化、日志体系完善 |

---

## 详细问题清单

### 关键文件问题汇总

| 文件 | 行数 | 质量 | 主要问题 | 优先级 |
|------|------|------|----------|--------|
| main.py | 228 | Good | 异常处理器过于宽泛 | Low |
| routers/food_router.py | 1,169 | Poor | 过大、流式处理复杂、存在Bug | High |
| routers/chat_router.py | 712 | Fair | 硬编码配置、无限流 | Medium |
| routers/auth_router.py | 227 | Fair | 安全措施不足 | Medium |
| shared/config/settings.py | 170 | Fair | 暴露凭证、验证不足 | High |
| agent/utils/nodes.py | 361 | Poor | 无错误处理、硬编码配置 | High |
| agent/common_utils/model_utils.py | 57 | Poor | 低效的.env加载、类型不匹配 | High |
