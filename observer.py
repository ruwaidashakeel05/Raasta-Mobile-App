# ============================================================
# observer.py
# DESIGN PATTERN → OBSERVER PATTERN
#
# How it works:
# - BusRoute is the SUBJECT (the one being watched)
# - Commuter is the OBSERVER (the one watching)
# - When a bus is delayed, BusRoute tells ALL subscribed
#   commuters automatically by calling notify()
#
# Real life example:
# You subscribe to Bus 1. Bus 1 gets delayed.
# The system automatically alerts YOU and everyone
# else who subscribed to Bus 1.
# ============================================================


# ── OBSERVER INTERFACE ──
class Observer:
    def update(self, message: str, route_id: str, bus_id: str = "", stop_name: str = ""):
        raise NotImplementedError("update() must be implemented by subclasses")


# ── SUBJECT INTERFACE ──
class Subject:
    def subscribe(self, observer: Observer):
        raise NotImplementedError

    def unsubscribe(self, observer: Observer):
        raise NotImplementedError

    def notify(self, message: str):
        raise NotImplementedError


# ── CONCRETE SUBJECT → BusRoute ──
class BusRoute(Subject):

    def __init__(self, route_id: str, route_name: str, bus_id: str = ""):
        self.route_id = route_id            # unique ID e.g. "R1"
        self.route_name = route_name        # human-readable name
        self.bus_id = bus_id                # FIX → store real bus_id e.g. "B1"
        self._observers = []                # list of subscribed Commuter objects
        self.delay_minutes = 0              # current delay in minutes
        self.current_stop = ""             # current stop name

    def subscribe(self, observer: Observer):
        if observer not in self._observers:
            self._observers.append(observer)

    def unsubscribe(self, observer: Observer):
        if observer in self._observers:
            self._observers.remove(observer)

    def notify(self, message: str, bus_id: str = "", stop_name: str = ""):
        # FIX → pass bus_id and stop_name to each observer
        for observer in self._observers:
            observer.update(message, self.route_id, bus_id, stop_name)

    def set_delay(self, minutes: int, stop_name: str):
        self.delay_minutes = minutes
        self.current_stop = stop_name

        if minutes > 0:
            message = f"{self.route_name} is delayed by {minutes} min at {stop_name}"
        else:
            message = f"{self.route_name} is back on schedule at {stop_name}"

        # FIX → pass real bus_id and stop_name so alerts save correctly to DB
        self.notify(message, bus_id=self.bus_id, stop_name=stop_name)

    def move_to_stop(self, stop_name: str):
        self.current_stop = stop_name
        message = f"{self.route_name} has arrived at {stop_name}"
        # FIX → pass real bus_id and stop_name
        self.notify(message, bus_id=self.bus_id, stop_name=stop_name)


# ── CONCRETE OBSERVER → Commuter ──
class Commuter(Observer):

    def __init__(self, user_id: str, name: str):
        self.user_id = user_id
        self.name = name
        self.alerts = []

    def update(self, message: str, route_id: str, bus_id: str = "", stop_name: str = ""):
        # Save alert to in-memory list
        alert = {"message": message, "route_id": route_id}
        self.alerts.append(alert)
        print(f"[ALERT → {self.name}]: {message}")

        # FIX → save to DB with real bus_id and stop_name
        # Previously bus_id="unknown" caused foreign key violation in DB
        # Now we use the real bus_id passed from the simulator
        try:
            from queries import save_alert
            from database import SessionLocal, Bus

            # Find a real bus_id that exists in DB for this route
            db = SessionLocal()
            real_bus = db.query(Bus).filter(Bus.route_id == route_id).first()
            db.close()

            if not real_bus:
                print(f"[DEBUG] No bus found for route {route_id} — skipping save")
                return

            real_bus_id = real_bus.id
            print(f"[DEBUG] Saving alert — user:{self.user_id} route:{route_id} bus:{real_bus_id} stop:{stop_name}")

            save_alert(
                user_id=self.user_id,
                route_id=route_id,
                bus_id=real_bus_id,
                message=message,
                stop_name=stop_name
            )
            print(f"[DEBUG] Alert saved successfully!")

        except Exception as e:
            print(f"[WARNING] Could not save alert to DB: {e}")
            import traceback
            traceback.print_exc()


# ── ROUTE MANAGER (Singleton Pattern) ──
class RouteManager:

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.routes = {}
        return cls._instance

    def get_route(self, route_id: str) -> BusRoute:
        return self.routes.get(route_id)

    def add_route(self, route: BusRoute):
        self.routes[route.route_id] = route

    def add_subscriber(self, route_id: str, commuter: Commuter):
        route = self.get_route(route_id)
        if route:
            route.subscribe(commuter)

    def remove_subscriber(self, route_id: str, commuter: Commuter):
        route = self.get_route(route_id)
        if route:
            route.unsubscribe(commuter)

    def alert_route(self, route_id: str, message: str):
        route = self.get_route(route_id)
        if route:
            route.notify(message)


# One global instance used everywhere
route_manager = RouteManager()