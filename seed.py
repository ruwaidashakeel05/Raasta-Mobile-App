# ============================================================
# seed.py
# Run this file ONCE to:
# 1. DELETE old R1, R2, R3 data
# 2. INSERT all real metro routes with buses and stops
#
# Run with:
#   python seed.py
# ============================================================

from database import SessionLocal, Route, Bus, Stop, BusPosition, Subscription, AlertHistory
from sqlalchemy.exc import IntegrityError

db = SessionLocal()
print("🌱 Starting database seed...")

# ============================================================
# STEP 1 — DELETE OLD R1, R2, R3 DATA
# Must delete in correct order due to foreign keys:
# bus_positions → buses → stops → subscriptions → alert_history → routes
# ============================================================  

print("\n🗑️  Deleting old R1, R2, R3 data...")

old_route_ids = ["R1", "R2", "R3"]
old_bus_ids   = ["B1", "B8", "B14"]

# Delete bus positions first (references buses)
for bus_id in old_bus_ids:
    deleted = db.query(BusPosition).filter(BusPosition.bus_id == bus_id).delete()
    if deleted:
        print(f"  🗑️  Deleted {deleted} positions for bus {bus_id}")
db.commit()

# Delete buses (references routes)
for bus_id in old_bus_ids:
    deleted = db.query(Bus).filter(Bus.id == bus_id).delete()
    if deleted:
        print(f"  🗑️  Deleted bus {bus_id}")
db.commit()

# Delete stops (references routes)
for route_id in old_route_ids:
    deleted = db.query(Stop).filter(Stop.route_id == route_id).delete()
    if deleted:
        print(f"  🗑️  Deleted stops for route {route_id}")
db.commit()

# Delete subscriptions (references routes)
for route_id in old_route_ids:
    deleted = db.query(Subscription).filter(Subscription.route_id == route_id).delete()
    if deleted:
        print(f"  🗑️  Deleted subscriptions for route {route_id}")
db.commit()

# Delete alert history (references routes)
for route_id in old_route_ids:
    deleted = db.query(AlertHistory).filter(AlertHistory.route_id == route_id).delete()
    if deleted:
        print(f"  🗑️  Deleted alerts for route {route_id}")
db.commit()

# Delete routes
for route_id in old_route_ids:
    deleted = db.query(Route).filter(Route.id == route_id).delete()
    if deleted:
        print(f"  🗑️  Deleted route {route_id}")
db.commit()

print("✅ Old data deleted")

# ============================================================
# STEP 2 — INSERT REAL METRO ROUTES
# ============================================================

print("\n🚌 Inserting real metro routes...")

routes = [
    Route(
        id="RED",
        name="Red Line Metro Bus",
        start_point="Pak Secretariat",
        end_point="Saddar",
        area="Blue Area",
        status="running",
        color_hex="#E53935",
        delay_minutes=0,
        total_stops=24
    ),
    Route(
        id="ORANGE",
        name="Orange Line Metro Bus",
        start_point="Faiz Ahmed Faiz",
        end_point="Islamabad Airport",
        area="G-10",
        status="running",
        color_hex="#FB8C00",
        delay_minutes=0,
        total_stops=7
    ),
    Route(
        id="GREEN",
        name="Green Line Metro Bus",
        start_point="PIMS Hospital",
        end_point="Bhara Kahu",
        area="G-7",
        status="running",
        color_hex="#43A047",
        delay_minutes=0,
        total_stops=8
    ),
    Route(
        id="BLUE",
        name="Blue Line Metro Bus",
        start_point="PIMS Hospital",
        end_point="Gulberg Green",
        area="G-7",
        status="running",
        color_hex="#1E88E5",
        delay_minutes=0,
        total_stops=13
    ),
    Route(
        id="FR4",
        name="FR-4 Electric Feeder Bus",
        start_point="Bari Imam",
        end_point="PIMS Hospital",
        area="F-6",
        status="running",
        color_hex="#00897B",
        delay_minutes=0,
        total_stops=8
    ),
    Route(
        id="FR3A",
        name="FR-3A Feeder Faisal Masjid",
        start_point="PIMS Hospital",
        end_point="Pak Secretariat",
        area="G-5",
        status="running",
        color_hex="#8E24AA",
        delay_minutes=0,
        total_stops=7
    ),
]

