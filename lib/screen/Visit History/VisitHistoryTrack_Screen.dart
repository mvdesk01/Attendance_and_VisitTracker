import 'dart:async';
import 'dart:math';
import 'dart:math' as math;

import 'package:attendance_system_ios/bloc/main_bloc.dart';
// import 'package:attendance_system_ios/model/VisitHistory/VisitLatLongListResponse.dart';
import 'package:attendance_system_ios/screen/Home/home.dart';
import 'package:attendance_system_ios/service/WebService.dart';
import 'package:attendance_system_ios/util/MyColor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import '../../model/VisitReport/VisitDetailedRecordsResponse.dart';

class VisitHistoryTrackScreen extends StatefulWidget {

  late List<Message> latLongList=[];
  VisitHistoryTrackScreen(
      {
        Key? key,
        required this.latLongList,
      })
      : super(key: key);

  @override
  _VisitHistoryTrackScreenState createState() => _VisitHistoryTrackScreenState();
}

class _VisitHistoryTrackScreenState extends State<VisitHistoryTrackScreen> {
  Completer<GoogleMapController> _controller = Completer();
  Polyline? _polyline;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    _markers.clear();
    _circles.clear();
    _polyline = null;
    // Ensure widgets are built before adding markers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMarkersonScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => (Navigator.canPop(context))
              ? Navigator.pop(context)
              : Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => MainBloc(webService: WebService()),
                child: HomeScreen(),
              ),
            ),
          ),
        ),
        title: const Text("Visit History"),
        backgroundColor: MyColors.lightBlue,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ).copyWith(color: Colors.white),
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => MainBloc(webService: WebService()),
                  child: HomeScreen(),
                ),
              ),
            );
            return false;
          }
          return true;
        },
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(18.5834, 73.7358),
                  zoom: 15.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                markers: _markers,
                circles: _circles,   // 👈 needed
                polylines: _polyline != null ? {_polyline!} : {},
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                myLocationEnabled: true,
                gestureRecognizers: {
                  Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                onTap: (LatLng location) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

///previous one working fine
  void _addMarkersonScreen() async {
    const double MIN_DISTANCE_THRESHOLD = 5.0;   // meters (ignore jitter)
   // const double MAX_JUMP_THRESHOLD = 100000.0;      // meters (ignore jumps)
    const int showEveryNth = 1;                   // set >1 to thin markers (e.g., 10)

    // Safe copy of the incoming list (widget.latLongList must be List<Message>)
    final List<Message> rawList = List<Message>.from(widget.latLongList ?? []);

    // Helper to parse timestamp from your Message
    DateTime _parseMessageTimestamp(Message m) {
      // Primary source: transactionTime (you store dd/MM/yyyy HH:mm:ss there)
      if (m.transactionTime != null && m.transactionTime!.trim().isNotEmpty) {
        final s = m.transactionTime!.trim();
        try {
          return DateFormat('dd/MM/yyyy HH:mm:ss').parseStrict(s);
        } catch (_) {
          try {
            return DateTime.parse(s); // fallback for ISO-like formats
          } catch (_) {}
        }
      }

      // Fallback: transactionDate (only date)
      if (m.transactionDate != null && m.transactionDate!.trim().isNotEmpty) {
        final s = m.transactionDate!.trim();
        try {
          return DateFormat('dd/MM/yyyy').parseStrict(s);
        } catch (_) {
          try {
            return DateTime.parse(s);
          } catch (_) {}
        }
      }

      // Last resort: epoch 0 so these sort first (or use DateTime.now())
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    // 1) Sort by parsed timestamp (ascending)
    rawList.sort((a, b) => _parseMessageTimestamp(a).compareTo(_parseMessageTimestamp(b)));

    // 2) Clean & filter points (ordered)
    List<LatLng> cleanedPoints = [];
    for (var msg in rawList) {
      final lat = double.tryParse(msg.latitude ?? '') ?? 0.0;
      final lng = double.tryParse(msg.longitude ?? '') ?? 0.0;

      // skip invalid coords
      if (lat == 0.0 && lng == 0.0) continue;

      final current = LatLng(lat, lng);

      if (cleanedPoints.isNotEmpty) {
        final last = cleanedPoints.last;
        final double distance = Geolocator.distanceBetween(
          last.latitude, last.longitude,
          current.latitude, current.longitude,
        );

        // skip jitter (too close) or impossible jumps (too far)
        if (distance < MIN_DISTANCE_THRESHOLD) continue;
        // if (distance > MAX_JUMP_THRESHOLD) {
        //   // optionally log: print("Skipping jump ${distance}m");
        //   continue;
        // }
      }

      cleanedPoints.add(current);
    }

    cleanedPoints = await radiusFilterPoints(cleanedPoints);
    // cleanedPoints = await removeSpikes(cleanedPoints);
    // cleanedPoints = await removeHistoricalSpikes(cleanedPoints);
    // cleanedPoints = await douglasPeucker(cleanedPoints, 0.0001);
    // cleanedPoints = await movingAverageSmoothing(cleanedPoints, 2);

    // 3) Build markers based on cleaned list
    final Set<Marker> newMarkers = <Marker>{};
    Set<Circle> newCircles = {};

    if (cleanedPoints.isNotEmpty) {
      if (cleanedPoints.length == 1) {
        // Single point: show a single marker (Start/End)
        newMarkers.add(
          Marker(
            markerId: const MarkerId('start_end'),
            position: cleanedPoints.first,
            infoWindow: const InfoWindow(title: 'Start / End'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      } else {
        // Start marker
        newMarkers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: cleanedPoints.first,
            infoWindow: const InfoWindow(title: 'Start'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );

        // Intermediate markers (thinned by showEveryNth if desired)
        for (int i = 1; i < cleanedPoints.length - 1; i++) {
          if ((i % showEveryNth) != 0) continue; // thinning
          newMarkers.add(
            Marker(
              markerId: MarkerId('point_$i'),
              position: cleanedPoints[i],
              infoWindow: InfoWindow(title: 'Point ${i + 1}'), // labels match chronological order
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            ),
          );
        }
/*        for (int i = 1; i < cleanedPoints.length - 1; i++) {
          if ((i % showEveryNth) != 0) continue; // thinning

          newCircles.add(
            Circle(
              circleId: CircleId('point_$i'),
              center: cleanedPoints[i],
              radius: 5, // meters; small so immt looks like a dot
              fillColor: Color..................................s.cyan,
              strokeColor: Colors.cyan,
              strokeWidth: 1,
            ),
          );
        }*/

        // End marker
        newMarkers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: cleanedPoints.last,
            infoWindow: const InfoWindow(title: 'End'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    // 4) Build a single polyline from cleanedPoints (ordered)
    final Polyline newPolyline = Polyline(
      polylineId: const PolylineId('route'),
      points: cleanedPoints,
      width: 4,
      // color: choose as you like; don't hardcode if you prefer to use theme
      color: Colors.green,
    );

    // 5) Update state in one go (avoids null-safety problems)
    setState(() {
      // Replace _markers and _polyline wholly — avoid calling clear() on nullable objects
      _markers = newMarkers;
      _circles = newCircles;   // 👈 important
      _polyline = newPolyline;
    });

    if (cleanedPoints.isNotEmpty) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: cleanedPoints.first, // 👈 start point
            zoom: 16.0,
          ),
        ),
      );
    }

    print("✅ Markers: ${newMarkers.length}, Polyline points: ${cleanedPoints.length}");
  }



  /// Helper to calculate LatLngBounds for camera
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double south = list.first.latitude;
    double north = list.first.latitude;
    double west = list.first.longitude;
    double east = list.first.longitude;

    for (var latLng in list) {
      if (latLng.latitude < south) south = latLng.latitude;
      if (latLng.latitude > north) north = latLng.latitude;
      if (latLng.longitude < west) west = latLng.longitude;
      if (latLng.longitude > east) east = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
  // void _addMarkersonScreen() async {
  //   const double MIN_DISTANCE_THRESHOLD = 5.0;   // meters (ignore jitter)
  //   const double MAX_JUMP_THRESHOLD = 1500.0;      // meters (ignore jumps)
  //   const int showEveryNth = 1;                   // set >1 to thin markers (e.g., 10)
  //   const double GAP_THRESHOLD = 50.0;           // meters, for dashed line
  //
  //   // Safe copy of the incoming list (widget.latLongList must be List<Message>)
  //   final List<Message> rawList = List<Message>.from(widget.latLongList ?? []);
  //
  //   // Helper to parse timestamp from your Message
  //   DateTime _parseMessageTimestamp(Message m) {
  //     if (m.transactionTime != null && m.transactionTime!.trim().isNotEmpty) {
  //       final s = m.transactionTime!.trim();
  //       try {
  //         return DateFormat('dd/MM/yyyy HH:mm:ss').parseStrict(s);
  //       } catch (_) {
  //         try {
  //           return DateTime.parse(s);
  //         } catch (_) {}
  //       }
  //     }
  //     if (m.transactionDate != null && m.transactionDate!.trim().isNotEmpty) {
  //       final s = m.transactionDate!.trim();
  //       try {
  //         return DateFormat('dd/MM/yyyy').parseStrict(s);
  //       } catch (_) {
  //         try {
  //           return DateTime.parse(s);
  //         } catch (_) {}
  //       }
  //     }
  //     return DateTime.fromMillisecondsSinceEpoch(0);
  //   }
  //
  //   // 1) Sort by parsed timestamp (ascending)
  //   rawList.sort((a, b) => _parseMessageTimestamp(a).compareTo(_parseMessageTimestamp(b)));
  //
  //   // 2) Clean & filter points (ordered)
  //   final List<LatLng> cleanedPoints = [];
  //   for (var msg in rawList) {
  //     final lat = double.tryParse(msg.latitude ?? '') ?? 0.0;
  //     final lng = double.tryParse(msg.longitude ?? '') ?? 0.0;
  //
  //     if (lat == 0.0 && lng == 0.0) continue;
  //
  //     final current = LatLng(lat, lng);
  //
  //     if (cleanedPoints.isNotEmpty) {
  //       final last = cleanedPoints.last;
  //       final double distance = Geolocator.distanceBetween(
  //         last.latitude, last.longitude,
  //         current.latitude, current.longitude,
  //       );
  //
  //       if (distance < MIN_DISTANCE_THRESHOLD) continue;
  //       if (distance > MAX_JUMP_THRESHOLD) {
  //         continue;
  //       }
  //     }
  //
  //     cleanedPoints.add(current);
  //   }
  //
  //   // 3) Build markers based on cleaned list
  //   final Set<Marker> newMarkers = <Marker>{};
  //   Set<Circle> newCircles = {};
  //
  //   if (cleanedPoints.isNotEmpty) {
  //     if (cleanedPoints.length == 1) {
  //       newMarkers.add(
  //         Marker(
  //           markerId: const MarkerId('start_end'),
  //           position: cleanedPoints.first,
  //           infoWindow: const InfoWindow(title: 'Start / End'),
  //           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
  //         ),
  //       );
  //     } else {
  //       newMarkers.add(
  //         Marker(
  //           markerId: const MarkerId('start'),
  //           position: cleanedPoints.first,
  //           infoWindow: const InfoWindow(title: 'Start'),
  //           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  //         ),
  //       );
  //
  //       for (int i = 1; i < cleanedPoints.length - 1; i++) {
  //         if ((i % showEveryNth) != 0) continue;
  //         newCircles.add(
  //           Circle(
  //             circleId: CircleId('point_$i'),
  //             center: cleanedPoints[i],
  //             radius: 5,
  //             fillColor: Colors.cyan,
  //             strokeColor: Colors.cyan,
  //             strokeWidth: 1,
  //           ),
  //         );
  //       }
  //
  //       newMarkers.add(
  //         Marker(
  //           markerId: const MarkerId('end'),
  //           position: cleanedPoints.last,
  //           infoWindow: const InfoWindow(title: 'End'),
  //           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  //         ),
  //       );
  //     }
  //   }
  //
  //   // 4) Build polylines with gap handling
  //   final Set<Polyline> newPolylines = {};
  //   int polyIdCounter = 1;
  //
  //   if (cleanedPoints.length > 1) {
  //     List<LatLng> currentSegment = [cleanedPoints.first];
  //
  //     for (int i = 1; i < cleanedPoints.length; i++) {
  //       final prev = cleanedPoints[i - 1];
  //       final curr = cleanedPoints[i];
  //
  //       final distance = Geolocator.distanceBetween(
  //         prev.latitude, prev.longitude,
  //         curr.latitude, curr.longitude,
  //       );
  //
  //       if (distance > GAP_THRESHOLD) {
  //         // close solid segment
  //         if (currentSegment.length > 1) {
  //           newPolylines.add(Polyline(
  //             polylineId: PolylineId('solid_$polyIdCounter'),
  //             points: List.from(currentSegment),
  //             width: 4,
  //             color: Colors.green,
  //           ));
  //           polyIdCounter++;
  //         }
  //
  //         // add dashed gap line
  //         newPolylines.add(Polyline(
  //           polylineId: PolylineId('gap_$polyIdCounter'),
  //           points: [prev, curr],
  //           width: 4,
  //           color: Colors.black,
  //           patterns: [PatternItem.dash(20), PatternItem.gap(10)],
  //         ));
  //         polyIdCounter++;
  //
  //         currentSegment = [curr];
  //       } else {
  //         currentSegment.add(curr);
  //       }
  //     }
  //
  //     if (currentSegment.length > 1) {
  //       newPolylines.add(Polyline(
  //         polylineId: PolylineId('solid_$polyIdCounter'),
  //         points: List.from(currentSegment),
  //         width: 4,
  //         color: Colors.green,
  //       ));
  //     }
  //   }
  //
  //   // 5) Update state
  //   setState(() {
  //     _markers = newMarkers;
  //     _circles = newCircles;
  //     _polylines = newPolylines; // 👈 now multiple polylines
  //   });
  //
  //   if (cleanedPoints.isNotEmpty) {
  //     final GoogleMapController controller = await _controller.future;
  //     controller.animateCamera(
  //       CameraUpdate.newCameraPosition(
  //         CameraPosition(
  //           target: cleanedPoints.first,
  //           zoom: 16.0,
  //         ),
  //       ),
  //     );
  //   }
  //
  //   print("✅ Markers: ${newMarkers.length}, Polyline points: ${cleanedPoints.length}, Polylines: ${newPolylines.length}");
  // }

  /// Integrating Below Code in this method, Douglas–Peucker for efficient downsampling + Moving Average for smoothness.
  Future<List<LatLng>> processRawPoints(List<LatLng> rawPoints) async {
    // Step 1: Simplify with Douglas–Peucker
    var simplified = douglasPeucker(rawPoints, 0.0001); // ~10m tolerance

    // Step 2: Smooth with Moving Average
    var smoothed = movingAverageSmoothing(simplified, 3);

    var radiusFilteredPoints = radiusFilterPoints(
      smoothed,
      minSeparationMeters: 5, // adjust between 10–25 to taste
    );

    // return smoothed;
    return radiusFilteredPoints;
  }

  // 1.
  double _perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    double dx = lineEnd.longitude - lineStart.longitude;
    double dy = lineEnd.latitude - lineStart.latitude;

    if (dx == 0 && dy == 0) {
      dx = point.longitude - lineStart.longitude;
      dy = point.latitude - lineStart.latitude;
      return sqrt(dx * dx + dy * dy);
    }

    double t = ((point.longitude - lineStart.longitude) * dx +
        (point.latitude - lineStart.latitude) * dy) /
        (dx * dx + dy * dy);

    if (t < 0) {
      dx = point.longitude - lineStart.longitude;
      dy = point.latitude - lineStart.latitude;
    } else if (t > 1) {
      dx = point.longitude - lineEnd.longitude;
      dy = point.latitude - lineEnd.latitude;
    } else {
      double nearX = lineStart.longitude + t * dx;
      double nearY = lineStart.latitude + t * dy;
      dx = point.longitude - nearX;
      dy = point.latitude - nearY;
    }

    return sqrt(dx * dx + dy * dy);
  }

  // 2. Douglas–Peucker Algorithm (Polyline Simplification), Accuracy → Still keeps shape of path (Douglas–Peucker).
  List<LatLng> douglasPeucker(List<LatLng> points, double epsilon) {
    if (points.length < 3) return points;

    double dmax = 0;
    int index = 0;
    for (int i = 1; i < points.length - 1; i++) {
      double d = _perpendicularDistance(points[i], points[0], points.last);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      var recResults1 = douglasPeucker(points.sublist(0, index + 1), epsilon);
      var recResults2 = douglasPeucker(points.sublist(index, points.length), epsilon);

      return recResults1.sublist(0, recResults1.length - 1) + recResults2;
    } else {
      return [points.first, points.last];
    }
  }

  // 3. Moving Average Filter (Smoothing Jitter), Smoothness → Removes GPS jumps (Moving Average).
  List<LatLng> movingAverageSmoothing(List<LatLng> points, int windowSize) {
    if (points.length < windowSize) return points;

    List<LatLng> smoothed = [];
    for (int i = 0; i < points.length; i++) {
      int start = max(0, i - windowSize);
      int end = min(points.length - 1, i + windowSize);

      double avgLat = 0;
      double avgLng = 0;
      int count = 0;

      for (int j = start; j <= end; j++) {
        avgLat += points[j].latitude;
        avgLng += points[j].longitude;
        count++;
      }

      smoothed.add(LatLng(avgLat / count, avgLng / count));
    }
    return smoothed;
  }

  /// Radius-based filter:
  /// Keeps only points that are at least [minSeparationMeters] apart
  /// from ALL previously kept points. Great for avoiding dense crossings.
  List<LatLng> radiusFilterPoints(
      List<LatLng> points, {
        double minSeparationMeters = 10, // tweak: 10–25m depending on density
      })
  {
    if (points.length <= 1) return points;

    final List<LatLng> filtered = [];

    for (final p in points) {
      bool tooClose = false;

      for (final kept in filtered) {
        final d = Geolocator.distanceBetween(
          p.latitude,
          p.longitude,
          kept.latitude,
          kept.longitude,
        );

        if (d < minSeparationMeters) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        filtered.add(p);
      }
    }

    return filtered;
  }

  /// 5. Spike detection filter
  /// Removes points that are big jumps compared to their neighbors.
  /// Example: prev & next are close, but current is far from both → spike.
  List<LatLng> removeSpikes(
      List<LatLng> points, {
        double spikeDistanceMeters = 20,      // how far is considered a spike
        double neighborMaxDistanceMeters = 25 // prev-next must be within this
      }) {
    if (points.length < 3) return points;

    final List<LatLng> filtered = [];
    filtered.add(points.first); // keep first

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      final double dPrevCurr = Geolocator.distanceBetween(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      );

      final double dCurrNext = Geolocator.distanceBetween(
        curr.latitude, curr.longitude,
        next.latitude, next.longitude,
      );

      final double dPrevNext = Geolocator.distanceBetween(
        prev.latitude, prev.longitude,
        next.latitude, next.longitude,
      );

      final bool isSpike =
          dPrevCurr > spikeDistanceMeters &&
              dCurrNext > spikeDistanceMeters &&
              dPrevNext < neighborMaxDistanceMeters;

      if (!isSpike) {
        filtered.add(curr);
      } else {
        // optional: debug log
        // print("🧹 Spike removed: $curr (prev-next close, this far)");
      }
    }

    filtered.add(points.last); // keep last
    return filtered;
  }

  /// 🔥 Strong spike remover:
  /// Removes points that are far from recent path but suddenly close to old path.
  /// Example: 36 is near, but 85/86 appear suddenly far from 84 & 87.
  List<LatLng> removeHistoricalSpikes(
      List<LatLng> points, {
        double farThreshold = 60,   // how far jump must be to be suspicious
        double nearOldThreshold = 20, // how close to ANY older point to consider spike
      }) {
    if (points.length < 4) return points;

    final List<LatLng> result = [];
    result.add(points.first);

    // Maintain a sliding window of "trusted path history"
    final List<LatLng> history = [points.first];

    for (int i = 1; i < points.length; i++) {
      final curr = points[i];
      final prev = result.last;

      // A) Check if curr is far from recent path (suspicious)
      final dPrevCurr = Geolocator.distanceBetween(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      );

      bool closeToOld = false;

      // B) Check if curr is very close to ANY old point → loopback spike
      for (final h in history) {
        final dOld = Geolocator.distanceBetween(
          curr.latitude, curr.longitude,
          h.latitude, h.longitude,
        );

        if (dOld < nearOldThreshold) {
          closeToOld = true;
          break;
        }
      }

      // If far from recent + close to old → spike
      if (dPrevCurr > farThreshold && closeToOld) {
        // print("🔥 Historical spike removed: $curr");
        continue;
      }

      // Otherwise keep point
      result.add(curr);
      history.add(curr);
    }

    return result;
  }

}



/*
double _calculateDistance(LatLng start, LatLng end) {
  const double R = 6371000; // Earth radius in meters
  double lat1 = start.latitude * (math.pi / 180);
  double lon1 = start.longitude * (math.pi / 180);
  double lat2 = end.latitude * (pi / 180);
  double lon2 = end.longitude * (pi / 180);

  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = pow(sin(dLat / 2), 2) +
      math.cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;  // Distance in meters
}
*/


///updated
//   void _addMarkersonScreen() async {
//     const double MIN_DISTANCE_THRESHOLD = 5.0;   // meters (ignore jitter)
//     const double MAX_TIME_GAP_HOURS = 4.0;       // Maximum allowed time gap
//     const int showEveryNth = 1;
//
//     final List<Message> rawList = List<Message>.from(widget.latLongList ?? []);
//
//     // Enhanced timestamp parser with better error handling
//     DateTime _parseMessageTimestamp(Message m) {
//       if (m.transactionTime != null && m.transactionTime!.trim().isNotEmpty) {
//         final s = m.transactionTime!.trim();
//         try {
//           return DateFormat('dd/MM/yyyy HH:mm:ss').parseStrict(s);
//         } catch (_) {
//           try {
//             return DateTime.parse(s);
//           } catch (_) {
//             // If parsing fails, try with common formats
//             try {
//               return DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(s);
//             } catch (_) {}
//           }
//         }
//       }
//
//       if (m.transactionDate != null && m.transactionDate!.trim().isNotEmpty) {
//         final s = m.transactionDate!.trim();
//         try {
//           return DateFormat('dd/MM/yyyy').parseStrict(s);
//         } catch (_) {
//           try {
//             return DateTime.parse(s);
//           } catch (_) {}
//         }
//       }
//
//       return DateTime.fromMillisecondsSinceEpoch(0);
//     }
//
//     // 1) Sort by parsed timestamp (ascending)
//     rawList.sort((a, b) => _parseMessageTimestamp(a).compareTo(_parseMessageTimestamp(b)));
//
//     // 2) Clean & filter points with time-based filtering
//     final List<LatLng> cleanedPoints = [];
//     DateTime? lastTimestamp;
//
//     for (var msg in rawList) {
//       final lat = double.tryParse(msg.latitude ?? '') ?? 0.0;
//       final lng = double.tryParse(msg.longitude ?? '') ?? 0.0;
//
//       // skip invalid coords
//       if (lat == 0.0 && lng == 0.0) continue;
//
//       final current = LatLng(lat, lng);
//       final currentTimestamp = _parseMessageTimestamp(msg);
//
//       if (cleanedPoints.isNotEmpty && lastTimestamp != null) {
//         final double distance = Geolocator.distanceBetween(
//           cleanedPoints.last.latitude, cleanedPoints.last.longitude,
//           current.latitude, current.longitude,
//         );
//
//         final double timeDiffHours = currentTimestamp.difference(lastTimestamp).inMinutes / 60.0;
//
//         // skip jitter (too close)
//         if (distance < MIN_DISTANCE_THRESHOLD) continue;
//
//         // Skip points with large time gaps (indicating GPS dropouts or device changes)
//         if (timeDiffHours > MAX_TIME_GAP_HOURS) {
//           print("Skipping point with time gap: ${timeDiffHours.toStringAsFixed(2)} hours");
//           continue;
//         }
//
//         // Additional safety check: if time gap is large AND distance is large, likely a jump
//         if (timeDiffHours > 1.0 && distance > 5000) { // 1+ hour gap and >5km distance
//           print("Skipping unreasonable jump: ${distance.toStringAsFixed(2)}m in ${timeDiffHours.toStringAsFixed(2)}h");
//           continue;
//         }
//       }
//
//       cleanedPoints.add(current);
//       lastTimestamp = currentTimestamp;
//     }
//
//     // 3) Build markers based on cleaned list
//     final Set<Marker> newMarkers = <Marker>{};
//     Set<Circle> newCircles = {};
//
//     if (cleanedPoints.isNotEmpty) {
//       if (cleanedPoints.length == 1) {
//         // Single point: show a single marker (Start/End)
//         newMarkers.add(
//           Marker(
//             markerId: const MarkerId('start_end'),
//             position: cleanedPoints.first,
//             infoWindow: const InfoWindow(title: 'Start / End'),
//             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//           ),
//         );
//       } else {
//         // Start marker
//         newMarkers.add(
//           Marker(
//             markerId: const MarkerId('start'),
//             position: cleanedPoints.first,
//             infoWindow: const InfoWindow(title: 'Start'),
//             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//           ),
//         );
//
//         // Intermediate circles
//         for (int i = 1; i < cleanedPoints.length - 1; i++) {
//           if ((i % showEveryNth) != 0) continue;
//
//           newCircles.add(
//             Circle(
//               circleId: CircleId('point_$i'),
//               center: cleanedPoints[i],
//               radius: 5,
//               fillColor: Colors.cyan,
//               strokeColor: Colors.cyan,
//               strokeWidth: 1,
//             ),
//           );
//         }
//
//         // End marker
//         newMarkers.add(
//           Marker(
//             markerId: const MarkerId('end'),
//             position: cleanedPoints.last,
//             infoWindow: const InfoWindow(title: 'End'),
//             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           ),
//         );
//       }
//     }
//
//     // 4) Build a single polyline from cleanedPoints (ordered)
//     final Polyline newPolyline = Polyline(
//       polylineId: const PolylineId('route'),
//       points: cleanedPoints,
//       width: 4,
//       color: Colors.green,
//     );
//
//     // 5) Update state
//     setState(() {
//       _markers = newMarkers;
//       _circles = newCircles;
//       _polyline = newPolyline;
//     });
//
//     if (cleanedPoints.isNotEmpty) {
//       final GoogleMapController controller = await _controller.future;
//       controller.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: cleanedPoints.first,
//             zoom: 16.0,
//           ),
//         ),
//       );
//     }
//
//     print("✅ Markers: ${newMarkers.length}, Polyline points: ${cleanedPoints.length}");
//     print("⏰ Time-based filtering applied (max gap: ${MAX_TIME_GAP_HOURS}h)");
//   }

// old working fine
/*void _addMarkersonScreen() {
    List<Message> validLatLongList = widget.latLongList.where((latLong) =>
    latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();

    List<LatLng> polylinePoints = [];
    print("validLatLongList Size ---> ${validLatLongList.length}");

    int markerId = 1;

    // ✅ Clear previous markers and polyline before adding new ones
    setState(() {
      _markers.clear();
      _polyline = null; // Reset polyline

      for (var latLong in validLatLongList) {
        final latLng = LatLng(double.parse(latLong.latitude!), double.parse(latLong.longitude!));

        _markers.add(
          Marker(
            markerId: MarkerId('marker_$markerId'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Marker $markerId'),
          ),
        );
        polylinePoints.add(latLng);
        markerId++;
      }

      // ✅ Add new polyline with valid points
      if (polylinePoints.isNotEmpty) {
        _polyline = Polyline(
          polylineId: const PolylineId("route"),
          points: polylinePoints,
          color: Colors.green,
          width: 5,
        );
      }
    });
  }*/

// void _addMarkersonScreen() async {
//   // Step 1: Clean raw lat/longs
//   List<Message> validLatLongList = widget.latLongList.where((latLong) =>
//   latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();
//
//   print("validLatLongList Size ---> ${validLatLongList.length}");
//
//   List<LatLng> rawPoints = validLatLongList
//       .map((latLong) => LatLng(
//     double.parse(latLong.latitude!),
//     double.parse(latLong.longitude!),
//   ))
//       .toList();
//
//   // Step 2: Remove duplicate consecutive points
//   List<LatLng> cleanedPoints = [];
//   for (int i = 0; i < rawPoints.length; i++) {
//     if (i == 0 || rawPoints[i] != rawPoints[i - 1]) {
//       cleanedPoints.add(rawPoints[i]);
//     }
//   }
//
//   // Step 3: Use processRawPoints for simplification + smoothing
//   List<LatLng> finalPoints = await processRawPoints(cleanedPoints);
//
//   print("Processed polyline points ---> ${finalPoints.length}");
//
//   // Step 4: Update map UI
//   setState(() {
//     _markers.clear();
//     _polyline = null;
//
//     if (finalPoints.isNotEmpty) {
//       // Add start + end markers
//       _markers.add(
//         Marker(
//           markerId: const MarkerId("start"),
//           position: finalPoints.first,
//           infoWindow: const InfoWindow(title: "Start"),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//         ),
//       );
//       _markers.add(
//         Marker(
//           markerId: const MarkerId("end"),
//           position: finalPoints.last,
//           infoWindow: const InfoWindow(title: "End"),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         ),
//       );
//
//       // Draw path polyline
//       _polyline = Polyline(
//         polylineId: const PolylineId("route"),
//         points: finalPoints,
//         color: Colors.blue,
//         width: 5,
//       );
//     }
//   });
// }
///
//   void _addMarkersonScreen() async {
//     const double min_distance = 30.0;
//     // Step 1: Clean raw lat/longs
//     List<Message> validLatLongList = widget.latLongList.where((latLong) =>
//     latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();
//
//     List<LatLng> polylines = [];
//     int markerid = 1;
//     LatLng? lastlatLang;
//
//
//
//     print("validLatLongList Size ---> ${validLatLongList.length}");
//     List<LatLng> rawPoints = validLatLongList
//         .map((latLong) => LatLng(
//       double.parse(latLong.latitude!),
//       double.parse(latLong.longitude!),
//     ))
//         .toList();
//
//     // Step 2: Remove duplicate consecutive points
//     List<LatLng> cleanedPoints = [];
//     for (int i = 0; i < rawPoints.length; i++) {
//       if (i == 0 || rawPoints[i] != rawPoints[i - 1]) {
//         cleanedPoints.add(rawPoints[i]);
//       }
//     }
//
//     // Step 3: Use processRawPoints for simplification + smoothing
//     List<LatLng> finalPoints = await processRawPoints(cleanedPoints);
//
//     print("Processed polyline points ---> ${finalPoints.length}");
//
//     // Step 4: Update map UI
//     // setState(() {
//     //   _markers.clear();
//     //   _polyline = null;
//     //
//     //   if (finalPoints.isNotEmpty) {
//     //     // Always add Start marker
//     //     _markers.add(
//     //       Marker(
//     //         markerId: const MarkerId("start"),
//     //         position: finalPoints.first,
//     //         infoWindow: const InfoWindow(title: "Start"),
//     //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//     //       ),
//     //     );
//     //
//     //     // Add intermediate markers every Nth point
//     //     const int step = 20; // adjust: smaller = more markers, larger = fewer
//     //     for (int i = step; i < finalPoints.length - 1; i += step) {
//     //       _markers.add(
//     //         Marker(
//     //           markerId: MarkerId("point_$i"),
//     //           position: finalPoints[i],
//     //           infoWindow: InfoWindow(title: "Point $i"),
//     //           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//     //         ),
//     //       );
//     //     }
//     //
//     //     // Always add End marker
//     //     _markers.add(
//     //       Marker(
//     //         markerId: const MarkerId("end"),
//     //         position: finalPoints.last,
//     //         infoWindow: const InfoWindow(title: "End"),
//     //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//     //       ),
//     //     );
//     //
//     //     // Draw path polyline
//     //     _polyline = Polyline(
//     //       polylineId: const PolylineId("route"),
//     //       points: finalPoints,
//     //       color: Colors.blue,
//     //       width: 5,
//     //     );
//     //   }
//     // });
//
//     setState(() {
//       _markers.clear();
//       _polyline = null;
//
//
//       if (finalPoints.isNotEmpty) {
//         _markers.add(
//           Marker(markerId: MarkerId('marker_$markerid'),
//             position: cu
//           )
//
//         );
//         //       // Add start + end markers
//               _markers.add(
//                 Marker(
//                   markerId: const MarkerId("start"),
//                   position: finalPoints.first,
//                   infoWindow: const InfoWindow(title: "Start"),
//                   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//                 ),
//               );
//               _markers.add(
//                 Marker(
//                   markerId: const MarkerId("end"),
//                   position: finalPoints.last,
//                   infoWindow: const InfoWindow(title: "End"),
//                   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//                 ),
//               );
//
//               // Draw path polyline
//               _polyline = Polyline(
//                 polylineId: const PolylineId("route"),
//                 points: finalPoints,
//                 color: Colors.blue,
//                 width: 5,
//               );
//             }
//     });
//   }


/// Working Refine method for Smoothing Tracking on Map
/*  void _addMarkersonScreen() {
    //	Filter invalid points.
    List<Message> validLatLongList = widget.latLongList.where((latLong) =>
    latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();

    print("validLatLongList Size ---> ${validLatLongList.length}");

    // Convert to LatLng
    List<LatLng> rawPoints = validLatLongList
        .map((latLong) => LatLng(
      double.parse(latLong.latitude!),
      double.parse(latLong.longitude!),
    ))
        .toList();

    // ✅ Step 1: Remove duplicate consecutive points
    List<LatLng> cleanedPoints = [];
    for (int i = 0; i < rawPoints.length; i++) {
      if (i == 0 || rawPoints[i] != rawPoints[i - 1]) {
        cleanedPoints.add(rawPoints[i]);
      }
    }

    // ✅ Step 2: Smooth path (moving average of 3 points)
    List<LatLng> smoothedPoints = [];
    for (int i = 0; i < cleanedPoints.length; i++) {
      if (i == 0 || i == cleanedPoints.length - 1) {
        smoothedPoints.add(cleanedPoints[i]); // keep endpoints
      } else {
        double avgLat = (cleanedPoints[i - 1].latitude +
            cleanedPoints[i].latitude +
            cleanedPoints[i + 1].latitude) /
            3;
        double avgLng = (cleanedPoints[i - 1].longitude +
            cleanedPoints[i].longitude +
            cleanedPoints[i + 1].longitude) /
            3;
        smoothedPoints.add(LatLng(avgLat, avgLng));
      }
    }

    // ✅ Step 3: Optional simplification (skip very close points <5m apart)
    List<LatLng> finalPoints = [];
    const double minDistanceMeters = 5.0;
    LatLng? lastKept;
    for (var p in smoothedPoints) {
      if (lastKept == null) {
        finalPoints.add(p);
        lastKept = p;
      } else {
        double distance = _calculateDistance(lastKept, p);
        if (distance > minDistanceMeters) {
          finalPoints.add(p);
          lastKept = p;
        }
      }
    }

    print("Smoothed polyline points ---> ${finalPoints.length}");

    // ✅ Update markers and polyline
    setState(() {
      _markers.clear();
      _polyline = null;

      int markerId = 1;
      for (var latLng in finalPoints) {
        _markers.add(
          Marker(
            markerId: MarkerId('marker_$markerId'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Marker $markerId'),
          ),
        );
        markerId++;
      }

      if (finalPoints.isNotEmpty) {
        _polyline = Polyline(
          polylineId: const PolylineId("route"),
          points: finalPoints,
          color: Colors.green,
          width: 5,
        );
      }
    });
  }

  /// Haversine formula to calculate distance in meters
  double _calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // Earth radius in meters
    double dLat = _degToRad(p2.latitude - p1.latitude);
    double dLon = _degToRad(p2.longitude - p1.longitude);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_degToRad(p1.latitude)) *
                cos(_degToRad(p2.latitude)) *
                (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);*/

/// old 1
/*  void _addMarkersonScreen() {
    List<Message> validLatLongList = widget.latLongList.where((latLong) =>
    latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();

    List<LatLng> polylinePoints = [];
    print("validLatLongList Size ---> ${validLatLongList.length}");

    int markerId = 1;

    // Use setState to update markers and polylines
    setState(() {
      for (var latLong in validLatLongList) {
        final latLng = LatLng(double.parse(latLong.latitude!), double.parse(latLong.longitude!));

        _markers.add(
          Marker(
            markerId: MarkerId('marker_$markerId'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Marker $markerId'),
          ),
        );
        polylinePoints.add(latLng);
        markerId++;
      }

      // Update Polyline with valid points
      if (polylinePoints.isNotEmpty) {
        _polyline = Polyline(
          polylineId: const PolylineId("route"),
          points: polylinePoints,
          color: Colors.green,
          width: 5,
        );
      }
    });
  }*/

/// old 2
/*
  void _addMarkersonScreen() {
    List<Message> validLatLongList = widget.latLongList.where((latLong) =>
    latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();

    List<LatLng> polylinePoints = [];
    print("validLatLongList Size ---> ${validLatLongList.length}");

    int markerId = 1;

    // ✅ Clear previous markers and polyline before adding new ones
    setState(() {
      _markers.clear();
      _polyline = null; // Reset polyline

      for (var latLong in validLatLongList) {
        final latLng = LatLng(double.parse(latLong.latitude!), double.parse(latLong.longitude!));

        _markers.add(
          Marker(
            markerId: MarkerId('marker_$markerId'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Marker $markerId'),
          ),
        );
        polylinePoints.add(latLng);
        markerId++;
      }

      // ✅ Add new polyline with valid points
      if (polylinePoints.isNotEmpty) {
        _polyline = Polyline(
          polylineId: const PolylineId("route"),
          points: polylinePoints,
          color: Colors.green,
          width: 5,
        );
      }
    });
  }
*/


/// working addmarker screen
/*void _addMarkersonScreen() async {
    // Step 1: Clean raw lat/longs
    const double MIN_DISTANCE_THRESHOLD = 50.0;
    List<Message> validLatLongList = widget.latLongList.where((latLong) =>
    latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();

    List<LatLng> polylinePoints = [];
    print("validLatLongList Size ---> ${validLatLongList.length}");

    int markerId = 1;
    LatLng? lastLatLng;

    print("validLatLongList Size ---> ${validLatLongList.length}");

    List<LatLng> rawPoints = validLatLongList
        .map((latLong) => LatLng(
      double.parse(latLong.latitude!),
      double.parse(latLong.longitude!),
    ))
        .toList();

    // Step 2: Remove duplicate consecutive points
    List<LatLng> cleanedPoints = [];
    for (int i = 0; i < rawPoints.length; i++) {
      if (i == 0 || rawPoints[i] != rawPoints[i - 1]) {
        cleanedPoints.add(rawPoints[i]);
      }
    }

    // Step 3: Simplify + Smooth
    List<LatLng> finalPoints = await processRawPoints(cleanedPoints);

    print("Processed polyline points ---> ${finalPoints.length}");

    // Step 4: Update map UI
    // setState(() {
    //   _markers.clear();
    //   _polyline = null;
    //
    //   if (finalPoints.isNotEmpty) {
    //     int markerId = 1;
    //     LatLng? lastLatLng;
    //
    //     // 🔹 Add intermediate markers at distance threshold
    //     const double MIN_DISTANCE_THRESHOLD = 70.0; // meters
    //     for (var point in finalPoints) {
    //       if (lastLatLng != null) {
    //         double distance = Geolocator.distanceBetween(
    //             lastLatLng.latitude, lastLatLng.longitude,
    //             point.latitude, point.longitude);
    //
    //         if (distance < MIN_DISTANCE_THRESHOLD) {
    //           continue; // skip close points
    //         }
    //       }
    //
    //       _markers.add(
    //         Marker(
    //           markerId: MarkerId('marker_$markerId'),
    //           position: point,
    //           infoWindow: InfoWindow(title: 'Marker $markerId'),
    //         ),
    //       );
    //       lastLatLng = point;
    //       markerId++;
    //     }
    //
    //     // 🔹 Add Start & End markers with colors
    //     _markers.add(
    //       Marker(
    //         markerId: const MarkerId("start"),
    //         position: finalPoints.first,
    //         infoWindow: const InfoWindow(title: "Start"),
    //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    //       ),
    //     );
    //     _markers.add(
    //       Marker(
    //         markerId: const MarkerId("end"),
    //         position: finalPoints.last,
    //         infoWindow: const InfoWindow(title: "End"),
    //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    //       ),
    //     );
    //
    //     // 🔹 Draw polyline
    //     _polyline = Polyline(
    //       polylineId: const PolylineId("route"),
    //       points: finalPoints,
    //       color: Colors.blue,
    //       width: 5,
    //     );
    //   }
    // });

    setState(() {
      _markers.clear();
      _polyline = null;

      for (var latLong in validLatLongList) {
        final currentLatLng = LatLng(
          double.parse(latLong.latitude!),
          double.parse(latLong.longitude!),
        );

        // ✅ Filter by distance to avoid zigzag
        if (lastLatLng != null) {
          double distance = _calculateDistance(lastLatLng!, currentLatLng);

          if (distance < MIN_DISTANCE_THRESHOLD) {
            print("Skipping small movement: $distance meters");
            continue;  // Skip adding this point
          }
        }

        // ✅ Add marker and polyline point
        _markers.add(
          Marker(
            markerId: MarkerId('marker_$markerId'),
            position: currentLatLng,
            infoWindow: InfoWindow(title: 'Marker $markerId'),
          ),
        );
        polylinePoints.add(currentLatLng);
        lastLatLng = currentLatLng;
        markerId++;
      }

      // ✅ Add new polyline with filtered points
      if (polylinePoints.isNotEmpty) {
        _polyline = Polyline(
          polylineId: const PolylineId("route"),
          points: polylinePoints,
          color: Colors.green,
          width: 5,
        );
      }
    });
  }*/

// void _addMarkersonScreen() async {
//   // Step 1: Filter valid lat/longs
//   List<Message> validLatLongList = widget.latLongList.where((latLong) =>
//   latLong.latitude != "0.0" && latLong.longitude != "0.0").toList();
//
//   print("validLatLongList Size ---> ${validLatLongList.length}");
//
//   // Convert to LatLng
//   List<LatLng> rawPoints = validLatLongList
//       .map((latLong) => LatLng(
//     double.parse(latLong.latitude!),
//     double.parse(latLong.longitude!),
//   ))
//       .toList();
//
//   // Step 2: Remove duplicate consecutive points
//   List<LatLng> cleanedPoints = [];
//   for (int i = 0; i < rawPoints.length; i++) {
//     if (i == 0 || rawPoints[i] != rawPoints[i - 1]) {
//       cleanedPoints.add(rawPoints[i]);
//     }
//   }
//
//   // Step 3: Apply smoothing/cleaning (optional if you already have processRawPoints)
//   List<LatLng> finalPoints = await processRawPoints(cleanedPoints);
//   print("Processed polyline points ---> ${finalPoints.length}");
//
//   // Step 4: Update map
//   setState(() {
//     _markers.clear();
//     _polyline = null;
//
//     int markerId = 1;
//
//     // 🔹 Add intermediate markers for *all* points
//     for (var point in finalPoints) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId('marker_$markerId'),
//           position: point,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // red breadcrumb marker
//           infoWindow: InfoWindow(title: 'Point $markerId'),
//         ),
//       );
//       markerId++;
//     }
//
//     // 🔹 Add Start & End markers with distinct colors
//     if (finalPoints.isNotEmpty) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId("start"),
//           position: finalPoints.first,
//           infoWindow: const InfoWindow(title: "Start"),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//         ),
//       );
//       _markers.add(
//         Marker(
//           markerId: const MarkerId("end"),
//           position: finalPoints.last,
//           infoWindow: const InfoWindow(title: "End"),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//         ),
//       );
//
//       // 🔹 Draw polyline
//       _polyline = Polyline(
//         polylineId: const PolylineId("route"),
//         points: finalPoints,
//         color: Colors.blue,
//         width: 5,
//       );
//     }
//   });
// }