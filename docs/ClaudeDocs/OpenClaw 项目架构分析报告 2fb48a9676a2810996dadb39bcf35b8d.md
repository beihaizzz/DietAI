# OpenClaw 项目架构分析报告

**分析日期**: 2026-02-02

**项目规模**: 2,518 个 TypeScript 文件, 86,196 行代码

---

## 一、项目整体结构

### 1.1 顶层目录结构

```
openclaw-main/
├── src/                    # 主源代码目录
├── apps/                   # 跨平台应用 (iOS/Android/macOS)
├── packages/               # 工作空间子包 (clawdbot, moltbot)
├── extensions/             # 插件/扩展
├── skills/                 # 技能和工具定义
├── docs/                   # 文档 (Mintlify)
├── .pi/                    # PI代理配置和提示词
├── .agent/                 # Agent工作流 (MD格式定义)
└── scripts/                # 构建脚本
```

### 1.2 src/核心模块组织

| 模块 | 文件数 | 代码行数 | 功能描述 |
| --- | --- | --- | --- |
| agents | 100+ | 12,000+ | Agent核心系统、工具集、认证 |
| memory | 20+ | 4,000+ | 长期记忆系统、向量化、搜索 |
| gateway | 30+ | 5,000+ | 网关服务、Chatbot处理 |
| cli | 50+ | 8,000+ | 命令行界面、程序入口 |
| config | 15+ | 3,000+ | 配置系统、Schema验证 |
| channels | 40+ | 6,000+ | 多渠道消息支持 |

---

## 二、MD文件长期记忆管理系统 (核心亮点)

### 2.1 核心原理

OpenClaw 使用 **Markdown 文件作为长期记忆的存储媒介**，通过向量数据库和混合搜索提供高效的记忆检索。这是项目最具特色的设计之一。

### 2.2 MD文件识别规则

记忆文件识别逻辑 (`src/memory/internal.ts`):