for route in routes:
    try:
        db.add(route)
        db.commit()
        print(f"  ✅ Route {route.id} — {route.name}")
    except IntegrityError:
        db.rollback()
        print(f"  ⚠️  Route {route.id} already exists, skipping")

# ============================================================
# STEP 3 — INSERT BUSES
# ============================================================

print("\n🚌 Inserting buses...")

buses = [
    Bus(id="B-RED",    route_id="RED",   type="metro",   name="Red Line Bus",    capacity=150, speed_kmh=40, is_active=True),
    Bus(id="B-ORANGE", route_id="ORANGE",type="metro",   name="Orange Line Bus", capacity=150, speed_kmh=40, is_active=True),
    Bus(id="B-GREEN",  route_id="GREEN", type="metro",   name="Green Line Bus",  capacity=150, speed_kmh=40, is_active=True),
    Bus(id="B-BLUE",   route_id="BLUE",  type="metro",   name="Blue Line Bus",   capacity=150, speed_kmh=40, is_active=True),
    Bus(id="B-FR4",    route_id="FR4",   type="feeder",  name="FR-4 Bus",        capacity=50,  speed_kmh=35, is_active=True),
    Bus(id="B-FR3A",   route_id="FR3A",  type="feeder",  name="FR-3A Bus",       capacity=50,  speed_kmh=35, is_active=True),
]

for bus in buses:
    try:
        db.add(bus)
        db.commit()
        print(f"  ✅ Bus {bus.id} — {bus.name}")
    except IntegrityError:
        db.rollback()
        print(f"  ⚠️  Bus {bus.id} already exists, skipping")

# ============================================================
# STEP 4 — INSERT STOPS WITH REAL GPS COORDINATES
# ============================================================

print("\n📍 Inserting stops...")

