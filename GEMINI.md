# DietAI Project Context

This document provides a comprehensive overview of the **DietAI** project, an AI-powered diet and health management system. It serves as the primary context for Gemini during development and maintenance.

## 🚀 Project Overview

**DietAI** leverages computer vision and natural language processing to help users manage their diet, track nutrition, and achieve health goals.

- **Main Technologies:** FastAPI (Python 3.12), Flutter (Dart), LangGraph (AI Agents), PostgreSQL, Redis, MinIO, ChromaDB.
- **Key Value Props:** AI image-based food recognition, multi-step nutrition analysis via agents, RAG-enhanced advice, and real-time AI nutritionist consultation.

## 🏗️ Architecture & Component Layout

### 1. Backend (FastAPI) - Root Directory
The core API service handling authentication, user data, food records, and orchestration.
- **Entry Point:** `main.py`
- **Routers:** `routers/` (Auth, User, Food, Health, Chat, Analysis)
- **Shared Logic:** `shared/` (Models, Database, Config, Utils)
- **Configuration:** `shared/config/settings.py` (Loads from `.env.dev` with `DIETAI_` prefix)

### 2. AI Agent System (LangGraph) - `agent/`
Specialized AI workflows running on a dedicated service (Port 2024).
- **Graphs:** Defined in `langgraph.json`
  - `nutrition_agent`: Image analysis workflow (`state_init` → `analyze_image` → `extract_nutrition` → `RAG` → `generate_advice`)
  - `chat_agent`: Context-aware conversational health assistant
- **Knowledge Base:** `agent/VectorStore/` (ChromaDB for RAG)
- **Utils:** `agent/utils/` (States, nodes, prompts, schemas)

### 3. Mobile App (Flutter) - `frontend_flutter/`
Cross-platform mobile client for user interaction.
- **State Management:** Riverpod
- **Routing:** Go Router
- **Key Features:** Camera integration, health dashboards, real-time chat (SSE), food history.

### 4. Infrastructure
Managed via Docker Compose (`docker-compose.yml`):
- **PostgreSQL:** Primary relational database (Port 5432)
- **Redis:** Caching for sessions and nutrition summaries (Port 6379)
- **MinIO:** Object storage for food images (Port 9000/9001)

## 🛠️ Development & Operational Commands

### Backend (Python)
- **Setup:** `uv sync`
- **Run:** `uvicorn main:app --reload --port 8000`
- **Migrations:** `alembic upgrade head` | `alembic revision --autogenerate -m "msg"`
- **Test:** `pytest`
- **Lint/Check:** Use `ruff` or `pytest-cov` for coverage.

### AI Agents (LangGraph)
- **Run Dev Server:** `langgraph dev --port 2024`
- **Vector Init:** `python vector_init.py` (Custom script for initializing ChromaDB)

### Frontend (Flutter)
- **Dependencies:** `flutter pub get`
- **Code Gen:** `dart run build_runner build --delete-conflicting-outputs`
- **Run:** `flutter run`

### Infrastructure
- **Start Services:** `docker-compose up -d postgres redis minio`
- **Logs:** `docker-compose logs -f [service_name]`

## 📜 Development Conventions

1.  **Environment Variables:** All project-specific env vars should start with `DIETAI_`.
2.  **API Design:** Unified JSON response format `{success: bool, data: any, message: string}`.
3.  **Real-time Feedback:** Use SSE (Server-Sent Events) for long-running AI analysis or streaming chat responses.
4.  **Database:** Use SQLAlchemy 2.0+ patterns. All models are centralized in `shared/models/`.
5.  **Agent Logic:** Keep logic inside nodes (`agent/utils/nodes.py`) and maintain state definitions in `agent/utils/states.py`.
6.  **Code Style:**
    - **Python:** PEP 8, Type Hints, Google-style docstrings.
    - **Dart:** Effective Dart, Null Safety, Const constructors.

## 📂 Key File Map
- `main.py`: Application entry & middleware.
- `shared/config/settings.py`: Global configuration schema.
- `agent/agent.py`: Analysis graph definition.
- `agent/chat_agent.py`: Chat graph definition.
- `routers/food_router.py`: Food analysis entry point.
- `TECHNICAL_DOCUMENTATION.md`: Deep dive into system design.
- `CLAUDE.md`: Quick reference for development commands.
