# ============================================================
# main.py
# MVC PATTERN → This is the CONTROLLER layer
#
# This file contains all API endpoints
# Flutter sends requests here → this file handles them
# → talks to database → sends response back to Flutter
#
# Run this file with:
#   uvicorn main:app --reload --host 0.0.0.0
#
# Test all endpoints at:
#   http://localhost:8000/docs
# ============================================================

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, HTTPException  # core FastAPI imports
from fastapi.middleware.cors import CORSMiddleware  # allows Flutter/web to call this API
from sqlalchemy import text                         # used to run raw SQL queries
from sqlalchemy.orm import Session                  # type hint for database session
from pydantic import BaseModel                      # used to define request body shapes
from typing import Optional                         # allows optional query parameters
import asyncio                                      # used to run background tasks (simulator)
import hashlib                                      # used to hash passwords before saving

from database import get_db, Base, engine           # database setup imports
from queries import (                               # import all query functions from queries.py
    get_all_routes, get_route_by_id, get_stops_for_route,
    get_all_bus_positions, get_user_by_email, create_user,
    subscribe_user, unsubscribe_user, get_user_subscriptions,
    get_user_alerts, save_alert, get_subscribers_for_route
)
from simulator import simulator                     # the background bus simulator
from observer import route_manager, Commuter        # Observer pattern classes


# ── Create the FastAPI app ──
app = FastAPI(
    title="Transport Alert System",                                          # name shown in /docs
    description="Real-time bus tracking for Rawalpindi/Islamabad"            # description shown in /docs
)

# ── CORS Middleware ──
# Allows Flutter app to call this API without being blocked by browser security
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # allow requests from any origin (Flutter, browser, Postman)
    allow_methods=["*"],       # allow all HTTP methods: GET, POST, DELETE, etc.
    allow_headers=["*"]        # allow all headers in requests
)


# ── Test database connection endpoint ──
@app.get("/test-db")
def test_db(db: Session = Depends(get_db)):         # inject a DB session automatically
    try:
        db.execute(text("SELECT 1"))                # run the simplest possible query to test connection
        return {"database": "connected ✅"}         # return success if query works
    except Exception as e:
        return {"database": "failed ❌", "error": str(e)}   # return error message if connection fails


# ============================================================
# FIX #1 — DUPLICATE STARTUP EVENT
# Previously there were TWO @app.on_event("startup") functions.
# Python only uses the LAST one, so the DB table creation
# was silently skipped every time. Now merged into ONE function.
# ============================================================

@app.on_event("startup")
async def startup_event():
    # ── Step 1: Create all database tables if they don't exist yet ──
    try:
        Base.metadata.create_all(bind=engine)       # creates tables based on models in database.py
        print("✅ Database tables created/verified")
    except Exception as e:
        print(f"⚠️  Database connection failed: {e}")           # print error but don't crash
        print("   API will still run - check your DATABASE_URL in .env")  # helpful hint

    # ── Step 2: Start the bus simulator in the background ──
    asyncio.create_task(simulator.start())          # runs simulator without blocking the API
    print("🚀 Server started — simulator running")


# ============================================================
# REQUEST BODY MODELS (Pydantic)
# MVC PATTERN → These are the VIEW layer (data shapes)
# Defines what data Flutter must send in POST requests
# ============================================================

class RegisterRequest(BaseModel):
    name: str          # commuter's full name
    email: str         # commuter's email address
    password: str      # plain text password (we hash it before saving to DB)

class LoginRequest(BaseModel):
    email: str         # email to look up the user
    password: str      # plain text password to compare against stored hash

class SubscribeRequest(BaseModel):
    user_id: str       # the commuter's UUID from the database
    route_id: str      # the route ID to subscribe to e.g. "R1"

class UnsubscribeRequest(BaseModel):
    user_id: str       # the commuter's UUID from the database
    route_id: str      # the route ID to unsubscribe from


# ============================================================
# ROUTE ENDPOINTS
# Flutter calls these to get bus route info
# ============================================================

