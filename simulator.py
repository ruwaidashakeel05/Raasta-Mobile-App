# ============================================================
# simulator.py
# DESIGN PATTERN → ADAPTER PATTERN
#
# How it works:
# - BusFeedSource is the INTERFACE (standard format)
# - SimulatedFeedAdapter is the ADAPTER (fake GPS data)
# - The system talks to BusFeedSource only
# - So in future, a RealGPSAdapter can replace it
#   without changing ANY other code
#
# Also contains the simulator loop that moves buses
# every few seconds (this is what makes it "live")
# ============================================================

import asyncio        # for running background tasks and async sleep
import random         # for generating random delays and speeds
from datetime import datetime                           # for timestamps
from observer import route_manager, BusRoute            # Observer pattern classes


# ── ADAPTER INTERFACE ──
# Any data source (real or fake GPS) must follow this format.
# This is the standard contract — all adapters must have these methods.
class BusFeedSource:
    def get_position(self, bus_id: str) -> dict:
        # Must return a dict with current bus position data
        raise NotImplementedError

    def get_delay(self, bus_id: str) -> int:
        # Must return delay in minutes (0 = no delay)
        raise NotImplementedError


# ── SIMULATED ADAPTER ──
# ADAPTER PATTERN → wraps fake GPS data so it looks like real GPS data.
# This lets us test the whole system without needing actual GPS hardware.
class SimulatedFeedAdapter(BusFeedSource):

    def get_position(self, bus_id: str) -> dict:
        # Returns a fake position with random progress along the route
        return {
            "bus_id": bus_id,                                       # which bus
            "progress": round(random.uniform(0, 1), 2),             # 0.0 = at start, 1.0 = at end
            "speed_kmh": random.randint(20, 60),                    # random speed between 20-60 km/h
            "recorded_at": datetime.utcnow().isoformat()            # current UTC time as string
        }

    def get_delay(self, bus_id: str) -> int:
        # 30% chance the bus is delayed on any given tick
        if random.random() < 0.3:
            return random.randint(3, 15)    # random delay between 3 and 15 minutes
        return 0                            # 70% chance: no delay


# ── REAL GPS ADAPTER (future use) ──
# ADAPTER PATTERN → when real GPS hardware is available, swap this in.
# Because both adapters follow BusFeedSource, no other code needs to change.
class RealGPSAdapter(BusFeedSource):
    def get_position(self, bus_id: str) -> dict:
        # TODO: Call real GPS API here
        # e.g. response = requests.get(f"https://gps-api.com/bus/{bus_id}")
        pass

    def get_delay(self, bus_id: str) -> int:
        # TODO: Calculate delay by comparing actual time vs scheduled time
        pass


# ── BUS ROUTES DATA ──
# Rawalpindi/Islamabad routes hardcoded for this project.
# Each route has a bus ID and a list of stop names in order.
ROUTES_DATA = {
    "R1": {
        "name": "Bus 1 — Saddar to Bahria Town",       # human-readable route name
        "bus_id": "B1",                                 # which bus runs this route
        "stops": [
            "Saddar Chowk",         # stop 1 (start)
            "Committee Chowk",      # stop 2
            "6th Road",             # stop 3
            "Faizabad",             # stop 4
            "Motorway Toll",        # stop 5
            "Bahria Chowk",         # stop 6
            "Bahria Town Gate"      # stop 7 (end)
        ]
    },
    "R2": {
        "name": "Bus 8 — Cantt to F-10 Islamabad",     # route name
        "bus_id": "B8",                                 # bus for this route
        "stops": [
            "Cantt Station",        # stop 1 (start)
            "Lalkurti",             # stop 2
            "Pirwadhai",            # stop 3
            "Koral Chowk",          # stop 4
            "Tarlai",               # stop 5
            "Golra",                # stop 6
            "F-10 Markaz"           # stop 7 (end)
        ]
    },
    "R3": {
        "name": "Bus 14 — Raja Bazaar to Airport",      # route name
        "bus_id": "B14",                                # bus for this route
        "stops": [
            "Raja Bazaar",          # stop 1 (start)
            "Liaquat Bagh",         # stop 2
            "Shamsabad",            # stop 3
            "Westridge",            # stop 4
            "Chaklala Scheme 3",    # stop 5
            "Airport"               # stop 6 (end)
        ]
    }
}