stops = [
    # ── RED LINE: Pak Secretariat → Saddar ──
    Stop(route_id="RED", name="Pak Secretariat",    sequence=1,  latitude=33.7295, longitude=73.0931),
    Stop(route_id="RED", name="Faiz Ahmed Faiz",    sequence=2,  latitude=33.7165, longitude=73.0629),
    Stop(route_id="RED", name="Jinnah Avenue",      sequence=3,  latitude=33.7220, longitude=73.0714),
    Stop(route_id="RED", name="F-7 Markaz",         sequence=4,  latitude=33.7189, longitude=73.0502),
    Stop(route_id="RED", name="Melody",             sequence=5,  latitude=33.7107, longitude=73.0612),
    Stop(route_id="RED", name="Karachi Company",    sequence=6,  latitude=33.6942, longitude=73.0657),
    Stop(route_id="RED", name="Faizabad",           sequence=7,  latitude=33.6884, longitude=73.0441),
    Stop(route_id="RED", name="Rehmanabad",         sequence=8,  latitude=33.6763, longitude=73.0510),
    Stop(route_id="RED", name="6th Road",           sequence=9,  latitude=33.6621, longitude=73.0537),
    Stop(route_id="RED", name="Shamsabad",          sequence=10, latitude=33.6519, longitude=73.0572),
    Stop(route_id="RED", name="Committee Chowk",    sequence=11, latitude=33.6401, longitude=73.0601),
    Stop(route_id="RED", name="Saddar",             sequence=12, latitude=33.5977, longitude=73.0476),

    # ── ORANGE LINE: Faiz Ahmed Faiz → Airport ──
    Stop(route_id="ORANGE", name="Faiz Ahmed Faiz", sequence=1, latitude=33.7165, longitude=73.0629),
    Stop(route_id="ORANGE", name="Shahzad Town",    sequence=2, latitude=33.7089, longitude=73.0891),
    Stop(route_id="ORANGE", name="Golra Mor",       sequence=3, latitude=33.6981, longitude=73.0124),
    Stop(route_id="ORANGE", name="Tarlai",          sequence=4, latitude=33.6712, longitude=73.0984),
    Stop(route_id="ORANGE", name="Koral Chowk",     sequence=5, latitude=33.6445, longitude=73.0891),
    Stop(route_id="ORANGE", name="T-Chowk",         sequence=6, latitude=33.6321, longitude=73.1012),
    Stop(route_id="ORANGE", name="Islamabad Airport",sequence=7, latitude=33.6167, longitude=73.0992),

    # ── GREEN LINE: PIMS → Bhara Kahu ──
    Stop(route_id="GREEN", name="PIMS Hospital",    sequence=1, latitude=33.7107, longitude=73.0612),
    Stop(route_id="GREEN", name="Kachnar Park",     sequence=2, latitude=33.7021, longitude=73.0698),
    Stop(route_id="GREEN", name="Bari Imam",        sequence=3, latitude=33.6934, longitude=73.0812),
    Stop(route_id="GREEN", name="Shah Allah Ditta", sequence=4, latitude=33.7234, longitude=73.1123),
    Stop(route_id="GREEN", name="Chattar Park",     sequence=5, latitude=33.7412, longitude=73.1345),
    Stop(route_id="GREEN", name="Simly Dam Road",   sequence=6, latitude=33.7589, longitude=73.1512),
    Stop(route_id="GREEN", name="Bhara Kahu",       sequence=7, latitude=33.7712, longitude=73.1678),

    # ── BLUE LINE: PIMS → Gulberg Green ──
    Stop(route_id="BLUE", name="PIMS Hospital",     sequence=1,  latitude=33.7107, longitude=73.0612),
    Stop(route_id="BLUE", name="Karachi Company",   sequence=2,  latitude=33.6942, longitude=73.0657),
    Stop(route_id="BLUE", name="Faizabad",          sequence=3,  latitude=33.6884, longitude=73.0441),
    Stop(route_id="BLUE", name="Motorway Chowk",    sequence=4,  latitude=33.6712, longitude=73.0234),
    Stop(route_id="BLUE", name="DHA Phase 2",       sequence=5,  latitude=33.6534, longitude=73.0123),
    Stop(route_id="BLUE", name="Bahria Town",       sequence=6,  latitude=33.6312, longitude=72.9987),
    Stop(route_id="BLUE", name="Gulberg Green",     sequence=7,  latitude=33.6089, longitude=72.9812),

    # ── FR4: Bari Imam → PIMS ──
    Stop(route_id="FR4", name="Bari Imam",          sequence=1, latitude=33.6934, longitude=73.0812),
    Stop(route_id="FR4", name="Golra Road",         sequence=2, latitude=33.6989, longitude=73.0712),
    Stop(route_id="FR4", name="Kachnar Park",       sequence=3, latitude=33.7021, longitude=73.0698),
    Stop(route_id="FR4", name="F-6 Markaz",         sequence=4, latitude=33.7189, longitude=73.0612),
    Stop(route_id="FR4", name="Super Market",       sequence=5, latitude=33.7212, longitude=73.0589),
    Stop(route_id="FR4", name="PIMS Hospital",      sequence=6, latitude=33.7107, longitude=73.0612),

    # ── FR3A: PIMS → Pak Secretariat ──
    Stop(route_id="FR3A", name="PIMS Hospital",     sequence=1, latitude=33.7107, longitude=73.0612),
    Stop(route_id="FR3A", name="F-7 Markaz",        sequence=2, latitude=33.7189, longitude=73.0502),
    Stop(route_id="FR3A", name="Faisal Masjid",     sequence=3, latitude=33.7295, longitude=73.0371),
    Stop(route_id="FR3A", name="F-8 Markaz",        sequence=4, latitude=33.7089, longitude=73.0489),
    Stop(route_id="FR3A", name="G-5 Chowk",        sequence=5, latitude=33.7212, longitude=73.0812),
    Stop(route_id="FR3A", name="Pak Secretariat",   sequence=6, latitude=33.7295, longitude=73.0931),
]

for stop in stops:
    try:
        db.add(stop)
        db.commit()
        print(f"  ✅ {stop.name} (Route {stop.route_id})")
    except IntegrityError:
        db.rollback()
        print(f"  ⚠️  Stop {stop.name} already exists, skipping")

db.close()
print("\n✅ Database seeded successfully!")
print("   Now update simulator.py to use these route IDs")
print("   Then run: uvicorn main:app --reload --host 0.0.0.0 --port 8000")