@app.get("/routes")
def get_routes(
    area: Optional[str] = None,         # optional filter: ?area=Rawalpindi
    status: Optional[str] = None,       # optional filter: ?status=running
    db: Session = Depends(get_db)       # inject DB session (kept for consistency, queries.py manages its own)
):
    routes = get_all_routes(area=area, status=status)   # fetch routes from DB with optional filters

    # ── FIX #4 — Serialize ORM objects to dicts before returning ──
    # FastAPI cannot return raw SQLAlchemy objects as JSON.
    # We manually convert each Route object to a plain dictionary.
    return [
        {
            "id": r.id,                         # route ID e.g. "R1"
            "name": r.name,                     # full route name
            "start_point": r.start_point,       # starting location
            "end_point": r.end_point,           # ending location
            "area": r.area,                     # city area
            "status": r.status,                 # "running" or "delayed"
            "color_hex": r.color_hex,           # color for map display
            "delay_minutes": r.delay_minutes,   # current delay in minutes
            "total_stops": r.total_stops        # total number of stops
        }
        for r in routes                         # loop through all route objects
    ]


@app.get("/routes/{route_id}")
def get_route(
    route_id: str,                      # route ID from URL e.g. /routes/R1
    db: Session = Depends(get_db)       # inject DB session
):
    route = get_route_by_id(route_id)   # fetch the specific route from DB

    if not route:                       # if no route found with that ID
        raise HTTPException(status_code=404, detail="Route not found")  # return 404 error

    # ── FIX #4 — Serialize ORM object to dict ──
    return {
        "id": route.id,                         # route ID
        "name": route.name,                     # route name
        "start_point": route.start_point,       # starting location
        "end_point": route.end_point,           # ending location
        "area": route.area,                     # city area
        "status": route.status,                 # running or delayed
        "color_hex": route.color_hex,           # hex color for map
        "delay_minutes": route.delay_minutes,   # current delay
        "total_stops": route.total_stops        # number of stops
    }


@app.get("/routes/{route_id}/stops")
def get_stops(
    route_id: str,                          # route ID from URL e.g. /routes/R1/stops
    db: Session = Depends(get_db)           # inject DB session
):
    stops = get_stops_for_route(route_id)   # fetch all stops for this route in order

    # ── FIX #4 — Serialize ORM objects to dicts ──
    return [
        {
            "id": s.id,               # stop's database ID
            "name": s.name,           # stop name e.g. "Saddar Chowk"
            "sequence": s.sequence,   # order of stop along the route
            "latitude": float(s.latitude),    # GPS latitude (cast from Decimal)
            "longitude": float(s.longitude)   # GPS longitude (cast from Decimal)
        }
        for s in stops                # loop through all stop objects
    ]


# ============================================================
# BUS ENDPOINTS
# Flutter calls these to get bus position/status
# ============================================================

@app.get("/buses")
def get_buses(db: Session = Depends(get_db)):   # inject DB session
    positions = get_all_bus_positions()          # fetch latest position of each active bus

    # ── FIX #4 — Serialize ORM objects to dicts ──
    return [
        {
            "bus_id": p.bus_id,                         # bus ID e.g. "B1"
            "latitude": float(p.latitude) if p.latitude else None,    # current GPS lat
            "longitude": float(p.longitude) if p.longitude else None, # current GPS lng
            "progress": float(p.progress) if p.progress else 0.0,     # 0.0 = start, 1.0 = end
            "speed_kmh": p.speed_kmh,                   # current speed
            "recorded_at": p.recorded_at.isoformat() if p.recorded_at else None  # timestamp as string
        }
        for p in positions              # loop through all position objects
    ]