# Dictionary that tracks which stop index each bus is currently at.
# Updated every tick as buses move forward through their stops.
bus_stop_index = {
    "B1": 0,        # Bus 1 starts at stop index 0 (Saddar Chowk)
    "B8": 0,        # Bus 8 starts at stop index 0 (Cantt Station)
    "B14": 0        # Bus 14 starts at stop index 0 (Raja Bazaar)
}


# ── SIMULATOR ENGINE ──
# Runs in the background every 5 seconds.
# Each tick moves buses forward and triggers Observer alerts.
class BusSimulator:

    def __init__(self, feed: BusFeedSource):
        self.feed = feed            # the data adapter (fake or real GPS)
        self.running = False        # controls whether the loop keeps running

    def setup_routes(self):
        # Register all routes into the RouteManager (Observer pattern).
        # This must run before the loop starts so routes exist for subscribers.
        for route_id, data in ROUTES_DATA.items():
            route = BusRoute(route_id, data["name"])    # create a BusRoute observer subject
            route_manager.add_route(route)              # register it in the global manager
        print("✅ Routes loaded into Observer system")

    async def start(self):
        # Start the simulation loop — runs forever in the background.
        # Called once at server startup via asyncio.create_task().
        self.running = True
        self.setup_routes()                             # register routes first
        print("🚌 Bus simulator started")

        while self.running:
            # FIX #6 → _tick() is a regular (sync) function but we're inside async.
            # Running it directly would BLOCK the event loop, freezing all API calls
            # for however long _tick() takes. asyncio.to_thread() runs it in a
            # separate thread so the async event loop stays free.
            await asyncio.to_thread(self._tick)         # run _tick in a background thread
            await asyncio.sleep(5)                      # wait 5 seconds before next tick

    def _tick(self):
        # Called every 5 seconds — moves each bus one stop forward.
        # Triggers Observer notifications (delay alerts or arrival alerts).
        for route_id, data in ROUTES_DATA.items():     # loop through all routes
            bus_id = data["bus_id"]                     # get this route's bus ID
            stops = data["stops"]                       # get the list of stops

            current_index = bus_stop_index[bus_id]      # get current stop index for this bus
            current_stop = stops[current_index]         # get the stop name at that index

            # Ask the adapter if this bus is delayed right now
            delay = self.feed.get_delay(bus_id)         # returns 0 or a positive integer

            # Get the BusRoute object from the Observer system
            route = route_manager.get_route(route_id)   # fetch from RouteManager

            if route:                                   # only proceed if route exists
                if delay > 0:
                    # Bus is delayed → set_delay() builds the alert message
                    # and calls notify() which alerts ALL subscribed commuters
                    route.set_delay(delay, current_stop)
                else:
                    # Bus arrived at current stop on time → move_to_stop() notifies subscribers
                    route.move_to_stop(current_stop)

            # Advance bus to next stop.
            # Use modulo (%) so it loops back to stop 0 after the last stop.
            next_index = (current_index + 1) % len(stops)
            bus_stop_index[bus_id] = next_index         # update the global tracker

    def stop(self):
        # Call this to gracefully stop the simulation loop.
        self.running = False
        print("🛑 Bus simulator stopped")


# ── CREATE THE GLOBAL SIMULATOR INSTANCE ──
# Uses SimulatedFeedAdapter (fake GPS).
# To switch to real GPS later, just change this one line:
#   simulator = BusSimulator(RealGPSAdapter())
simulator = BusSimulator(SimulatedFeedAdapter())