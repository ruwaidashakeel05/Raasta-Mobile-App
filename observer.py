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
# Every observer (commuter) must implement this.
# Defining it as a base class enforces the contract.
class Observer:
    def update(self, message: str, route_id: str):
        # This method is called automatically when a bus sends an alert.
        # Every subclass MUST override this — if not, NotImplementedError is raised.
        raise NotImplementedError("update() must be implemented by subclasses")


# ── SUBJECT INTERFACE ──
# Every subject (bus route) must implement these 3 methods.
# subscribe, unsubscribe, notify — this is the standard Observer contract.
class Subject:
    def subscribe(self, observer: Observer):
        # Add a commuter to the alert list
        raise NotImplementedError

    def unsubscribe(self, observer: Observer):
        # Remove a commuter from the alert list
        raise NotImplementedError

    def notify(self, message: str):
        # Send alert to ALL commuters in the subscriber list
        raise NotImplementedError


# ── CONCRETE SUBJECT → BusRoute ──
# This is the actual bus route that commuters watch.
# It extends Subject and provides real implementations.
class BusRoute(Subject):

    def __init__(self, route_id: str, route_name: str):
        self.route_id = route_id            # unique ID e.g. "R1"
        self.route_name = route_name        # human-readable name e.g. "Saddar to Bahria Town"
        self._observers = []                # list of Commuter objects watching this route
        self.delay_minutes = 0              # current delay in minutes (0 = on time)
        self.current_stop = ""             # name of the stop the bus is currently at

    def subscribe(self, observer: Observer):
        # Add a commuter to the subscriber list.
        # Check first to avoid duplicate entries.
        if observer not in self._observers:
            self._observers.append(observer)    # add to the list

    def unsubscribe(self, observer: Observer):
        # Remove a commuter from the subscriber list.
        # Check first to avoid ValueError if not found.
        if observer in self._observers:
            self._observers.remove(observer)    # remove from the list

    def notify(self, message: str):
        # Send an alert to EVERY commuter currently subscribed.
        # Calls update() on each one — they handle it individually.
        for observer in self._observers:
            observer.update(message, self.route_id)     # pass message and route ID

    def set_delay(self, minutes: int, stop_name: str):
        # Called by the simulator when a bus is delayed.
        # Updates internal state and notifies all subscribers.
        self.delay_minutes = minutes            # update current delay
        self.current_stop = stop_name           # update current stop

        # Build an appropriate message based on delay amount
        if minutes > 0:
            # Bus is delayed → tell subscribers how long
            message = f"{self.route_name} is delayed by {minutes} min at {stop_name}"
        else:
            # Delay cleared → bus is back on time
            message = f"{self.route_name} is back on schedule at {stop_name}"

        # Push the message to all subscribed commuters automatically
        self.notify(message)

    def move_to_stop(self, stop_name: str):
        # Called by the simulator when bus arrives at the next stop.
        # Updates current stop and notifies all subscribers.
        self.current_stop = stop_name                                   # update current position
        message = f"{self.route_name} has arrived at {stop_name}"      # build arrival message
        self.notify(message)                                            # alert all subscribers


# ── CONCRETE OBSERVER → Commuter ──
# This is the commuter who receives alerts.
# It extends Observer and provides the real update() logic.
class Commuter(Observer):

    def __init__(self, user_id: str, name: str):
        self.user_id = user_id      # the commuter's UUID from the database
        self.name = name            # the commuter's display name
        self.alerts = []            # in-memory list of alerts received this session

    def update(self, message: str, route_id: str):
        # This runs automatically when a BusRoute calls notify().
        # Saves the alert locally and also persists it to the database.

        # Build the alert dictionary
        alert = {
            "message": message,         # the alert text
            "route_id": route_id        # which route sent it
        }

        self.alerts.append(alert)                           # save to in-memory list
        print(f"[ALERT → {self.name}]: {message}")         # print to console for debugging

        # FIX → Also save the alert to the database so it appears in /alerts/{user_id}
        # Previously alerts were only printed to console and lost on restart.
        # Now they are persisted so the user can see their alert history.
        try:
            from queries import save_alert      # import here to avoid circular imports at module level
            save_alert(
                user_id=self.user_id,           # which user this alert is for
                route_id=route_id,              # which route triggered it
                bus_id="unknown",               # bus_id not available here; set to placeholder
                message=message,                # the alert text
                stop_name=""                    # stop name not passed here; left empty
            )
        except Exception as e:
            # Don't crash the observer if DB save fails — just log it
            print(f"[WARNING] Could not save alert to DB: {e}")


# ── ROUTE MANAGER (Singleton Pattern) ──
# DESIGN PATTERN → SINGLETON
# Only ONE RouteManager instance exists for the entire app lifetime.
# It stores all BusRoute objects and manages their subscribers.
class RouteManager:

    _instance = None        # class-level variable that holds the single instance

    def __new__(cls):
        # __new__ is called before __init__ when creating an object.
        # We override it to ensure only one instance is ever created.
        if cls._instance is None:
            cls._instance = super().__new__(cls)        # create the instance once
            cls._instance.routes = {}                   # initialize empty routes dictionary
        return cls._instance                            # always return the same instance

    def get_route(self, route_id: str) -> BusRoute:
        # Look up a BusRoute by its ID e.g. "R1"
        # Returns None if the route doesn't exist
        return self.routes.get(route_id)

    def add_route(self, route: BusRoute):
        # Register a new BusRoute in the manager
        # Called at startup by the simulator for each route
        self.routes[route.route_id] = route             # store with route_id as key

    def add_subscriber(self, route_id: str, commuter: Commuter):
        # Subscribe a commuter to a route.
        # Called by the /subscribe endpoint in main.py
        route = self.get_route(route_id)                # find the route
        if route:                                       # only subscribe if route exists
            route.subscribe(commuter)                   # add commuter to route's observer list

    def remove_subscriber(self, route_id: str, commuter: Commuter):
        # Unsubscribe a commuter from a route.
        # Called by the /unsubscribe endpoint in main.py
        route = self.get_route(route_id)                # find the route
        if route:                                       # only unsubscribe if route exists
            route.unsubscribe(commuter)                 # remove commuter from observer list

    def alert_route(self, route_id: str, message: str):
        # Manually send an alert to all subscribers of a route.
        # Useful for sending custom admin alerts.
        route = self.get_route(route_id)                # find the route
        if route:                                       # only alert if route exists
            route.notify(message)                       # trigger Observer notification chain


# ── GLOBAL SINGLETON INSTANCE ──
# This is the one RouteManager used by all files (main.py, simulator.py).
# Imported directly: from observer import route_manager
route_manager = RouteManager()