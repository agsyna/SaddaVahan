import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saadibus/models/detailedBusDetail.dart';
import 'package:saadibus/providers/availableBusScreenProvider.dart';
import 'package:saadibus/providers/homepageProvider.dart';
import 'package:saadibus/providers/loginScreenProvider.dart';
import 'package:saadibus/providers/recordingScreenProvider.dart';
import 'package:saadibus/screens/RecordingScreen.dart';
import 'package:saadibus/screens/availableBusScreen.dart';
import 'package:saadibus/screens/detailedBusScreen.dart';
import 'package:saadibus/screens/homepage.dart';
import 'package:saadibus/screens/login.dart';
import 'package:saadibus/screens/splashScreen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // what exactly will be the redirect logic??
  },
  routes: [
     GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
            GoRoute(
      path: "/login",
      builder: (context, state) {
        return ChangeNotifierProvider(
          create: (_) => LoginScreenProvider(),
          child: LoginScreen(),
        );
      },
    ),
    GoRoute(
      path: "/signup",
      builder: (context, state) {
        return ChangeNotifierProvider(
          create: (_) => LoginScreenProvider(),
          child: LoginScreen(),
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) {
        return ChangeNotifierProvider<HomepageProvider>(
          create: (_) => HomepageProvider(),
          child: HomeScreen(),
        );
      },
    ),
    GoRoute(
      path: "/availableBuses",
      builder: (context, state) {
        final pickupLocation = state.uri.queryParameters['pickup'] ?? '';
        final dropLocation = state.uri.queryParameters['drop'] ?? '';
        final pickupLat = double.tryParse(state.uri.queryParameters['pickupLat'] ?? '');
        final pickupLng = double.tryParse(state.uri.queryParameters['pickupLng'] ?? '');
        final dropLat = double.tryParse(state.uri.queryParameters['dropLat'] ?? '');
        final dropLng = double.tryParse(state.uri.queryParameters['dropLng'] ?? '');

        debugPrint('Pickup: $pickupLocation (${pickupLat}, ${pickupLng})');
        debugPrint('Drop: $dropLocation (${dropLat}, ${dropLng})');
        
        return ChangeNotifierProvider(
          create: (_) {
            final provider = AvailableBusScreenProvider();
            provider.pickupLocation = pickupLocation;
            provider.dropLocation = dropLocation;
            
            // Set coordinates if available
            if (pickupLat != null && pickupLng != null) {
              provider.pickupLat = pickupLat;
              provider.pickupLng = pickupLng;
            }
            if (dropLat != null && dropLng != null) {
              provider.dropLat = dropLat;
              provider.dropLng = dropLng;
            }
            
            return provider;
          },
          child: Availablebusscreen(),
        );
      },
    ),
    GoRoute(
      path: "/recording",
      builder: (context, state) {
        return ChangeNotifierProvider(
          create: (_) => RecordingScreenProvider(),
          child: RecordingScreen(),
        );
      },
    ),

    GoRoute(
      path: "/detailedBus",
      builder: (context, state) {
         final busDetail = state.extra as DetailedBusDetail;
        return DetailedBusScreen(detailedBusDetail: busDetail);
      },
    ),
  ],
);
