# -*- coding: utf-8 -*-
# ============================================================
# database.py
# MVC PATTERN → This is the MODEL layer foundation
#
# This file sets up:
# 1. The database connection (engine)
# 2. The session factory (SessionLocal)
# 3. All ORM table models (User, Route, Bus, etc.)
#
# Every other file imports from here.
# ============================================================

from sqlalchemy import (
    create_engine, Column, String, Integer,
    Boolean, DateTime, Numeric, Text, Time, ForeignKey   # all column types we use
)

from dotenv import load_dotenv
import os

load_dotenv()  # reads your .env file
DATABASE_URL = os.getenv("DATABASE_URL")  # gets the URL from .env

# FIX → declarative_base() moved in SQLAlchemy 1.4+
# Old import: from sqlalchemy.ext.declarative import declarative_base  ← deprecated, shows warning
# New import: from sqlalchemy.orm import declarative_base              ← correct for modern SQLAlchemy
from sqlalchemy.orm import sessionmaker, relationship, declarative_base

from sqlalchemy.dialects.postgresql import UUID     # PostgreSQL-specific UUID column type
import uuid                                         # Python's built-in UUID generator
from datetime import datetime                       # for default timestamps                                   # reads environment variables

# ── Base class for all ORM models ──
# Every model (User, Route, etc.) inherits from this
Base = declarative_base()

# ── Read the database URL from .env ──
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    # Hard stop — can't do anything without a database URL
    raise ValueError("❌ DATABASE_URL not found in .env file! Set it to your Supabase connection string.")

# FIX → Supabase requires SSL. Without this, the connection may be refused.
# If DATABASE_URL already has ?sslmode=require, this check avoids adding it twice.
if "sslmode" not in DATABASE_URL:
    DATABASE_URL += "?sslmode=require"  # append SSL requirement for Supabase

print("✅ Connecting to PostgreSQL...")

# ── Create the SQLAlchemy engine ──
# The engine is the actual connection to the database.
# pool_pre_ping=True → tests connection before using it (avoids stale connection errors)
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# ── Session factory ──
# Call SessionLocal() to get a new database session
# autocommit=False → we manually call db.commit() when we want to save
# autoflush=False  → don't automatically flush changes before every query
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# ── get_db() dependency ──
# Used by FastAPI endpoints via Depends(get_db).
# Automatically opens a session and closes it after the request.
def get_db():
    db = SessionLocal()         # open a new session
    try:
        yield db                # give the session to the endpoint
    finally:
        db.close()              # always close session after request ends


# ============================================================
# ORM MODELS
# Each class below maps to one table in the database.
# SQLAlchemy reads these to know the table structure.
# ============================================================

class User(Base):
    __tablename__ = "users"                                                     # maps to "users" table

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)      # UUID primary key, auto-generated
    email = Column(String(255), unique=True, nullable=False)                    # unique email, required
    password_hash = Column(String(255), nullable=False)                         # hashed password, required
    name = Column(String(100), nullable=False)                                  # display name, required
    created_at = Column(DateTime, default=datetime.utcnow)                      # auto-set on creation
    last_login = Column(DateTime)                                               # updated on each login

    # Relationships → lets us do user.subscriptions or user.alerts
    subscriptions = relationship("Subscription", back_populates="user")         # all subscriptions by this user
    alerts = relationship("AlertHistory", back_populates="user")                # all alerts received by this user


class Route(Base):
    __tablename__ = "routes"                                    # maps to "routes" table

    id = Column(String(10), primary_key=True)                   # e.g. "R1", "R2"
    name = Column(String(150), nullable=False)                  # full route name
    start_point = Column(String(100))                           # starting location name
    end_point = Column(String(100))                             # ending location name
    area = Column(String(100))                                  # city area e.g. "Rawalpindi"
    status = Column(String(20), default="running")              # "running" or "delayed"
    color_hex = Column(String(7))                               # hex color for map display e.g. "#FF5733"
    delay_minutes = Column(Integer, default=0)                  # current delay in minutes
    total_stops = Column(Integer, default=0)                    # total number of stops on this route

    # Relationships → lets us do route.buses, route.stops, route.subscriptions
    buses = relationship("Bus", back_populates="route")                                     # buses on this route
    stops = relationship("Stop", back_populates="route", order_by="Stop.sequence")          # stops in order
    subscriptions = relationship("Subscription", back_populates="route")                    # users subscribed


