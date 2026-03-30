import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/superadmin/superadmin_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data (required for DateFormat with 'id_ID')
  await initializeDateFormatting('id_ID', null);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize connectivity service
  await ConnectivityService().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRANATA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      // Wrap ALL screens with MobilePreviewWrapper
      builder: (context, child) {
        return MobilePreviewWrapper(child: child ?? const SizedBox());
      },
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!authProvider.isLoggedIn) {
            return const WelcomeScreen();
          }

          // SuperAdmin → dashboard khusus (tetap pakai theme Navy-Gold default)
          if (authProvider.isSuperAdmin) {
            return const SuperAdminDashboardScreen();
          }

          // Admin Dinas / Member → HomeScreen dibungkus tema dinasnya
          return Theme(
            data: DinasTheme.getTheme(authProvider.dinasId),
            child: const HomeScreen(),
          );
        },
      ),
    );
  }
}

// Mobile Preview Wrapper - Responsive untuk desktop dan mobile
class MobilePreviewWrapper extends StatelessWidget {
  final Widget child;
  
  const MobilePreviewWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Jika lebar layar < 500px, anggap sudah mobile - tampilkan fullscreen
        if (constraints.maxWidth < 500) {
          return child;
        }
        
        // Jika desktop, tampilkan dengan frame iPhone
        return Scaffold(
          backgroundColor: const Color(0xFF1a1a1a),
          body: Center(
            child: Container(
              width: 390, // iPhone 14 width
              height: 844, // iPhone 14 height
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.9,
                maxHeight: constraints.maxHeight * 0.95,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
