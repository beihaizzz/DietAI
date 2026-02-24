---
name: langchain-docs
description: |
  LangChain/LangGraph/LangSmith 官方文档查询技能。当用户询问以下相关问题时自动触发：
  - LangChain: chains, LCEL, runnables, agents, tools, prompts, models, messages, RAG, retrievers, embeddings, vectorstores
  - LangGraph: graphs, state, nodes, edges, persistence, memory, checkpointers, store, workflows, interrupts, streaming
  - LangSmith: tracing, evaluation, datasets, experiments, observability, playground, deployment
  - Deep Agents: skills, subagents, harness, backends
  此技能从官方 llms.txt 索引搜索相关文档链接，然后深入获取详细内容，支持迭代搜索直到找到完整信息。
---

# LangChain 文档查询工作流

## 概述

通过 `https://docs.langchain.com/llms.txt` 官方索引递归查找文档信息。

## 执行流程

### Step 1: 获取文档索引

使用 WebFetch 获取索引：

```
URL: https://docs.langchain.com/llms.txt
Prompt: "搜索与 {用户问题关键词} 相关的文档链接，列出最相关的 3-5 个 URL 及其描述"
```

### Step 2: 关键词匹配

根据问题类型定位相关文档区域：

| 问题类型 | 索引路径前缀 |
|---------|-------------|
| LangGraph Memory | `oss/python/langgraph/persistence`, `oss/python/langgraph/add-memory`, `oss/python/concepts/memory` |
| LangGraph State | `oss/python/langgraph/graph-api`, `oss/python/langgraph/functional-api` |
| LangGraph Deploy | `langsmith/deployment`, `oss/python/langgraph/deploy` |
| LangChain Agents | `oss/python/langchain/agents`, `oss/python/langchain/tools` |
| LangChain RAG | `oss/python/langchain/rag`, `oss/python/langchain/retrieval` |
| LangSmith Tracing | `langsmith/observability`, `langsmith/trace-with-*` |
| LangSmith Evaluation | `langsmith/evaluation`, `langsmith/evaluate-*` |

### Step 3: 递归获取详情

对每个相关链接：

1. 使用 WebFetch 获取页面内容
2. 提取代码示例和关键概念
3. 如果页面引用了其他相关链接，继续获取
4. **最多迭代 5 轮**

```
WebFetch(
  url: "https://docs.langchain.com/oss/python/langgraph/persistence",
  prompt: "提取关于 {具体主题} 的完整说明，包括代码示例、API 用法、最佳实践"
)
```

### Step 4: 整合回答

回答格式要求：

1. **概念解释** - 简明扼要说明核心概念
2. **代码示例** - 必须包含官方示例代码
3. **来源引用** - 列出所有参考的文档链接
4. **版本说明** - 标注适用版本 (LangGraph 0.2+, LangChain 0.3+ 等)

## URL 路径模式

文档 URL 遵循以下模式：

```
https://docs.langchain.com/oss/python/langgraph/{topic}     # LangGraph Python
https://docs.langchain.com/oss/javascript/langgraph/{topic} # LangGraph JS
https://docs.langchain.com/oss/python/langchain/{topic}     # LangChain Python
https://docs.langchain.com/langsmith/{topic}                # LangSmith
```

## 常见主题路径速查

- **Memory**: `oss/python/langgraph/persistence`, `oss/python/concepts/memory`
- **Checkpointers**: `oss/python/langgraph/persistence`
- **Store API**: `oss/python/langgraph/persistence`, `langsmith/agent-server-api/store/*`
- **Streaming**: `oss/python/langgraph/streaming`
- **Interrupts/HITL**: `oss/python/langgraph/interrupts`, `oss/python/langchain/human-in-the-loop`
- **Multi-agent**: `oss/python/langchain/multi-agent/*`
- **Evaluation**: `langsmith/evaluation-*`, `langsmith/evaluate-*`
- **Deployment**: `langsmith/deploy-*`, `langsmith/deployment*`
