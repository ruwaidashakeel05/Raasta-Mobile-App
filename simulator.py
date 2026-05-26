# ============================================================
# simulator.py
# DESIGN PATTERN → ADAPTER PATTERN
# Updated to use real metro route IDs matching the database
# ============================================================

import asyncio
import random
from datetime import datetime
from observer import route_manager, BusRoute


class BusFeedSource:
    def get_position(self, bus_id: str) -> dict:
        raise NotImplementedError

    def get_delay(self, bus_id: str) -> int:
        raise NotImplementedError


class SimulatedFeedAdapter(BusFeedSource):

    def get_position(self, bus_id: str) -> dict:
        return {
            "bus_id": bus_id,
            "progress": round(random.uniform(0, 1), 2),
            "speed_kmh": random.randint(20, 60),
            "recorded_at": datetime.utcnow().isoformat()
        }

    def get_delay(self, bus_id: str) -> int:
        if random.random() < 0.3:
            return random.randint(3, 15)
        return 0


class RealGPSAdapter(BusFeedSource):
    def get_position(self, bus_id: str) -> dict:
        pass

    def get_delay(self, bus_id: str) -> int:
        pass


# ── UPDATED ROUTES DATA — matches real database route IDs ──
ROUTES_DATA = {
    "RED": {
        "name": "Red Line Metro Bus",
        "bus_id": "B-RED",
        "stops": [
            "Pak Secretariat", "Faiz Ahmed Faiz", "Jinnah Avenue",
            "F-7 Markaz", "Melody", "Karachi Company", "Faizabad",
            "Rehmanabad", "6th Road", "Shamsabad", "Committee Chowk", "Saddar"
        ]
    },
    "ORANGE": {
        "name": "Orange Line Metro Bus",
        "bus_id": "B-ORANGE",
        "stops": [
            "Faiz Ahmed Faiz", "Shahzad Town", "Golra Mor",
            "Tarlai", "Koral Chowk", "T-Chowk", "Islamabad Airport"
        ]
    },
    "GREEN": {
        "name": "Green Line Metro Bus",
        "bus_id": "B-GREEN",
        "stops": [
            "PIMS Hospital", "Kachnar Park", "Bari Imam",
            "Shah Allah Ditta", "Chattar Park", "Simly Dam Road", "Bhara Kahu"
        ]
    },
    "BLUE": {
        "name": "Blue Line Metro Bus",
        "bus_id": "B-BLUE",
        "stops": [
            "PIMS Hospital", "Karachi Company", "Faizabad",
            "Motorway Chowk", "DHA Phase 2", "Bahria Town", "Gulberg Green"
        ]
    },
    "FR4": {
        "name": "FR-4 Electric Feeder Bus",
        "bus_id": "B-FR4",
        "stops": [
            "Bari Imam", "Golra Road", "Kachnar Park",
            "F-6 Markaz", "Super Market", "PIMS Hospital"
        ]
    },
    "FR3A": {
        "name": "FR-3A Feeder Faisal Masjid",
        "bus_id": "B-FR3A",
        "stops": [
            "PIMS Hospital", "F-7 Markaz", "Faisal Masjid",
            "F-8 Markaz", "G-5 Chowk", "Pak Secretariat"
        ]
    },
}

# Track current stop index for each bus
bus_stop_index = {
    "B-RED":    0,
    "B-ORANGE": 0,
    "B-GREEN":  0,
    "B-BLUE":   0,
    "B-FR4":    0,
    "B-FR3A":   0,
}


class BusSimulator:

    def __init__(self, feed: BusFeedSource):
        self.feed = feed
        self.running = False

    def setup_routes(self):
        for route_id, data in ROUTES_DATA.items():
            route = BusRoute(route_id, data["name"], bus_id=data["bus_id"])
            route_manager.add_route(route)
        print("✅ Routes loaded into Observer system")

    async def start(self):
        self.running = True
        self.setup_routes()
        print("🚌 Bus simulator started")
        while self.running:
            await asyncio.to_thread(self._tick)
            await asyncio.sleep(5)

    def _tick(self):
        for route_id, data in ROUTES_DATA.items():
            bus_id = data["bus_id"]
            stops = data["stops"]
            current_index = bus_stop_index[bus_id]
            current_stop = stops[current_index]
            delay = self.feed.get_delay(bus_id)
            route = route_manager.get_route(route_id)
            if route:
                if delay > 0:
                    route.set_delay(delay, current_stop)
                else:
                    route.move_to_stop(current_stop)
            next_index = (current_index + 1) % len(stops)
            bus_stop_index[bus_id] = next_index

    def stop(self):
        self.running = False
        print("🛑 Bus simulator stopped")


simulator = BusSimulator(SimulatedFeedAdapter())