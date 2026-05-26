// ============================================================
// api_service.dart
// This file handles ALL communication between Flutter and backend
//
// Every screen imports this file to get data from the server.
// Change baseUrl if your laptop IP changes.
// ============================================================

import 'dart:convert';           // for jsonEncode and jsonDecode
import 'package:http/http.dart' as http;   // for making HTTP requests

class ApiService {

  // ── Base URL of your FastAPI backend ──
  // This is your laptop's IP on your WiFi network
  // If it stops working, run ipconfig and update this
  static const String baseUrl = "http://192.168.1.7:8000";

  // ============================================================
  // AUTH
  // ============================================================

  // Register a new user account
  // Called from register_screen.dart
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),         // POST /register
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );
    return jsonDecode(response.body);         // returns {message, user_id, name}
  }

  // Login with email and password
  // Called from login_screen.dart
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),            // POST /login
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    return jsonDecode(response.body);         // returns {message, user_id, name}
  }

  // ============================================================
  // ROUTES
  // ============================================================

  // Get all bus routes (optional filters)
  // Called from home_screen.dart
  static Future<List<dynamic>> getRoutes({String? area, String? status}) async {
    // Build query string if filters provided
    String query = "";
    if (area != null) query += "?area=$area";
    if (status != null) query += (query.isEmpty ? "?" : "&") + "status=$status";

    final response = await http.get(
      Uri.parse("$baseUrl/routes$query"),     // GET /routes or /routes?area=Rawalpindi
    );
    return jsonDecode(response.body);         // returns list of route objects
  }

  // Get one specific route by ID
  // Called from route_detail_screen.dart
  static Future<Map<String, dynamic>> getRoute(String routeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/routes/$routeId"),  // GET /routes/R1
    );
    return jsonDecode(response.body);         // returns single route object
  }

  // Get all stops for a route in order
  // Called from route_detail_screen.dart
  static Future<List<dynamic>> getStops(String routeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/routes/$routeId/stops"),  // GET /routes/R1/stops
    );
    return jsonDecode(response.body);         // returns list of stop objects
  }

  // ============================================================
  // BUSES
  // ============================================================

  // Get latest position of all active buses
  // Called from live_map_screen.dart
  static Future<List<dynamic>> getBuses() async {
    final response = await http.get(
      Uri.parse("$baseUrl/buses"),            // GET /buses
    );
    return jsonDecode(response.body);         // returns list of bus position objects
  }

  // Get ETA for a specific bus
  // Called from live_map_screen.dart or route_detail_screen.dart
  static Future<Map<String, dynamic>> getBusEta(String busId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/buses/$busId/eta"), // GET /buses/B1/eta
    );
    return jsonDecode(response.body);         // returns {bus_id, current_stop, remaining_stops, eta_minutes}
  }

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================

  // Subscribe a user to a route
  // Called from route_detail_screen.dart
  static Future<Map<String, dynamic>> subscribe({
    required String userId,
    required String routeId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/subscribe"),        // POST /subscribe
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "route_id": routeId,
      }),
    );
    return jsonDecode(response.body);         // returns {message}
  }

  // Unsubscribe a user from a route
  // Called from route_detail_screen.dart or profile_screen.dart
  static Future<Map<String, dynamic>> unsubscribe({
    required String userId,
    required String routeId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/unsubscribe"),      // POST /unsubscribe
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "route_id": routeId,
      }),
    );
    return jsonDecode(response.body);         // returns {message}
  }

  // Get all routes a user is subscribed to
  // Called from profile_screen.dart
  static Future<List<dynamic>> getSubscriptions(String userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/subscriptions/$userId"),  // GET /subscriptions/abc-123
    );
    return jsonDecode(response.body);         // returns list of subscription objects
  }

  // Check if user is subscribed to a specific route
  // Called from route_detail_screen.dart
  static Future<bool> isSubscribed({
    required String userId,
    required String routeId,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/subscriptions/$userId/$routeId"),  // GET /subscriptions/abc-123/R1
    );
    final data = jsonDecode(response.body);
    return data['is_subscribed'] ?? false;     // returns {is_subscribed: true/false}
  }

  // ============================================================
  // ALERTS
  // ============================================================

  // Get last 50 alerts for a user
  // Called from alerts_screen.dart
  static Future<List<dynamic>> getAlerts(String userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/alerts/$userId"),   // GET /alerts/abc-123
    );
    return jsonDecode(response.body);         // returns list of alert objects
  }

  // ============================================================
  // WEBSOCKET — LIVE TRACKING
  // Use this in live_map_screen.dart for real-time bus updates
  //
  // Example usage in your screen:
  //
  // final channel = WebSocketChannel.connect(
  //   Uri.parse(ApiService.getLiveTrackingUrl("R1")),
  // );
  // channel.stream.listen((data) {
  //   final update = jsonDecode(data);
  //   // update has: route_id, bus_id, current_stop, next_stop,
  //   //             delay_minutes, eta_minutes, status
  // });
  // ============================================================

  // Returns the WebSocket URL for live tracking a route
  // Note: WebSocket uses ws:// not http://
  static String getLiveTrackingUrl(String routeId) {
    // Replace http with ws for WebSocket connection
    return "ws://192.168.1.7:8000/live/$routeId";  // WS /live/R1
  }

  // ============================================================
  // UPDATE PROFILE
  // Called from edit_profile_screen.dart
  // Backend does not have this endpoint yet — updates name locally
  // and returns success so the UI works without a backend change
  // ============================================================
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    String? email,
    String? password,
  }) async {
    // Backend doesn't have a PATCH /users endpoint yet
    // So we just return success and update the session locally
    // When backend adds this endpoint, replace this with a real call
    await Future.delayed(const Duration(milliseconds: 300)); // simulate network
    return {"message": "Profile updated"};                   // fake success
  }

  // ============================================================
  // UPDATE NOTIFICATION SETTINGS
  // Called from notification_settings_screen.dart
  // Stored locally only — backend has no notifications endpoint yet
  // ============================================================
  static Future<Map<String, dynamic>> updateNotifications({
    required String userId,
    required bool delayAlerts,
    required bool arrivalAlerts,
  }) async {
    // Backend doesn't have a notifications settings endpoint yet
    // So we just return success — settings are stored in app state only
    await Future.delayed(const Duration(milliseconds: 300)); // simulate network
    return {"message": "Settings saved"};                    // fake success
  }
}