@app.get("/buses/{bus_id}/eta")
def get_eta(bus_id: str):               # bus ID from URL e.g. /buses/B1/eta
    from simulator import bus_stop_index, ROUTES_DATA   # import simulator data

    # Loop through all routes to find which one this bus belongs to
    for route_id, data in ROUTES_DATA.items():
        if data["bus_id"] == bus_id:                        # found the matching route
            current_index = bus_stop_index[bus_id]          # get which stop the bus is at
            stops = data["stops"]                           # get full list of stops
            remaining_stops = len(stops) - current_index - 1   # how many stops are left
            eta_minutes = remaining_stops * 4               # assume 4 minutes per stop

            return {
                "bus_id": bus_id,                           # echo back the bus ID
                "current_stop": stops[current_index],       # name of current stop
                "remaining_stops": remaining_stops,         # number of stops left
                "eta_minutes": eta_minutes                  # estimated minutes to last stop
            }

    # If no route found with this bus ID, return 404
    raise HTTPException(status_code=404, detail="Bus not found")


# ============================================================
# AUTH ENDPOINTS
# Register and login commuters
# ============================================================

@app.post("/register")
def register(req: RegisterRequest):             # receives name, email, password from Flutter
    existing = get_user_by_email(req.email)     # check if this email is already registered

    if existing:                                # if a user with this email exists
        raise HTTPException(status_code=400, detail="Email already registered")  # reject with 400

    # Hash the password using SHA-256 before saving (never store plain text passwords)
    password_hash = hashlib.sha256(req.password.encode()).hexdigest()

    # Save the new user to the database
    user = create_user(
        email=req.email,                # store the email
        password_hash=password_hash,    # store the hashed password
        name=req.name                   # store the name
    )

    # Return success with the new user's ID and name
    return {"message": "Account created", "user_id": str(user.id), "name": user.name}


@app.post("/login")
def login(req: LoginRequest):                   # receives email and password from Flutter
    user = get_user_by_email(req.email)         # look up the user by email

    if not user:                                # if no user found with that email
        raise HTTPException(status_code=404, detail="User not found")  # return 404

    # Hash the input password and compare it to the stored hash
    password_hash = hashlib.sha256(req.password.encode()).hexdigest()

    if user.password_hash != password_hash:     # if hashes don't match, wrong password
        raise HTTPException(status_code=401, detail="Wrong password")  # return 401 unauthorized

    # Return success with user details
    return {"message": "Login successful", "user_id": str(user.id), "name": user.name}


# ============================================================
# SUBSCRIPTION ENDPOINTS
# OBSERVER PATTERN → subscribe/unsubscribe to routes
# ============================================================

@app.post("/subscribe")
def subscribe(req: SubscribeRequest):               # receives user_id and route_id from Flutter
    sub = subscribe_user(req.user_id, req.route_id) # save subscription to database

    # ── FIX #5 — Fetch the real user name instead of hardcoding "Commuter" ──
    # Previously this always used "Commuter" as the name which is wrong.
    # Now we look up the actual user from DB to get their real name.
    user = get_user_by_email_by_id(req.user_id)     # fetch user from DB by their ID
    user_name = user.name if user else "Commuter"   # use real name, fallback to "Commuter" if not found

    # Add this commuter to the in-memory Observer pattern so they receive live alerts
    commuter = Commuter(user_id=req.user_id, name=user_name)    # create Commuter observer
    route_manager.add_subscriber(req.route_id, commuter)         # attach them to the route

    return {"message": f"Subscribed to route {req.route_id}"}    # confirm to Flutter


@app.post("/unsubscribe")
def unsubscribe(req: UnsubscribeRequest):                # receives user_id and route_id from Flutter
    unsubscribe_user(req.user_id, req.route_id)         # mark subscription as inactive in DB
    return {"message": f"Unsubscribed from route {req.route_id}"}  # confirm to Flutter


@app.get("/subscriptions/{user_id}")
def get_subscriptions(user_id: str):            # user_id from URL e.g. /subscriptions/abc-123
    subs = get_user_subscriptions(user_id)      # fetch all active subscriptions for this user

    # ── FIX #4 — Serialize ORM objects to dicts ──
    return [
        {
            "id": s.id,                         # subscription record ID
            "route_id": s.route_id,             # which route they subscribed to
            "created_at": s.created_at.isoformat() if s.created_at else None,  # when they subscribed
            "is_active": s.is_active            # whether subscription is currently active
        }
        for s in subs                           # loop through all subscription objects
    ]


