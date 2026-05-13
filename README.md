# Sda_Project
# 🚌 Real-time Public Transport Alert System
> A simulated live bus tracking system for Rawalpindi, Pakistan.  
> Commuters subscribe to routes and get instant alerts when buses are delayed.

---

## 👥 Team

| Member | Role | Branch |
|--------|------|--------|
| Member 1 | Database (PostgreSQL) | `database/postgresql` |
| Member 2 | Backend (FastAPI) | `backend/fastapi` |
| Member 3 | Frontend (Flutter) | `frontend/flutter` |

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Python + FastAPI |
| Database | PostgreSQL |
| Real-time | WebSockets |

---

## 🚀 Getting Started

### Step 1 — Clone the repo
```bash
git clone https://github.com/yourname/yourrepo.git
cd yourrepo
```

### Step 2 — Switch to YOUR branch (do not work on main)
```bash
# Member 1 (Database)
git checkout database/postgresql

# Member 2 (Backend)
git checkout backend/fastapi

# Member 3 (Frontend)
git checkout frontend/flutter
```

### Step 3 — Pull latest code every morning
```bash
git pull origin main
```

---

## ⚙️ Backend Setup (Member 2)

### Install libraries
```bash
pip install fastapi uvicorn sqlalchemy psycopg2-binary pydantic python-dotenv
```

### Create .env file (never push this to GitHub)
```
DATABASE_URL=postgresql://postgres:PASSWORD@DB_IP/transport_db
```

### Run the server
```bash
uvicorn main:app --reload --host 0.0.0.0
```

### Test all endpoints (no Flutter needed)
```
http://localhost:8000/docs
```

---

## 🗄️ Database Setup (Member 1)

### Install PostgreSQL
Download from https://postgresql.org and install.  
Remember the password you set during install.

### Create the database
```sql
CREATE DATABASE transport_db;
```

### Send these to Member 2
```
IP Address   → run ipconfig (Windows) or ifconfig (Mac)
Username     → postgres
Password     → whatever you set during install
DB Name      → transport_db
```

---

## 📱 Frontend Setup (Member 3)

### Add these to pubspec.yaml
```yaml
dependencies:
  dio: ^5.0.0
  web_socket_channel: ^2.4.0
  provider: ^6.0.0
```

### Get the backend URL from Member 2
```
Base URL       → http://MEMBER2_IP:8000
WebSocket URL  → ws://MEMBER2_IP:8000/live/{route_id}
```

> ⚠️ All 3 members must be on the same WiFi when testing together.

---

## 🔌 API Endpoints

### Routes
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/routes` | Get all bus routes |
| GET | `/routes/{id}` | Get one route with stops |
| GET | `/routes/{id}/buses` | Get buses on a route |

### Buses
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/buses` | Get all active buses |
| GET | `/buses/{id}` | Get one bus (position + delay) |
| GET | `/buses/{id}/eta` | Get ETA to each stop |

### Commuters
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/register` | Create account |
| POST | `/login` | Login, get token |
| POST | `/subscribe` | Subscribe to a route |
| DELETE | `/unsubscribe/{route_id}` | Unsubscribe from a route |

### Alerts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/alerts` | Get all recent alerts |
| GET | `/alerts/my` | Get alerts for my routes only |

### Live Tracking (WebSocket)
| Type | Endpoint | Description |
|------|----------|-------------|
| WS | `/live/{route_id}` | Stream live bus updates every 3 seconds |

---

## 🚌 Bus Routes (Rawalpindi)

| Bus | Route | Stops |
|-----|-------|-------|
| Bus 1 | Saddar → Bahria Town | Saddar Chowk, Committee Chowk, 6th Road, Faizabad, Motorway Toll, Bahria Chowk, Bahria Town Gate |
| Bus 8 | Cantt → F-10 Islamabad | Cantt Station, Lalkurti, Pirwadhai, Koral Chowk, Tarlai, Golra, F-10 Markaz |
| Bus 14 | Raja Bazaar → Airport | Raja Bazaar, Liaquat Bagh, Shamsabad, Westridge, Chaklala Scheme 3, Airport |

---

## 🎨 Design Patterns

| Pattern | Where used | Why |
|---------|-----------|-----|
| Observer | Alert system | Notifies all subscribed commuters automatically when bus is delayed |
| Adapter | Bus feed | Wraps simulated GPS so real GPS can plug in later |
| MVC | Whole backend | Separates data (models), logic (controller), output (schemas) |

---

## 📁 Project Structure

```
backend/
├── main.py           ← API endpoints + WebSocket
├── database.py       ← PostgreSQL connection
├── models.py         ← Database tables
├── schemas.py        ← Request/response shapes
├── simulator.py      ← Bus simulation engine
├── observer.py       ← Observer pattern
├── requirements.txt  ← All Python libraries
└── .env              ← DB credentials (NEVER push to GitHub)
```

---

## 📋 Daily Git Workflow

```bash
# Morning — get latest code
git pull origin main

# Work on your code...

# Evening — save and push your work
git add .
git commit -m "describe what you did"
git push origin your-branch-name
```

### When a feature is ready to merge into main:
1. Go to GitHub
2. Click **"Compare & pull request"**
3. Write what you did
4. Another member reviews it
5. Click **"Merge pull request"**

---

## ⚠️ Important Rules

- ❌ **Never push directly to main**
- ❌ **Never push the .env file**
- ✅ **Always pull before you start working**
- ✅ **Commit often with clear messages**
- ✅ **Test your part before merging to main**

---

## 📦 Requirements

```
fastapi
uvicorn
sqlalchemy
psycopg2-binary
pydantic
python-dotenv
```

Install all at once:
```bash
pip install -r requirements.txt
```
