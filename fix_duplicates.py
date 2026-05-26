# ============================================================
# fix_duplicates.py
# Run this ONCE to remove duplicate stops
# Keeps only the first occurrence of each stop per route
# ============================================================

from database import SessionLocal, Stop

db = SessionLocal()
print("🔧 Fixing duplicate stops...")

# Get all stops ordered by ID
all_stops = db.query(Stop).order_by(Stop.id).all()

# Track seen combinations of route_id + sequence
seen = set()
deleted = 0

for stop in all_stops:
    key = (stop.route_id, stop.sequence)
    if key in seen:
        # Duplicate — delete it
        db.delete(stop)
        deleted += 1
        print(f"  🗑️  Deleted duplicate: {stop.name} (Route {stop.route_id}, Seq {stop.sequence})")
    else:
        seen.add(key)

db.commit()
db.close()
print(f"\n✅ Done — deleted {deleted} duplicate stops")
