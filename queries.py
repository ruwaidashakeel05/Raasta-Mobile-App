#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ============================================================
# queries.py
# MVC PATTERN → This is the MODEL layer
#
# All database read/write operations live here.
# main.py calls these functions to talk to the database.
#
# FIX APPLIED → Every function now closes the DB session
# in a try/finally block so connections are never leaked.
# Previously sessions were opened but never closed, which
# would exhaust Supabase's connection pool over time.
# ============================================================

from database import (
    SessionLocal, User, Route, Bus, Stop,       # import all ORM models
    BusPosition, Subscription, Schedule, AlertHistory
)
from sqlalchemy import and_, func               # and_ for multi-condition filters, func for MAX()


# ── GET SINGLE BUS POSITION ──
def get_bus_position(bus_id):
    db = SessionLocal()             # open a new database session
    try:
        # Query bus_positions table, filter by bus_id, get the most recent one
        return db.query(BusPosition).filter(
            BusPosition.bus_id == bus_id                    # match this bus ID
        ).order_by(BusPosition.recorded_at.desc()).first()  # sort newest first, take top 1
    finally:
        db.close()      # FIX → always close session even if query throws an error


# ── GET ALL ROUTES (with optional filters) ──
def get_all_routes(area=None, status=None):
    db = SessionLocal()             # open a new database session
    try:
        query = db.query(Route)     # start a query on the routes table

        if area:
            # Filter by area if provided e.g. area="Rawalpindi"
            # ilike = case-insensitive LIKE search
            query = query.filter(Route.area.ilike(f"%{area}%"))

        if status:
            # Filter by status if provided e.g. status="running"
            query = query.filter(Route.status == status)

        return query.all()          # return all matching routes as a list
    finally:
        db.close()      # FIX → always close session


# ── GET ONE ROUTE BY ID ──
def get_route_by_id(route_id):
    db = SessionLocal()             # open a new database session
    try:
        # Find route where id matches e.g. "R1"
        return db.query(Route).filter(Route.id == route_id).first()
    finally:
        db.close()      # FIX → always close session


# ── GET ALL STOPS FOR A ROUTE (in order) ──
def get_stops_for_route(route_id):
    db = SessionLocal()             # open a new database session
    try:
        # Get all stops for this route, sorted by sequence (stop order)
        return db.query(Stop).filter(
            Stop.route_id == route_id           # only stops belonging to this route
        ).order_by(Stop.sequence).all()         # sort by stop number (1, 2, 3...)
    finally:
        db.close()      # FIX → always close session


# ── GET LATEST POSITION OF ALL BUSES ──
def get_all_bus_positions():
    db = SessionLocal()             # open a new database session
    try:
        # We only want the MOST RECENT position per bus, not all historical positions.
        # Step 1: Build a subquery that finds the latest recorded_at timestamp per bus
        subquery = db.query(
            BusPosition.bus_id,                                     # group by bus
            func.max(BusPosition.recorded_at).label("latest")       # get the max (newest) timestamp
        ).group_by(BusPosition.bus_id).subquery()                   # turn into a subquery

        # Step 2: Join back to bus_positions to get the full row for each latest timestamp
        return db.query(BusPosition).join(
            subquery,
            and_(
                BusPosition.bus_id == subquery.c.bus_id,            # match bus ID
                BusPosition.recorded_at == subquery.c.latest        # match the latest timestamp
            )
        ).all()                                                      # return all latest positions
    finally:
        db.close()      # FIX → always close session


# ── SAVE A NEW BUS POSITION ──
def update_bus_position(bus_id, lat, lng, progress, speed):
    db = SessionLocal()             # open a new database session
    try:
        # Create a new BusPosition record with the given data
        new_pos = BusPosition(
            bus_id=bus_id,          # which bus this position belongs to
            latitude=lat,           # GPS latitude
            longitude=lng,          # GPS longitude
            progress=progress,      # how far along the route (0.0 to 1.0)
            speed_kmh=speed         # current speed
        )
        db.add(new_pos)             # stage the new record
        db.commit()                 # save it to the database
    finally:
        db.close()      # FIX → always close session


# ── GET USER BY EMAIL ──
def get_user_by_email(email):
    db = SessionLocal()             # open a new database session
    try:
        # Look up a user by their email address (used in login and register)
        return db.query(User).filter(User.email == email).first()
    finally:
        db.close()      # FIX → always close session


