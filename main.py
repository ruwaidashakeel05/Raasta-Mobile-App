# ============================================================
# main.py
# MVC PATTERN → This is the CONTROLLER layer
# ============================================================

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
import asyncio
import hashlib

from database import get_db, Base, engine, SessionLocal, Subscription, User
from queries import (
    get_all_routes, get_route_by_id, get_stops_for_route,
    get_all_bus_positions, get_user_by_email, create_user,
    subscribe_user, unsubscribe_user, get_user_subscriptions,
    get_user_alerts, save_alert, get_subscribers_for_route,
    get_user_by_id
)
from simulator import simulator
from observer import route_manager, Commuter

app = FastAPI(
    title="Transport Alert System",
    description="Real-time bus tracking for Rawalpindi/Islamabad"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"database": "connected ✅"}
    except Exception as e:
        return {"database": "failed ❌", "error": str(e)}


# ============================================================
# STARTUP — single merged event
# ============================================================

@app.on_event("startup")
async def startup_event():
    # Step 1 — create tables
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created/verified")
    except Exception as e:
        print(f"⚠️  Database connection failed: {e}")

    # Step 2 — load ALL active subscriptions into Observer memory
    # This is the fix for alerts — without this, server restart
    # wipes all in-memory subscribers so nobody gets alerts
    try:
        db = SessionLocal()
        subs = db.query(Subscription).filter(
            Subscription.is_active == True
        ).all()
        for sub in subs:
            user = db.query(User).filter(User.id == sub.user_id).first()
            name = user.name if user else "Commuter"
            commuter = Commuter(user_id=str(sub.user_id), name=name)
            route_manager.add_subscriber(sub.route_id, commuter)
        db.close()
        print(f"✅ Loaded {len(subs)} subscriptions into Observer")
    except Exception as e:
        print(f"⚠️  Could not load subscriptions: {e}")

    # Step 3 — start simulator
    asyncio.create_task(simulator.start())
    print("🚀 Server started — simulator running")


# ============================================================
# REQUEST BODY MODELS
# ============================================================

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class SubscribeRequest(BaseModel):
    user_id: str
    route_id: str

class UnsubscribeRequest(BaseModel):
    user_id: str
    route_id: str

class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None


# ============================================================
# ROUTE ENDPOINTS
# ============================================================