class Bus(Base):
    __tablename__ = "buses"                                             # maps to "buses" table

    id = Column(String(10), primary_key=True)                           # e.g. "B1", "B8"
    route_id = Column(String(10), ForeignKey("routes.id"), nullable=False)  # which route this bus runs
    type = Column(String(20), nullable=False)                           # e.g. "minibus", "coach"
    name = Column(String(100))                                          # optional display name
    capacity = Column(Integer, default=50)                              # max passengers
    speed_kmh = Column(Integer, default=40)                             # average speed
    is_active = Column(Boolean, default=True)                           # whether bus is currently in service

    # Relationships
    route = relationship("Route", back_populates="buses")               # the route this bus belongs to
    positions = relationship("BusPosition", back_populates="bus")       # all position records for this bus


class Stop(Base):
    __tablename__ = "stops"                                                     # maps to "stops" table

    id = Column(Integer, primary_key=True, autoincrement=True)                  # auto-incrementing ID
    route_id = Column(String(10), ForeignKey("routes.id"), nullable=False)      # which route this stop is on
    name = Column(String(150), nullable=False)                                  # stop name e.g. "Saddar Chowk"
    sequence = Column(Integer, nullable=False)                                  # order along the route (1, 2, 3...)
    latitude = Column(Numeric(9, 6), nullable=False)                            # GPS latitude (6 decimal places)
    longitude = Column(Numeric(9, 6), nullable=False)                           # GPS longitude (6 decimal places)

    # Relationship
    route = relationship("Route", back_populates="stops")                       # the route this stop belongs to


class BusPosition(Base):
    __tablename__ = "bus_positions"                                             # maps to "bus_positions" table

    id = Column(Integer, primary_key=True, autoincrement=True)                  # auto-incrementing ID
    bus_id = Column(String(10), ForeignKey("buses.id"), nullable=False)         # which bus this position is for
    latitude = Column(Numeric(9, 6))                                            # GPS latitude
    longitude = Column(Numeric(9, 6))                                           # GPS longitude
    progress = Column(Numeric(5, 4), default=0.0)                               # 0.0 = route start, 1.0 = route end
    speed_kmh = Column(Integer, default=0)                                      # speed at this moment
    recorded_at = Column(DateTime, default=datetime.utcnow)                     # when this position was recorded

    # Relationship
    bus = relationship("Bus", back_populates="positions")                       # the bus this position belongs to


class Subscription(Base):
    __tablename__ = "subscriptions"                                             # maps to "subscriptions" table

    id = Column(Integer, primary_key=True, autoincrement=True)                  # auto-incrementing ID
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)    # which user subscribed
    route_id = Column(String(10), ForeignKey("routes.id"), nullable=False)          # which route they subscribed to
    created_at = Column(DateTime, default=datetime.utcnow)                          # when they subscribed
    is_active = Column(Boolean, default=True)                                       # False = unsubscribed

    # Relationships
    user = relationship("User", back_populates="subscriptions")                 # the user who subscribed
    route = relationship("Route", back_populates="subscriptions")               # the route they subscribed to


class Schedule(Base):
    __tablename__ = "schedules"                                                 # maps to "schedules" table

    id = Column(Integer, primary_key=True, autoincrement=True)                  # auto-incrementing ID
    route_id = Column(String(10), ForeignKey("routes.id"), nullable=False)      # which route this schedule is for
    stop_id = Column(Integer, ForeignKey("stops.id"), nullable=False)           # which stop this time applies to
    departure_time = Column(Time, nullable=False)                                # scheduled departure time
    day_type = Column(String(20), nullable=False)                                # "weekday" or "weekend"


class AlertHistory(Base):
    __tablename__ = "alert_history"                                             # maps to "alert_history" table

    id = Column(Integer, primary_key=True, autoincrement=True)                  # auto-incrementing ID
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)    # who received this alert
    route_id = Column(String(10), ForeignKey("routes.id"), nullable=False)          # which route triggered it
    bus_id = Column(String(10), ForeignKey("buses.id"), nullable=False)             # which bus triggered it
    message = Column(Text, nullable=False)                                          # the alert text
    stop_name = Column(String(150))                                                 # where the bus was
    sent_at = Column(DateTime, default=datetime.utcnow)                             # when the alert was sent
    is_read = Column(Boolean, default=False)                                        # whether user has read it

    # Relationship
    user = relationship("User", back_populates="alerts")                        # the user who received this alert