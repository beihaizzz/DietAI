# DietAI — Agent Working Guide

## Critical Naming Quirk

- `agent/utils/sturcts.py` is a **typo** (should be `structs`). It is imported as `from agent.utils.sturcts import ...` in 7 files. Do NOT rename it without updating all imports.

## Agent Directory is `agent/` not `agents/`

The upstream repo renamed `agent/` → `agents/` but this fork keeps `agent/`. All `langgraph.json` paths use `./agent/...`. All imports use `agent.*`. Do not create an `agents/` directory.

## Environment & Config

- Config loads from `.env.dev` (not `.env`) via `pydantic-settings` with `DIETAI_` prefix (`shared/config/settings.py`).
- `.env` is gitignored; `.env.example` documents available vars. Copy `.env.example` → `.env.dev` for local dev.
- Default credentials in `settings.py` are local dev values (Redis password `123456`, MinIO `admin/admin123456` on port `9090`). Docker Compose uses different defaults (`minioadmin/minioadmin` on port `9000`).

## Required Services

Backend requires 3 external services running before `uvicorn`:

| Service | Default Port | Purpose |
|---------|-------------|---------|
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Cache for nutrition summaries & RAG results |
| MinIO | 9000 (API) / 9001 (Console) | Food image storage |

Start locally: `docker-compose up -d postgres redis minio`  
Windows local services: bats at `bats/minio_start.bat`, `bats/postgresql_start.bat`

LangGraph dev server must run separately: `langgraph dev --port 2024`

## Run Commands

```bash
# Backend
uv sync                                           # install deps (uses uv, not pip)
uvicorn main:app --reload --host 0.0.0.0 --port 8000  # dev server

# LangGraph agent service
langgraph dev --port 2024

# Vector store initialization (one-time, before first agent use)
python vector_init.py

# Flutter frontend
cd frontend_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen before run
flutter run -d windows   # or -d chrome
```

No Alembic migrations directory exists; tables are created via `create_tables()` in `main.py` lifespan.

## Architecture Mapping

```
main.py                    → FastAPI entry, middleware, all routers registered at /api/*
routers/                   → 8 routers: auth, user, food, health, chat, analysis_chat, goal, deep, saved_meals
shared/
  config/settings.py       → Settings (DIETAI_ env prefix, .env.dev)
  config/redis_config.py   → cache_service (Redis caching)
  config/minio_config.py   → minio_client (object storage)
  models/                  → SQLAlchemy models + Pydantic schemas
    database.py            → engine, SessionLocal, get_db
    saved_meal_models.py   → SavedMeal model (new, from upstream)
  services/                → agent_orchestrator etc.
  tasks/                   → scheduler, memory_events
  utils/                   → auth, model, nutrition_calc
agent/
  agent.py                 → nutrition_agent graph entry
  chat_agent.py            → chat_agent graph entry
  test_agent.py            → test_agent graph (LangGraph validation)
  utils/                   → shared states/nodes/prompts/sturcts/tools/configuration
  common_utils/             → image_utils, model_utils, rag_utils, redis_util
  enhanced_nutrition/       → enhanced_nutrition_agent
  goal_tracking/            → goal_tracking_agent
  diet_deep_agent/          → Deep Agents SDK agent (qwen3.5-plus, skills/subagents/tools/memory)
  VectorStore/              → ChromaDB persistence dir (git-tracked binary)
  UserMemory/{user_id}/    → Per-user MD file memory workspaces
```

## LangGraph Graphs (defined in langgraph.json)

| Graph Name | Entry File | Flow |
|------------|-------------|------|
| `nutrition_agent` | `agent/agent.py:graph` | state_init → analyze_image → extract_nutrition → retrieve_knowledge → generate_deps → generate_advice → format_response |
| `enhanced_nutrition_agent` | `agent/enhanced_nutrition/enhanced_agent.py` | Enhanced nutrition analysis |
| `chat_agent` | `agent/chat_agent.py:chat_graph` | initialize_chat → analyze_context → generate_response → format_response |
| `goal_tracking_agent` | `agent/goal_tracking/goal_agent.py` | Nutrition goals |
| `diet_deep_agent` | `agent/diet_deep_agent/deep_agent.py:agent` | Deep Agents SDK, DashScope qwen3.5-plus |
| `test_agent` | `agent/test_agent.py:test_graph` | Validation test graph |

Agent model config passed via LangGraph SDK: `{"configurable": {"vision_model_provider": "openai", "vision_model": "gpt-4.1-nano-2025-04-14", "analysis_model_provider": "openai", "analysis_model": "o3-mini-2025-01-31"}}`

## Shared Models Import Convention

`shared/models/schemas.py` uses `Generic[T]` for `BaseResponse[T]`. When adding new response schemas, keep them in `schemas.py`. Database models go in `user_models.py`, `food_models.py`, `conversation_models.py`, `saved_meal_models.py`. Register new models in `shared/models/__init__.py`.

## Junk Files to Ignore

These are leftover from a sync and can be deleted:
- `routers/food_router_upstream.py`
- `frontend_flutter/pubspec_upstream.yaml`
- `frontend_flutter/gradle_upstream.properties`

## Test Infrastructure

No `tests/` directory or `pytest.ini` configured. Tests listed in `pyproject.toml` deps (`pytest`, `pytest-asyncio`, `pytest-cov`) but no test suite exists yet.