@app.get("/routes")
def get_routes(
    area: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    routes = get_all_routes(area=area, status=status)
    return [
        {
            "id": r.id,
            "name": r.name,
            "start_point": r.start_point,
            "end_point": r.end_point,
            "area": r.area,
            "status": r.status,
            "color_hex": r.color_hex,
            "delay_minutes": r.delay_minutes,
            "total_stops": r.total_stops
        }
        for r in routes
    ]


@app.get("/routes/{route_id}")
def get_route(route_id: str, db: Session = Depends(get_db)):
    route = get_route_by_id(route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    return {
        "id": route.id,
        "name": route.name,
        "start_point": route.start_point,
        "end_point": route.end_point,
        "area": route.area,
        "status": route.status,
        "color_hex": route.color_hex,
        "delay_minutes": route.delay_minutes,
        "total_stops": route.total_stops
    }


@app.get("/routes/{route_id}/stops")
def get_stops(route_id: str, db: Session = Depends(get_db)):
    stops = get_stops_for_route(route_id)
    return [
        {
            "id": s.id,
            "name": s.name,
            "sequence": s.sequence,
            "latitude": float(s.latitude),
            "longitude": float(s.longitude)
        }
        for s in stops
    ]


# ============================================================
# BUS ENDPOINTS
# ============================================================

@app.get("/buses")
def get_buses(db: Session = Depends(get_db)):
    positions = get_all_bus_positions()
    return [
        {
            "bus_id": p.bus_id,
            "latitude": float(p.latitude) if p.latitude else None,
            "longitude": float(p.longitude) if p.longitude else None,
            "progress": float(p.progress) if p.progress else 0.0,
            "speed_kmh": p.speed_kmh,
            "recorded_at": p.recorded_at.isoformat() if p.recorded_at else None
        }
        for p in positions
    ]


@app.get("/buses/{bus_id}/eta")
def get_eta(bus_id: str):
    from simulator import bus_stop_index, ROUTES_DATA
    for route_id, data in ROUTES_DATA.items():
        if data["bus_id"] == bus_id:
            current_index = bus_stop_index[bus_id]
            stops = data["stops"]
            remaining_stops = len(stops) - current_index - 1
            eta_minutes = remaining_stops * 4
            return {
                "bus_id": bus_id,
                "current_stop": stops[current_index],
                "remaining_stops": remaining_stops,
                "eta_minutes": eta_minutes
            }
    raise HTTPException(status_code=404, detail="Bus not found")


# ============================================================
# AUTH ENDPOINTS
# ============================================================

@app.post("/register")
def register(req: RegisterRequest):
    existing = get_user_by_email(req.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    password_hash = hashlib.sha256(req.password.encode()).hexdigest()
    user = create_user(email=req.email, password_hash=password_hash, name=req.name)
    return {"message": "Account created", "user_id": str(user.id), "name": user.name}


@app.post("/login")
def login(req: LoginRequest):
    user = get_user_by_email(req.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    password_hash = hashlib.sha256(req.password.encode()).hexdigest()
    if user.password_hash != password_hash:
        raise HTTPException(status_code=401, detail="Wrong password")
    return {"message": "Login successful", "user_id": str(user.id), "name": user.name}


# ============================================================
# SUBSCRIPTION ENDPOINTS
# ============================================================

@app.post("/subscribe")
def subscribe(req: SubscribeRequest):
    subscribe_user(req.user_id, req.route_id)
    user = get_user_by_id(req.user_id)
    user_name = user.name if user else "Commuter"
    commuter = Commuter(user_id=req.user_id, name=user_name)
    route_manager.add_subscriber(req.route_id, commuter)
    return {"message": f"Subscribed to route {req.route_id}"}


@app.post("/unsubscribe")
def unsubscribe(req: UnsubscribeRequest):
    unsubscribe_user(req.user_id, req.route_id)
    return {"message": f"Unsubscribed from route {req.route_id}"}


@app.get("/subscriptions/{user_id}")
def get_subscriptions(user_id: str):
    subs = get_user_subscriptions(user_id)
    return [
        {
            "id": s.id,
            "route_id": s.route_id,
            "created_at": s.created_at.isoformat() if s.created_at else None,
            "is_active": s.is_active
        }
        for s in subs
    ]


# ============================================================
# ALERT ENDPOINTS
# ============================================================

@app.get("/alerts/{user_id}")
def get_alerts(user_id: str):
    alerts = get_user_alerts(user_id)
    return [
        {
            "id": a.id,
            "route_id": a.route_id,
            "bus_id": a.bus_id,
            "message": a.message,
            "stop_name": a.stop_name,
            "sent_at": a.sent_at.isoformat() if a.sent_at else None,
            "is_read": a.is_read
        }
        for a in alerts
    ]


# ============================================================
# USER PROFILE ENDPOINTS
# ============================================================

@app.put("/users/{user_id}")
def update_profile(user_id: str, req: UpdateProfileRequest):
    user = get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db = SessionLocal()
    try:
        u = db.query(User).filter(User.id == user_id).first()
        if req.name:
            u.name = req.name           # update name if provided
        if req.email:
            u.email = req.email         # update email if provided
        if req.password:
            u.password_hash = hashlib.sha256(
                req.password.encode()).hexdigest()  # hash and update password
        db.commit()
        db.refresh(u)
        return {
            "message": "Profile updated successfully",
            "user_id": str(u.id),
            "name": u.name,
            "email": u.email
        }
    finally:
        db.close()


# ============================================================
# WEBSOCKET — LIVE TRACKING
# ============================================================

@app.websocket("/live/{route_id}")
async def live_tracking(websocket: WebSocket, route_id: str):
    await websocket.accept()
    print(f"📡 Flutter connected to live tracking for route {route_id}")
    try:
        from simulator import bus_stop_index, ROUTES_DATA
        while True:
            if route_id in ROUTES_DATA:
                data = ROUTES_DATA[route_id]
                bus_id = data["bus_id"]
                stops = data["stops"]
                current_index = bus_stop_index[bus_id]
                current_stop = stops[current_index]
                next_stop = stops[min(current_index + 1, len(stops) - 1)]
                remaining = len(stops) - current_index - 1
                route = route_manager.get_route(route_id)
                delay = route.delay_minutes if route else 0
                await websocket.send_json({
                    "route_id": route_id,
                    "bus_id": bus_id,
                    "bus_name": data["name"],
                    "current_stop": current_stop,
                    "next_stop": next_stop,
                    "delay_minutes": delay,
                    "eta_minutes": remaining * 4 + delay,
                    "status": "DELAYED" if delay > 0 else "ON TIME"
                })
            await asyncio.sleep(5)
    except WebSocketDisconnect:
        print(f"📵 Flutter disconnected from route {route_id}")
