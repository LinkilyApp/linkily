import 'package:flutter/material.dart';
import 'package:linkily/utils/util_geocode.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapView extends StatefulWidget {
  final List<dynamic> devices;
  final Color currentDeviceColor;
  final double markerSize;

  const MapView({
    super.key,
    required this.devices,
    this.currentDeviceColor = Colors.red,
    this.markerSize = 8.0,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapboxMap? mapboxMap;
  CircleAnnotationManager? circleAnnotationManager;
  List<CircleAnnotation> annotations = [];
  final Map<String, Color> deviceColors = {};

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devices != widget.devices || 
        oldWidget.currentDeviceColor != widget.currentDeviceColor ||
        oldWidget.markerSize != widget.markerSize) {
      _updateMap();
    }
  }

  Color _getDeviceColor(String deviceId) {
    if (!deviceColors.containsKey(deviceId)) {
      // Generate a random color but ensure it's not too light
      deviceColors[deviceId] = Color.fromRGBO(
        100 + (DateTime.now().millisecondsSinceEpoch % 155),
        100 + (DateTime.now().millisecondsSinceEpoch % 155),
        100 + (DateTime.now().millisecondsSinceEpoch % 155),
        1,
      );
    }
    return deviceColors[deviceId]!;
  }

  void _updateMap() async {
    if (widget.devices.isEmpty) return;
    if (circleAnnotationManager == null) return;

    // Clear existing annotations
    await circleAnnotationManager?.deleteAll();
    annotations.clear();

    // Create annotations for each device with a geocode
    for (final device in widget.devices) {
      final geocode = device['geocode'];
      if (geocode == null) continue;

      final latLng = GeoCodingUtils.decodeLatLng(geocode);
      final point = Point(coordinates: Position(latLng.longitude, latLng.latitude));

      final isCurrentDevice = device['isCurrentDevice'] == true;
      final color = isCurrentDevice 
          ? widget.currentDeviceColor 
          : _getDeviceColor(device['id']);

      final annotation = CircleAnnotationOptions(
        geometry: point,
        circleColor: color.value,
        circleRadius: widget.markerSize,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 2.0,
      );

      final createdAnnotation = await circleAnnotationManager?.create(annotation);
      if (createdAnnotation != null) {
        annotations.add(createdAnnotation);
      }
    }

    // Center the map on the current device if available, or first device otherwise
    final currentDevice = widget.devices.firstWhere(
      (d) => d['isCurrentDevice'] == true,
      orElse: () => widget.devices.firstWhere((d) => d['geocode'] != null),
    );

    if (currentDevice != null && currentDevice['geocode'] != null) {
      final latLng = GeoCodingUtils.decodeLatLng(currentDevice['geocode']);
      final point = Point(coordinates: Position(latLng.longitude, latLng.latitude));
      
      mapboxMap?.flyTo(
        CameraOptions(center: point, zoom: 15),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    _updateMap();
  }

  @override
  Widget build(BuildContext context) {
    CameraOptions cameraOptions = CameraOptions(zoom: 1);

    // Try to find a device with geocode to center on
    try {
      final deviceWithGeocode = widget.devices.firstWhere(
        (d) => d['geocode'] != null,
        orElse: () => null,
      );
      
      if (deviceWithGeocode != null) {
        final latLng = GeoCodingUtils.decodeLatLng(deviceWithGeocode['geocode']);
        cameraOptions = CameraOptions(
          center: Point(coordinates: Position(latLng.longitude, latLng.latitude)),
          zoom: 15,
        );
      }
    } catch (e) {
      // Fall back to world view
    }

    return MapWidget(
      cameraOptions: cameraOptions,
      onMapCreated: _onMapCreated,
      styleUri: MapboxStyles.MAPBOX_STREETS,
    );
  }

  @override
  void dispose() {
    mapboxMap?.annotations.removeAnnotationManager(circleAnnotationManager!);
    mapboxMap?.dispose();
    super.dispose();
  }
}