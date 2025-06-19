import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:linkily/screens/room_info.dart';
import 'package:linkily/utils/util_fetch.dart';
import 'package:linkily/utils/util_geocode.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:linkily/components/map_view.dart';
import 'package:linkily/styles/style_common.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  DateTime? _lastTrack;
  bool _loading = true;
  bool _locating = false;
  Position? _position;
  List<dynamic> _roomMembers = [];
  dynamic _currentDevice;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRoomMembers();
  }

  Future<void> _fetchRoomMembers() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      var res = await aget('/rooms/self/list-members');
      if (res != null && res['success'] == true && res['data'] is List) {
        final members = List.from(res['data']);

        // Find self device (assuming it's the first one or has some identifier)
        final selfDevice = members.firstWhere(
          (member) => member['isCurrentDevice'] == true,
        );

        setState(() {
          _roomMembers = members;
          _currentDevice = selfDevice;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = res?['message'] ?? 'Invalid response format';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load room members: ${e.toString()}';
      });
    }
  }

  Future<void> _handleLocate() async {
    try {
      setState(() => _locating = true);

      final status = await Permission.location.request();
      if (!status.isGranted) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = Position(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _lastTrack = DateTime.now();
        _locating = false;
      });

      await aput("/devices/self/geolocation", {
        "geocode": GeoCodingUtils.encodeLatLng(
          LatLng(_position!.latitude, _position!.longitude),
        ),
      });
    } catch (e) {
      setState(() => _locating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location error: $e")));
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return "${difference.inDays} days ago";
    if (difference.inHours > 0) return "${difference.inHours} hours ago";
    if (difference.inMinutes > 0) return "${difference.inMinutes} minutes ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            color: Colors.white,
            onPressed: _loading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomInfoScreen(
                          roomMembers: _roomMembers,
                          currentDevice: _currentDevice,
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Center(
                child: MapView(
                  devices: _roomMembers,
                  currentDeviceColor: Colors.red,
                ),
              ),
            ),
          ),

          // Info Panel
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey,
                              child: Text(
                                _currentDevice['user']['username'][0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name
                                  Text(
                                    _currentDevice['user']['username'] ??
                                        "Unknown",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  // Email
                                  Row(
                                    children: [
                                      const Icon(Icons.email, size: 13),
                                      const SizedBox(width: 3),
                                      Text(
                                        _currentDevice['user']['email'] ??
                                            "No email",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  // Phone
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 13),
                                      const SizedBox(width: 3),
                                      Text(
                                        _currentDevice['user']['phone'] ??
                                            "No phone number",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // Device Info
                                  Text(
                                    "${_currentDevice['brand']} ${_currentDevice['model']}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Toolbox Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          child: Column(
                            children: [
                              // Locate Button
                              ElevatedButton(
                                onPressed: _locating ? null : _handleLocate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor,
                                  foregroundColor: primaryColor,
                                  minimumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: _locating
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.my_location,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 5),
                                          const Text("Locate"),
                                        ],
                                      ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor,
                                  foregroundColor: primaryColor,
                                  maximumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.call, size: 16),
                                    SizedBox(width: 5),
                                    Text("Call"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class Position {
  final double latitude;
  final double longitude;

  Position({required this.latitude, required this.longitude});
}