# ── GET USER BY ID ──
# FIX → This function was missing entirely.
# It is needed by main.py subscribe endpoint to get the user's real name.
def get_user_by_id(user_id):
    db = SessionLocal()             # open a new database session
    try:
        # Look up a user by their UUID primary key
        return db.query(User).filter(User.id == user_id).first()
    finally:
        db.close()      # always close session


# ── CREATE A NEW USER ──
def create_user(email, password_hash, name):
    db = SessionLocal()             # open a new database session
    try:
        # Build a new User object with provided data
        user = User(
            email=email,                    # user's email
            password_hash=password_hash,    # already hashed password (never plain text)
            name=name                       # user's display name
        )
        db.add(user)                        # stage the new user
        db.commit()                         # save to database
        db.refresh(user)                    # reload the object to get auto-generated ID
        return user                         # return the saved user (with ID)
    finally:
        db.close()      # FIX → always close session


# ── SUBSCRIBE USER TO A ROUTE ──
def subscribe_user(user_id, route_id):
    db = SessionLocal()             # open a new database session
    try:
        # Check if a subscription already exists (even inactive ones)
        existing = db.query(Subscription).filter(
            Subscription.user_id == user_id,        # match this user
            Subscription.route_id == route_id       # match this route
        ).first()

        if existing:
            # Subscription exists but may be inactive → reactivate it
            existing.is_active = True
            db.commit()                             # save the change
            return existing                         # return the reactivated subscription

        # No existing subscription → create a new one
        sub = Subscription(user_id=user_id, route_id=route_id)
        db.add(sub)         # stage the new subscription
        db.commit()         # save to database
        return sub          # return the new subscription
    finally:
        db.close()      # FIX → always close session


# ── UNSUBSCRIBE USER FROM A ROUTE ──
def unsubscribe_user(user_id, route_id):
    db = SessionLocal()             # open a new database session
    try:
        # Find the subscription record for this user and route
        sub = db.query(Subscription).filter(
            Subscription.user_id == user_id,        # match this user
            Subscription.route_id == route_id       # match this route
        ).first()

        if sub:                     # if a subscription was found
            sub.is_active = False   # mark it as inactive (soft delete)
            db.commit()             # save the change
    finally:
        db.close()      # FIX → always close session


# ── GET ALL ACTIVE SUBSCRIPTIONS FOR A USER ──
def get_user_subscriptions(user_id):
    db = SessionLocal()             # open a new database session
    try:
        # Return all routes this user is currently subscribed to
        return db.query(Subscription).filter(
            Subscription.user_id == user_id,        # match this user
            Subscription.is_active == True          # only active subscriptions
        ).all()
    finally:
        db.close()      # FIX → always close session


# ── GET ALL SUBSCRIBERS FOR A ROUTE ──
def get_subscribers_for_route(route_id):
    db = SessionLocal()             # open a new database session
    try:
        # Return all users actively subscribed to this route
        return db.query(Subscription).filter(
            Subscription.route_id == route_id,      # match this route
            Subscription.is_active == True          # only active subscriptions
        ).all()
    finally:
        db.close()      # FIX → always close session


# ── GET SCHEDULE FOR A ROUTE ──
def get_schedule(route_id, day_type):
    db = SessionLocal()             # open a new database session
    try:
        # Return all scheduled departure times for this route on the given day type
        # day_type is e.g. "weekday" or "weekend"
        return db.query(Schedule).filter(
            Schedule.route_id == route_id,          # match this route
            Schedule.day_type == day_type           # match weekday or weekend
        ).order_by(Schedule.departure_time).all()   # sort by time ascending
    finally:
        db.close()      # FIX → always close session


# ── SAVE AN ALERT TO HISTORY ──
def save_alert(user_id, route_id, bus_id, message, stop_name):
    db = SessionLocal()             # open a new database session
    try:
        # Create a new AlertHistory record
        alert = AlertHistory(
            user_id=user_id,        # which user gets this alert
            route_id=route_id,      # which route triggered it
            bus_id=bus_id,          # which bus triggered it
            message=message,        # the alert text
            stop_name=stop_name     # where the bus was when alert fired
        )
        db.add(alert)               # stage the alert
        db.commit()                 # save to database
    finally:
        db.close()      # FIX → always close session


# ── GET LAST 50 ALERTS FOR A USER ──
def get_user_alerts(user_id):
    db = SessionLocal()             # open a new database session
    try:
        # Return the 50 most recent alerts for this user
        return db.query(AlertHistory).filter(
            AlertHistory.user_id == user_id             # match this user
        ).order_by(AlertHistory.sent_at.desc()).limit(50).all()  # newest first, max 50
    finally:
        db.close()      # FIX → always close session