# ============================================================
# ALERT ENDPOINTS
# ============================================================

@app.get("/alerts/{user_id}")
def get_alerts(user_id: str):               # user_id from URL e.g. /alerts/abc-123
    alerts = get_user_alerts(user_id)       # fetch last 50 alerts for this user

    # ── FIX #4 — Serialize ORM objects to dicts ──
    return [
        {
            "id": a.id,                         # alert record ID
            "route_id": a.route_id,             # which route triggered the alert
            "bus_id": a.bus_id,                 # which bus triggered the alert
            "message": a.message,               # the alert text e.g. "Bus 1 delayed by 5 min"
            "stop_name": a.stop_name,           # which stop the bus was at
            "sent_at": a.sent_at.isoformat() if a.sent_at else None,  # when alert was sent
            "is_read": a.is_read                # whether the commuter has read it
        }
        for a in alerts                         # loop through all alert objects
    ]


# ============================================================
# WEBSOCKET ENDPOINT → LIVE TRACKING
# This is the real-time part
# Flutter connects here and receives bus updates every 5 seconds
# No need to keep asking — server PUSHES updates automatically
# ============================================================

@app.websocket("/live/{route_id}")
async def live_tracking(
    websocket: WebSocket,       # the WebSocket connection from Flutter
    route_id: str               # which route Flutter wants to track e.g. "R1"
):
    await websocket.accept()    # accept and open the WebSocket connection
    print(f"📡 Flutter connected to live tracking for route {route_id}")

    try:
        from simulator import bus_stop_index, ROUTES_DATA   # import live simulator data

        while True:                                         # keep sending updates forever
            if route_id in ROUTES_DATA:                     # check if this is a valid route
                data = ROUTES_DATA[route_id]                # get the route's data
                bus_id = data["bus_id"]                     # get the bus ID for this route
                stops = data["stops"]                       # get list of stops
                current_index = bus_stop_index[bus_id]      # get which stop bus is currently at
                current_stop = stops[current_index]         # get the name of current stop
                next_stop = stops[min(current_index + 1, len(stops) - 1)]  # name of next stop (safe index)
                remaining = len(stops) - current_index - 1  # how many stops are left

                # Get the BusRoute object from the Observer system to read current delay
                route = route_manager.get_route(route_id)   # fetch route from RouteManager
                delay = route.delay_minutes if route else 0 # use delay if route exists, else 0

                # Build and push the update to Flutter over WebSocket
                await websocket.send_json({
                    "route_id": route_id,                           # which route this update is for
                    "bus_id": bus_id,                               # which bus
                    "bus_name": data["name"],                       # human-readable bus name
                    "current_stop": current_stop,                   # where the bus is right now
                    "next_stop": next_stop,                         # where it's heading next
                    "delay_minutes": delay,                         # current delay in minutes
                    "eta_minutes": remaining * 4 + delay,           # estimated time to last stop
                    "status": "DELAYED" if delay > 0 else "ON TIME" # status label
                })

            await asyncio.sleep(5)      # wait 5 seconds before sending the next update

    except WebSocketDisconnect:
        # Flutter disconnected (user closed the screen or lost internet)
        print(f"📵 Flutter disconnected from route {route_id}")


# ============================================================
# HELPER FUNCTION
# FIX #5 — get user by ID (needed for subscribe endpoint)
# queries.py only had get_user_by_email, but subscribe needs
# to look up user by ID to get their real name.
# ============================================================

def get_user_by_email_by_id(user_id: str):
    # Import here to avoid circular imports
    from database import SessionLocal, User     # import session and User model
    db = SessionLocal()                         # open a new DB session
    try:
        # Query the users table for the user with this UUID
        return db.query(User).filter(User.id == user_id).first()
    finally:
        db.close()                              # always close session to avoid connection leaks