1. [`MEMORY.md`](http://MEMORY.md) 或 [`memory.md`](http://memory.md) (工作空间根目录)
2. `memory/*` 目录下的任何 `.md` 文件
3. 配置中 `extraPaths` 指定的 `.md` 文件

### 2.3 记忆处理流程

```
MD文件 → 分块处理 → 向量化 → SQLite数据库 → 混合搜索 → Agent查询
```

**详细步骤:**

1. **文件扫描**: 识别所有记忆文件，计算SHA256哈希用于增量更新
2. **分块处理**: 400个token为一个chunk，80个token重叠保证上下文连续
3. **向量化**: 支持 OpenAI / Gemini / 本地模型，带缓存和断路器
4. **存储**: SQLite数据库 + sqlite-vec向量扩展
5. **搜索**: 70%向量 + 30%全文的混合搜索

### 2.4 数据库Schema

```sql
-- 文件元数据
CREATE TABLE files (path, source, hash, mtimeMs);

-- 文本块
CREATE TABLE chunks (id, path, startLine, endLine, text, hash, source, model);

-- 向量存储
CREATE TABLE chunks_vec (id, embedding BLOB);

-- 全文索引
CREATE TABLE chunks_fts (path, startLine, snippet, model);

-- 嵌入缓存
CREATE TABLE embedding_cache (text_hash, provider, model, embedding);
```

### 2.5 同步策略

| 触发时机 | 描述 |
| --- | --- |
| onSessionStart | 会话开始时同步 |
| onSearch | 查询时同步 |
| watch | 文件系统监听 (debounce 1.5s) |
| interval | 定时同步 |

### 2.6 会话自动保存 (session-memory hook)

使用 `/new` 命令时:

1. 读取最近15条消息
2. LLM生成描述性slug
3. 创建 `memory/YYYY-MM-DD-{slug}.md`
4. 下次运行自动索引

---

## 三、Chatbot 实现方式

### 3.1 整体架构

```
消息输入 → 网关 → Chatbot服务 → Agent(PI) → 工具执行 → 响应
```

### 3.2 核心组件

**ChatRunState** (`gateway/server-chat.ts`):

- `registry`: 运行队列管理
- `buffers`: 流式输出缓冲
- `deltaSentAt`: 时间戳追踪
- `abortedRuns`: 中止状态追踪

### 3.3 事件类型

| 事件 | 描述 |
| --- | --- |
| chat/delta | 流式文本增量 |
| chat/done | 运行完成 |
| chat/error | 运行错误 |
| chat/tool_call | 工具调用 |
| chat/thinking | 思考过程 |

### 3.4 流式处理流程

1. 注册运行到队列
2. 缓冲流式文本
3. 定期通过WebSocket广播增量
4. 完成时出队并清理资源

---

## 四、Agent 核心代码

### 4.1 Agent 运行引擎

核心函数: `runEmbeddedPiAgent()` (`agents/pi-embedded-runner/run.ts`)

**关键参数:**

- sessionKey/sessionId: 会话标识
- message: 输入消息
- provider/model: 模型配置 (默认 anthropic/claude-opus-4-5)
- tools: Agent可用工具
- thinking: 思考深度

### 4.2 执行流程

```
1. 模型解析和验证
2. 认证处理 (auth profile)
3. 工具准备 (createOpenClawTools)
4. 消息准备 (系统提示 + 历史 + 记忆搜索)
5. Agent运行 (PI-AI SDK)
6. 故障处理 (压缩/认证重试/故障转移)
```

### 4.3 内置工具集

| 工具 | 功能 |
| --- | --- |
| Browser | 浏览器自动化 |
| Canvas | 绘制和设计 |
| Nodes | Node.js执行 |
| Cron | 定时任务 |
| Message | 消息发送 |
| TTS | 文本转语音 |
| Memory | 长期记忆搜索 |
| WebSearch | 网络搜索 |
| WebFetch | 网页获取 |
| Image | 图像处理 |

### 4.4 多Agent支持

```json
{
  "agents": {
    "list": [
      {"id": "main", "name": "主Agent", "default": true},
      {"id": "research", "name": "研究Agent"}
    ]
  }
}
```

每个Agent拥有独立的:

- 工作空间目录
- 记忆数据库
- 认证配置
- 模型设置

---

## 五、项目配置系统

### 5.1 配置文件位置

```
~/.openclaw/
├── config.json5              # 主配置文件
├── credentials/              # Web登录凭证
├── sessions/                 # Pi会话
├── agents/{agentId}/
│   ├── agent/               # Agent目录
│   ├── workspace/           # 工作空间
│   │   ├── MEMORY.md        # 长期记忆
│   │   └── memory/          # 记忆目录
│   └── auth.json            # 认证配置
└── memory/{agentId}.sqlite  # 向量DB
```

### 5.2 CLI入口 (`src/entry.ts`)

1. 环境初始化
2. Node选项处理
3. 构建CLI程序 (Commander.js)
4. 解析命令行

### 5.3 主要CLI命令

`agent`, `message`, `memory`, `config`, `gateway`, `channels`, `cron`, `nodes`, `hooks`

---

## 六、开发经验与特点总结

### 6.1 架构设计亮点

| 特点 | 描述 |
| --- | --- |
| **MD记忆系统** | 用Markdown管理长期记忆，人类可读可编辑 |
| **混合搜索** | 向量+BM25全文搜索，准确率更高 |
| **多Agent** | 支持多个独立Agent实例 |
| **模块化工具** | 插件式工具扩展 |
| **跨平台** | CLI + iOS + Android + macOS |
| **多渠道** | WhatsApp/Telegram/Discord/Slack/Signal等 |

### 6.2 关键设计模式

1. **Dependency Injection**: createDefaultDeps模式
2. **Plugin Architecture**: 扩展工具/渠道/钩子
3. **Event-Driven**: Agent事件处理
4. **Streaming**: WebSocket流式输出
5. **Circuit Breaker**: 故障转移和重试
6. **Incremental Sync**: MD文件增量索引
7. **Hook System**: 生命周期回调

### 6.3 技术栈

| 类别 | 技术 |
| --- | --- |
| 运行时 | Node.js 22+ / Bun |
| 语言 | TypeScript (ESM) |
| 数据库 | SQLite + sqlite-vec向量扩展 |
| 向量化 | OpenAI / Gemini / 本地llama |
| AI模型 | Claude / GPT / Gemini |
| 构建 | pnpm monorepo |

---

## 七、Agent开发需要关注的部分

### 7.1 长期记忆设计

- **存储格式选择**: MD vs JSON vs 数据库
- **分块策略**: chunk大小、重叠比例
- **向量化provider**: 成本 vs 质量 vs 延迟
- **混合搜索权重**: 语义 vs 关键词
- **同步策略**: 实时 vs 批量 vs 按需

### 7.2 会话管理

- **会话历史压缩**: 避免上下文溢出
- **会话持久化**: 跨重启保持状态
- **会话路由**: 多渠道映射到正确Agent

### 7.3 工具系统设计

- **工具Schema定义**: 清晰的输入输出类型
- **沙盒隔离**: 安全执行用户代码
- **超时和重试**: 处理工具执行失败
- **结果格式化**: Markdown vs Plain

### 7.4 故障处理

- **模型故障转移**: primary → fallback
- **认证失败重试**: 多auth profile
- **上下文溢出处理**: 自动压缩
- **网络错误重试**: exponential backoff

### 7.5 可观测性

- **结构化日志**: 子系统分类
- **事件追踪**: 工具调用链
- **性能指标**: 延迟、成功率

### 7.6 多Agent协作

- **Agent隔离**: 独立工作空间和记忆
- **子Agent生成**: 动态创建专用Agent
- **消息路由**: 正确分发到目标Agent

### 7.7 安全考量

- **API密钥管理**: 安全存储和轮换
- **沙盒执行**: 限制文件系统访问
- **输入验证**: 防止注入攻击
- **敏感信息过滤**: 日志脱敏

---

## 八、核心数据流图

### 8.1 消息处理流

```
用户消息 → 网关接收 → 会话路由 → Agent选择
    ↓
长期记忆搜索 → 系统提示构建 → Agent执行
    ↓
工具执行 → 响应生成 → 频道发送
```

### 8.2 长期记忆流

```
MD文件编辑 → 文件监听 → 分块 → 向量化
    ↓
SQLite存储 (chunks_vec + chunks_fts)
    ↓
Agent查询 → 混合排序 → 注入提示词
```

---

## 九、学习建议

1. **从memory模块开始**: 理解MD记忆系统是理解整个项目的关键
2. **跟踪一次完整请求**: 从消息接收到响应发送的完整流程
3. **研究工具系统**: 了解如何扩展Agent能力
4. **配置系统**: 理解多Agent和多渠道的配置方式
5. **阅读hooks实现**: 了解生命周期管理

---

**报告生成**: Claude Opus 4.5

**项目**: OpenClaw Agent Framework