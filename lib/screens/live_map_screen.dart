import 'dart:convert';                           // for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';   // real map
import 'package:latlong2/latlong.dart';          // for LatLng coordinates
import 'package:web_socket_channel/web_socket_channel.dart';  // for live updates
import '../services/api_service.dart';           // for stops and WebSocket URL
import '../main.dart';                           // for kSea, kDanger etc

class LiveMapScreen extends StatefulWidget {
  final String routeId;
  const LiveMapScreen({super.key, required this.routeId});
  @override State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {

  // ── Map controller to move camera ──
  final MapController _mapController = MapController();

  // ── WebSocket for live bus updates ──
  WebSocketChannel? _channel;

  // ── Live data from backend ──
  String _currentStop = 'Loading...';  // current stop name
  int    _eta         = 0;             // ETA in minutes
  int    _delay       = 0;             // delay in minutes
  bool   _onTime      = true;          // on time or delayed
  String _busId       = '';            // bus ID
  bool   _connected   = false;         // WebSocket connected

  // ── Real stops from backend ──
  List<dynamic> _stops = [];           // list of stop objects with lat/lng

  // ── Bus marker position on map ──
  LatLng _busPosition = const LatLng(33.6007, 73.0679); // default Rawalpindi

  // ── Route line points ──
  List<LatLng> _routePoints = [];      // points for drawing route line

  @override
  void initState() {
    super.initState();
    _loadStops();           // load real stops with GPS coordinates
    _connectWebSocket();    // connect to live tracking
  }

  Future<void> _loadStops() async {
    try {
      // Fetch real stops for this route — each has latitude and longitude
      final stops = await ApiService.getStops(widget.routeId);
      setState(() {
        _stops = stops;

        // Build route line from stop coordinates
        _routePoints = stops.map((s) => LatLng(
          double.parse(s['latitude'].toString()),   // real GPS latitude
          double.parse(s['longitude'].toString()),  // real GPS longitude
        )).toList();

        // Set initial bus position to first stop
        if (stops.isNotEmpty) {
          _busPosition = LatLng(
            double.parse(stops[0]['latitude'].toString()),
            double.parse(stops[0]['longitude'].toString()),
          );
        }
      });

      // Move camera to first stop after map widget is fully built
      if (stops.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _mapController.move(_busPosition, 14.0);
          } catch (_) {}
        });
      }
    } catch (e) {
      print('Could not load stops: $e');
    }
  }

  void _connectWebSocket() {
    try {
      // Connect to live tracking WebSocket
      _channel = WebSocketChannel.connect(
        Uri.parse(ApiService.getLiveTrackingUrl(widget.routeId)),
      );

      // Listen for updates every 5 seconds from backend
      _channel!.stream.listen(
        (data) {
          final update = jsonDecode(data);          // parse JSON update
          final currentStopName = update['current_stop'] ?? '';

          // Find the stop with this name and get its coordinates
          final matchingStop = _stops.firstWhere(
            (s) => s['name'] == currentStopName,
            orElse: () => null,                    // null if not found
          );

          setState(() {
            _connected   = true;
            _busId       = update['bus_id']       ?? '';
            _currentStop = currentStopName;
            _eta         = update['eta_minutes']  ?? 0;
            _delay       = update['delay_minutes'] ?? 0;
            _onTime      = _delay == 0;

            // Move bus marker to real GPS coordinates of current stop
            if (matchingStop != null) {
              _busPosition = LatLng(
                double.parse(matchingStop['latitude'].toString()),
                double.parse(matchingStop['longitude'].toString()),
              );

              // Move map camera to follow the bus
              try {
                _mapController.move(_busPosition, 14.0);
              } catch (_) {}
            }
          });
        },
        onError: (e) => setState(() => _connected = false),
        onDone:  ()  => setState(() => _connected = false),
      );
    } catch (e) {
      print('WebSocket error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();   // close WebSocket when leaving screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [

        // ── Top bar ──
        Container(
          color: kSea,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
            left: 8, right: 16, bottom: 12,
          ),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text('Route ${widget.routeId} — Live',
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            // LIVE / OFFLINE badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _connected
                      ? const Color.fromRGBO(255,255,255,0.25)
                      : const Color.fromRGBO(255,0,0,0.3),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(
                _connected ? 'LIVE' : 'OFFLINE',
                style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 1),
              ),
            ),
          ]),
        ),

        // ── Real Map ──
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _busPosition,    // center on bus position
              initialZoom: 13.0,              // zoom level
            ),
            children: [

              // ── OpenStreetMap tile layer (free, no API key) ──
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.my_flutter_app',
              ),

              // ── Route line connecting all stops ──
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,   // real GPS coordinates
                      color: kSea,            // app color
                      strokeWidth: 4.0,       // line thickness
                    ),
                  ],
                ),

              // ── Stop markers ──
              MarkerLayer(
                markers: [
                  // Stop dots for each real stop
                  ..._stops.map((stop) {
                    final lat = double.parse(stop['latitude'].toString());
                    final lng = double.parse(stop['longitude'].toString());
                    final isCurrentStop = stop['name'] == _currentStop;

                    return Marker(
                      point: LatLng(lat, lng),
                      width: isCurrentStop ? 120 : 100,
                      height: isCurrentStop ? 40 : 30,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stop label
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrentStop ? kSea : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: kSea, width: 1),
                            ),
                            child: Text(
                              stop['name'] ?? '',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isCurrentStop
                                    ? Colors.white : kTextDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Stop dot
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: isCurrentStop ? kSea : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: kSea, width: 2),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // ── Bus marker at current real GPS position ──
                  Marker(
                    point: _busPosition,      // real GPS coordinates
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: kSea, shape: BoxShape.circle),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Bottom info panel ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Route ${widget.routeId} — Live Tracking',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: kTextDark)),
              const SizedBox(height: 2),
              // Real bus ID and current stop from backend
              Text(
                _connected
                    ? 'Bus $_busId  ·  At $_currentStop'
                    : 'Connecting to server...',
                style: const TextStyle(fontSize: 12, color: kMuted),
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _stops.isNotEmpty
                      ? (_stops.indexWhere((s) =>
                              s['name'] == _currentStop) +
                          1) /
                          _stops.length
                      : 0.0,
                  backgroundColor: kBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(kSea),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                // Real ETA
                _InfoChip(value: '$_eta', label: 'ETA (min)'),
                const SizedBox(width: 24),
                // Real stops remaining
                _InfoChip(
                  value: _stops.isNotEmpty
                      ? '${_stops.length - (_stops.indexWhere((s) => s['name'] == _currentStop) + 1)}'
                      : '0',
                  label: 'Stops left',
                ),
                const Spacer(),
                // On time / delayed badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _onTime
                        ? const Color(0xFFEAF3DE)
                        : const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _onTime ? 'ON TIME' : 'DELAYED +$_delay min',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _onTime
                            ? kSuccess : const Color(0xFF854F0B)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String value, label;
  const _InfoChip({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(fontSize: 22,
          fontWeight: FontWeight.w800, color: kSea)),
      Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
    ],
  );
}
