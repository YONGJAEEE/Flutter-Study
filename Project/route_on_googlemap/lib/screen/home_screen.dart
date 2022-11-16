import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_on_googlemap/utils/check_location_permission.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CameraPosition initialPosition;

  LatLng appleLatLng = const LatLng(
    37.3326935,
    -122.0110225,
  );

  List<LatLng> currentLocationList = []; // 위치 바뀔 때마다 저장
  Set<Polyline> polyLines = <Polyline>{};
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  PointLatLng? srcPoint;
  bool permissionAllow = false;
  GoogleMapController? mapController;

  @override
  void initState() {
    initialPosition = CameraPosition(target: appleLatLng, zoom: 13.5);
    setGeoLocatorStream();
    super.initState();
  }

  ///Permission 검사, Geolocator.getPositionStream 리스너 등록
  setGeoLocatorStream() async {
    await checkLocationPermission();
    setState(() {
      permissionAllow = true;
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 5),
      ),
    ).listen((event) {
      currentLocationList.add(LatLng(event.latitude, event.longitude));

      if (currentLocationList.length > 1) {
        srcPoint ??= PointLatLng(currentLocationList.first.latitude,
            currentLocationList.first.longitude);
        // 가장 마지막 최근에 기록된 위도경도를 destPoint로 지정
        PointLatLng destPoint = PointLatLng(
            currentLocationList[currentLocationList.length - 1].latitude,
            currentLocationList[currentLocationList.length - 1].longitude);
        final distance = Geolocator.distanceBetween(
            srcPoint!.latitude,
            srcPoint!.longitude,
            destPoint.latitude,
            destPoint.longitude); // m 단위로 return
        if (distance > 50) {
          // srcPoint와 destPoint가 250 이상으로 거리가 늘어났을 경우 실행
          initialPosition = CameraPosition(
              target: currentLocationList.last,
              zoom: 13.5); // 가장 마지막 위치로 initialPosition 변경
          _setPolyline(srcPoint: srcPoint!, destPoint: destPoint);
          srcPoint = PointLatLng(
            currentLocationList[currentLocationList.length - 2].latitude,
            currentLocationList[currentLocationList.length - 2].longitude,
          );
        }
      }
    });
  }

  onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (permissionAllow)
          ? GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: onMapCreated,
              initialCameraPosition: initialPosition,
              polylines: polyLines,
            )
          : Container(),
    );
  }

  void _setPolyline({
    required PointLatLng srcPoint,
    required PointLatLng destPoint,
  }) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyB3ocH1nB3VHLM0XxXw5B6lu7bSpkFq1kI",
      srcPoint,
      destPoint,
    );
    if (result.status == "OK") {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });

      setState(() {
        polyLines.add(
          Polyline(
            width: 10,
            polylineId: const PolylineId("polyline"),
            color: const Color(0xFF08A5CB),
            points: polylineCoordinates,
          ),
        );
      });
    }
  }
}
