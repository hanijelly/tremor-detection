import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'database_helper.dart';
import 'tremor_detector.dart';
import 'tremor_event.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'tremor_history_screen.dart';

void main() {
  runApp(const TremorDetectionApp());
}

class TremorDetectionApp extends StatelessWidget {
  const TremorDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tremor Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Splash Screen with First-Time Tutorial
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkFirstTime();
  }
  
  void checkFirstTime() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;
    
    if (!mounted) return;
    
    if (isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TutorialScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BluetoothScanScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tremor Detection',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monitoring your health',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Tutorial Screen for First-Time Users
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<TutorialPage> pages = [
    TutorialPage(
      icon: Icons.bluetooth,
      title: 'Connect Your Device',
      description: 'Pair your ESP32 tremor detection wearable via Bluetooth to start monitoring.',
    ),
    TutorialPage(
      icon: Icons.analytics,
      title: 'Real-Time Monitoring',
      description: 'View live accelerometer data and get instant notifications when tremors are detected.',
    ),
    TutorialPage(
      icon: Icons.history,
      title: 'Track Your Progress',
      description: 'Review your tremor history, see trends over time, and share data with your doctor.',
    ),
    TutorialPage(
      icon: Icons.settings,
      title: 'Customize Settings',
      description: 'Adjust sensitivity, frequency range, and notification preferences to suit your needs.',
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 60),
                  
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  
                  ElevatedButton(
                    onPressed: () async {
                      if (_currentPage == pages.length - 1) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('first_time', false);
                        
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BluetoothScanScreen(),
                          ),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_currentPage == pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPage(TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: 120,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  
  TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  String statusMessage = 'Initializing...';
  StreamSubscription? scanSubscription;

  @override
  void initState() {
    super.initState();
    checkBluetoothAndScan();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  void checkBluetoothAndScan() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        setState(() {
          statusMessage = 'Bluetooth not available on this device';
        });
        return;
      }

      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        setState(() {
          statusMessage = 'Please turn on Bluetooth';
        });
        return;
      }

      startScan();
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
      });
    }
  }

  void startScan() async {
    try {
      setState(() {
        isScanning = true;
        scanResults = [];
        statusMessage = 'Scanning for devices...';
      });

      await scanSubscription?.cancel();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true,
      );

      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });

      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      
      setState(() {
        isScanning = false;
        if (scanResults.isEmpty) {
          statusMessage = 'No devices found. Make sure your device is powered on.';
        } else {
          statusMessage = 'Found ${scanResults.length} device(s)';
        }
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        statusMessage = 'Scan failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tremor Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: 'Tremor History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TremorHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'All Readings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isScanning ? null : startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isScanning 
                    ? [Colors.blue.shade100, Colors.blue.shade200]
                    : [Colors.grey.shade200, Colors.grey.shade300],
              ),
            ),
            child: Row(
              children: [
                if (isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isScanning ? 'Scanning for devices...' : 'No devices found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!isScanning)
                          Text(
                            'Make sure your device is powered on and nearby',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (!isScanning) ...[
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: startScan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Scan Again'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: scanResults.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final result = scanResults[index];
                      final deviceName = result.device.platformName.isEmpty
                          ? 'Unknown Device'
                          : result.device.platformName;
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bluetooth,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            deviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.device.remoteId.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.signal_cellular_alt,
                                    size: 14,
                                    color: _getSignalColor(result.rssi),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${result.rssi} dBm',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getSignalColor(result.rssi),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DataDisplayScreen(
                                  device: result.device,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}

// Keep your existing DataDisplayScreen and HistoryScreen classes
// I'll update DataDisplayScreen in the next message to improve it

class DataDisplayScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DataDisplayScreen({super.key, required this.device});

  @override
  State<DataDisplayScreen> createState() => _DataDisplayScreenState();
}

class _DataDisplayScreenState extends State<DataDisplayScreen> {
  final TremorDetector tremorDetector = TremorDetector();
  bool currentlyInTremor = false;
  DateTime? tremorStartTime;
  TremorAnalysis? lastAnalysis;
  bool alertsEnabled = true;
  
  final FlutterLocalNotificationsPlugin notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  bool isConnected = false;
  bool isConnecting = true;
  double xValue = 0;
  double yValue = 0;
  double zValue = 0;
  double magnitude = 0;
  String statusMessage = 'Connecting to device...';
  BluetoothCharacteristic? targetCharacteristic;
  StreamSubscription? characteristicSubscription;
  
  List<FlSpot> xDataPoints = [];
  List<FlSpot> yDataPoints = [];
  List<FlSpot> zDataPoints = [];
  double timeCounter = 0;
  
  List<AccelerometerReading> recentReadings = [];
  final int maxDisplayPoints = 50;
  
  int tremorCountToday = 0;

  @override
  void initState() {
    super.initState();
    connectToDevice();
    loadRecentReadings();
    initializeNotifications();
    loadSettings();
    loadTodayTremorCount();
  }
  
  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      alertsEnabled = prefs.getBool('alerts_enabled') ?? true;
    });
    
    // Apply saved detector settings
    TremorDetector.updateSettings(
      newThreshold: prefs.getDouble('tremor_threshold') ?? 0.15,
      newMinFreq: prefs.getDouble('min_frequency') ?? 4.0,
      newMaxFreq: prefs.getDouble('max_frequency') ?? 12.0,
    );
  }
  
  void loadTodayTremorCount() async {
    final events = await DatabaseHelper.instance.getAllTremorEvents();
    final today = DateTime.now();
    final todayEvents = events.where((e) {
      return e.timestamp.year == today.year &&
             e.timestamp.month == today.month &&
             e.timestamp.day == today.day;
    }).toList();
    
    setState(() {
      tremorCountToday = todayEvents.length;
    });
  }

  void initializeNotifications() async {
    const initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await notificationsPlugin.initialize(initializationSettings);
    
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void loadRecentReadings() async {
    final readings = await DatabaseHelper.instance.getRecentReadings(10);
    setState(() {
      recentReadings = readings;
    });
  }

  void connectToDevice() async {
    try {
      await widget.device.connect(timeout: const Duration(seconds: 10));
      
      setState(() {
        isConnected = true;
        isConnecting = false;
        statusMessage = 'Connected! Discovering services...';
      });

      List<BluetoothService> services = await widget.device.discoverServices();

      bool foundCharacteristic = false;
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.read) {
            targetCharacteristic = characteristic;
            foundCharacteristic = true;
            
            await characteristic.setNotifyValue(true);
            
            characteristicSubscription = characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                String dataString = utf8.decode(value);
                parseData(dataString);
              }
            });
            
            setState(() {
              statusMessage = 'Receiving data';
            });
            
            break;
          }
        }
        if (foundCharacteristic) break;
      }
    } catch (e) {
      setState(() {
        isConnecting = false;
        isConnected = false;
        statusMessage = 'Connection failed: $e';
      });
    }
  }

  Future<void> showTremorNotification(TremorAnalysis analysis) async {
    if (!alertsEnabled) return;
    
    const androidDetails = AndroidNotificationDetails(
      'tremor_channel',
      'Tremor Alerts',
      channelDescription: 'Notifications for detected tremors',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await notificationsPlugin.show(
      0,
      '⚠️ Tremor Detected',
      '${analysis.severity} tremor at ${analysis.dominantFrequency.toStringAsFixed(1)} Hz',
      notificationDetails,
    );
  }
  
  void parseData(String data) async {
    try {
      List<String> values = data.trim().split(',');
      if (values.length >= 3) {
        double x = double.tryParse(values[0].trim()) ?? 0;
        double y = double.tryParse(values[1].trim()) ?? 0;
        double z = double.tryParse(values[2].trim()) ?? 0;
        
        double mag = sqrt(x * x + y * y + z * z);
        
        tremorDetector.addDataPoint(x, y, z);
        
        TremorAnalysis? analysis = tremorDetector.analyzeWindow();

        if (analysis != null) {
          lastAnalysis = analysis;
          
          if (analysis.isTremor && !currentlyInTremor) {
            currentlyInTremor = true;
            tremorStartTime = DateTime.now();
            
            await showTremorNotification(analysis);
            
            setState(() {
              tremorCountToday++;
            });
          } else if (!analysis.isTremor && currentlyInTremor) {
            currentlyInTremor = false;
            
            if (tremorStartTime != null) {
              double duration = DateTime.now().difference(tremorStartTime!).inSeconds.toDouble();
              
              final event = TremorEvent(
                timestamp: tremorStartTime!,
                magnitude: lastAnalysis!.power,
                duration: duration,
                severity: lastAnalysis!.severity,
              );
              
              await DatabaseHelper.instance.insertTremorEvent(event);
            }
            
            tremorStartTime = null;
          }
        }
        
        setState(() {
          xValue = x;
          yValue = y;
          zValue = z;
          magnitude = mag;
          
          timeCounter += 0.1;
          xDataPoints.add(FlSpot(timeCounter, x));
          yDataPoints.add(FlSpot(timeCounter, y));
          zDataPoints.add(FlSpot(timeCounter, z));
          
          if (xDataPoints.length > maxDisplayPoints) {
            xDataPoints.removeAt(0);
            yDataPoints.removeAt(0);
            zDataPoints.removeAt(0);
          }
        });
        
        final reading = AccelerometerReading(
          x: x,
          y: y,
          z: z,
          timestamp: DateTime.now(),
          magnitude: mag,
        );
        
        await DatabaseHelper.instance.insertReading(reading);
        loadRecentReadings();
      }
    } catch (e) {
      // Handle parsing error
    }
  }

  @override
  void dispose() {
    characteristicSubscription?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName.isEmpty ? 'Device' : widget.device.platformName),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TremorHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              loadSettings(); // Reload settings after returning
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tremor Alert Banner
              if (currentlyInTremor)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ TREMOR DETECTED',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (lastAnalysis != null)
                              Text(
                                '${lastAnalysis!.severity} • ${lastAnalysis!.dominantFrequency.toStringAsFixed(1)} Hz • Confidence: ${(lastAnalysis!.confidence * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Today's Stats
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat(
                        'Tremors Today',
                        '$tremorCountToday',
                        Icons.event_note,
                        Colors.blue,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      _buildQuickStat(
                        'Status',
                        currentlyInTremor ? 'Active' : 'Normal',
                        currentlyInTremor ? Icons.warning : Icons.check_circle,
                        currentlyInTremor ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Current Reading
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Current Reading',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          DataColumn(label: 'X', value: xValue.toStringAsFixed(2), color: Colors.red),
                          DataColumn(label: 'Y', value: yValue.toStringAsFixed(2), color: Colors.green),
                          DataColumn(label: 'Z', value: zValue.toStringAsFixed(2), color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Magnitude: ',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              magnitude.toStringAsFixed(3),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Live Graph
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Data Stream',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: xDataPoints.isEmpty
                            ? const Center(child: Text('Waiting for data...'))
                            : LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                      ),
                                    ),
                                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: xDataPoints,
                                      isCurved: true,
                                      color: Colors.red,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                      barWidth: 2,
                                    ),
                                    LineChartBarData(
                                      spots: yDataPoints,
                                      isCurved: true,
                                      color: Colors.green,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                      barWidth: 2,
                                    ),
                                    LineChartBarData(
                                      spots: zDataPoints,
                                      isCurved: true,
                                      color: Colors.blue,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                      barWidth: 2,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('X', Colors.red),
                          const SizedBox(width: 16),
                          _buildLegendItem('Y', Colors.green),
                          const SizedBox(width: 16),
                          _buildLegendItem('Z', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Detection Info
              if (lastAnalysis != null && !currentlyInTremor)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monitoring Active',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Frequency: ${lastAnalysis!.dominantFrequency.toStringAsFixed(1)} Hz',
                                style: const TextStyle(fontSize: 12),
                              ),
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
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class DataColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const DataColumn({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AccelerometerReading> allReadings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllReadings();
  }

  void loadAllReadings() async {
    final readings = await DatabaseHelper.instance.getAllReadings();
    setState(() {
      allReadings = readings;
      isLoading = false;
    });
  }

  Future<void> exportToCSV() async {
    final readings = await DatabaseHelper.instance.getAllReadings();
    
    StringBuffer csv = StringBuffer();
    csv.writeln('timestamp,x,y,z,magnitude');
    
    for (var reading in readings) {
      csv.writeln(
        '${reading.timestamp.toIso8601String()},'
        '${reading.x},'
        '${reading.y},'
        '${reading.z},'
        '${reading.magnitude}'
      );
    }
    
    print('=== CSV DATA START ===');
    print(csv.toString());
    print('=== CSV DATA END ===');
    print('Total readings: ${readings.length}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${readings.length} readings to console')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Readings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Readings?'),
                  content: const Text(
                    'This will delete all accelerometer readings. This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await DatabaseHelper.instance.deleteAllReadings();
                loadAllReadings();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allReadings.isEmpty
              ? const Center(child: Text('No readings saved yet'))
              : ListView.builder(
                  itemCount: allReadings.length,
                  itemBuilder: (context, index) {
                    final reading = allReadings[index];
                    return ListTile(
                      title: Text(DateFormat('MMM dd, yyyy HH:mm:ss').format(reading.timestamp)),
                      subtitle: Text(
                        'X: ${reading.x.toStringAsFixed(2)}, '
                        'Y: ${reading.y.toStringAsFixed(2)}, '
                        'Z: ${reading.z.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        reading.magnitude.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'database_helper.dart';
import 'tremor_detector.dart';
import 'tremor_event.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'ml_detector.dart';

void main() {
  runApp(const TremorDetectionApp());
}

class TremorDetectionApp extends StatelessWidget {
  const TremorDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tremor Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BluetoothScanScreen(),
    );
  }
}

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  String statusMessage = 'Initializing...';
  StreamSubscription? scanSubscription;

  @override
  void initState() {
    super.initState();
    checkBluetoothAndScan();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  void checkBluetoothAndScan() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        setState(() {
          statusMessage = 'Bluetooth not available on this device';
        });
        return;
      }

      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        setState(() {
          statusMessage = 'Please turn on Bluetooth';
        });
        return;
      }

      startScan();
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
      });
    }
  }

  void startScan() async {
    try {
      setState(() {
        isScanning = true;
        scanResults = [];
        statusMessage = 'Scanning for devices...';
      });

      await scanSubscription?.cancel();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true,
      );

      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });

      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      
      setState(() {
        isScanning = false;
        if (scanResults.isEmpty) {
          statusMessage = 'No devices found';
        } else {
          statusMessage = 'Found ${scanResults.length} device(s)';
        }
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        statusMessage = 'Scan failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tremor Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isScanning ? null : startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isScanning ? Colors.blue.shade100 : Colors.grey.shade200,
            child: Row(
              children: [
                if (isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 12),
                Expanded(child: Text(statusMessage)),
              ],
            ),
          ),
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          isScanning ? 'Scanning...' : 'No devices found',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        if (!isScanning) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: startScan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Scan Again'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final result = scanResults[index];
                      final deviceName = result.device.platformName.isEmpty
                          ? 'Unknown Device'
                          : result.device.platformName;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${result.device.remoteId}\nSignal: ${result.rssi} dBm'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DataDisplayScreen(device: result.device),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DataDisplayScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DataDisplayScreen({super.key, required this.device});

  @override
  State<DataDisplayScreen> createState() => _DataDisplayScreenState();
}

class _DataDisplayScreenState extends State<DataDisplayScreen> {
  final TremorDetector tremorDetector = TremorDetector();
  bool currentlyInTremor = false;
  final MLDetector mlDetector = MLDetector();
List<double> mlWindow = [];
bool mlTremorDetected = false;
  DateTime? tremorStartTime;
  TremorAnalysis? lastAnalysis;
  

  final FlutterLocalNotificationsPlugin notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  bool isConnected = false;
  bool isConnecting = true;
  double xValue = 0;
  double yValue = 0;
  double zValue = 0;
  double magnitude = 0;
  String rawData = 'Connecting...';
  String statusMessage = 'Connecting to device...';
  BluetoothCharacteristic? targetCharacteristic;
  StreamSubscription? characteristicSubscription;
  
  List<FlSpot> xDataPoints = [];
  List<FlSpot> yDataPoints = [];
  List<FlSpot> zDataPoints = [];
  double timeCounter = 0;
  
  List<AccelerometerReading> recentReadings = [];
  final int maxDisplayPoints = 50;
@override
  void initState() {
    super.initState();
    connectToDevice();
    loadRecentReadings();
    initializeNotifications(); // Add this line
  }

  void initializeNotifications() async {
  const initializationSettingsAndroid = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await notificationsPlugin.initialize(initializationSettings);
  
  // Request permissions
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  
  print('✅ Notifications initialized and permissions requested');
  
  // ADD THIS TEST NOTIFICATION:
  await Future.delayed(Duration(seconds: 2));
  
  const testDetails = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
  
  await notificationsPlugin.show(
    999,
    'TEST',
    'If you see this, notifications work!',
    testDetails,
  );
  
  print('🧪 Test notification sent');
}
  void loadRecentReadings() async {
    final readings = await DatabaseHelper.instance.getRecentReadings(10);
    setState(() {
      recentReadings = readings;
    });
  }

  void connectToDevice() async {
    try {
      await widget.device.connect(timeout: const Duration(seconds: 10));
      
      setState(() {
        isConnected = true;
        isConnecting = false;
        statusMessage = 'Connected! Discovering services...';
      });

      List<BluetoothService> services = await widget.device.discoverServices();

      bool foundCharacteristic = false;
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.read) {
            targetCharacteristic = characteristic;
            foundCharacteristic = true;
            
            await characteristic.setNotifyValue(true);
            
            characteristicSubscription = characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                String dataString = utf8.decode(value);
                parseData(dataString);
              }
            });
            
            setState(() {
              statusMessage = 'Receiving data';
            });
            
            break;
          }
        }
        if (foundCharacteristic) break;
      }
    } catch (e) {
      setState(() {
        isConnecting = false;
        isConnected = false;
        statusMessage = 'Connection failed';
        rawData = 'Error: $e';
      });
    }
  }
   Future<void> showTremorNotification(TremorAnalysis analysis) async {
    const androidDetails = AndroidNotificationDetails(
      'tremor_channel',
      'Tremor Alerts',
      channelDescription: 'Notifications for detected tremors',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await notificationsPlugin.show(
      0,
      '⚠️ Tremor Detected',
      '${analysis.severity} tremor at ${analysis.dominantFrequency.toStringAsFixed(1)} Hz',
      notificationDetails,
    );
  }
  
void parseData(String data) async {
    try {
      List<String> values = data.trim().split(',');
      if (values.length >= 3) {
        double x = double.tryParse(values[0].trim()) ?? 0;
        double y = double.tryParse(values[1].trim()) ?? 0;
        double z = double.tryParse(values[2].trim()) ?? 0;
        
        double mag = sqrt(x * x + y * y + z * z);
        
        
        tremorDetector.addDataPoint(x, y, z);
        
       
TremorAnalysis? analysis = tremorDetector.analyzeWindow();

mlWindow.add(mag);
if (mlWindow.length > 50) {
  mlWindow.removeAt(0);
}

if (mlWindow.length >= 20) {
  bool mlPrediction = mlDetector.detectTremor(mlWindow);
  double power = mlDetector.calcPower(mlWindow);
  
  setState(() {
    mlTremorDetected = mlPrediction;
  });
  
  print('ML: ${mlPrediction ? "TREMOR" : "NORMAL"}, Power: ${power.toStringAsFixed(4)}');
}

print('Analysis: isTremor=${analysis?.isTremor}, freq=${analysis?.dominantFrequency}, power=${analysis?.power}');

if (analysis != null) {
  lastAnalysis = analysis;
          
       
         if (analysis.isTremor && !currentlyInTremor) {

  print('🔔 TREMOR STARTED - Sending notification!'); 
  currentlyInTremor = true;
  tremorStartTime = DateTime.now();
  
  
  await showTremorNotification(analysis);
  print('🔔 Notification sent!'); 
} else if (!analysis.isTremor && currentlyInTremor) {
          
            currentlyInTremor = false;
            
            if (tremorStartTime != null) {
              double duration = DateTime.now().difference(tremorStartTime!).inSeconds.toDouble();
              
      
              final event = TremorEvent(
                timestamp: tremorStartTime!,
                magnitude: lastAnalysis!.power,
                duration: duration,
                severity: lastAnalysis!.severity,
              );
              
              await DatabaseHelper.instance.insertTremorEvent(event);
            }
            
            tremorStartTime = null;
          }
        }
       
        
        setState(() {
          xValue = x;
          yValue = y;
          zValue = z;
          magnitude = mag;
          rawData = data.trim();
          
          timeCounter += 0.1;
          xDataPoints.add(FlSpot(timeCounter, x));
          yDataPoints.add(FlSpot(timeCounter, y));
          zDataPoints.add(FlSpot(timeCounter, z));
          
          if (xDataPoints.length > maxDisplayPoints) {
            xDataPoints.removeAt(0);
            yDataPoints.removeAt(0);
            zDataPoints.removeAt(0);
          }
        });
        
       
        final reading = AccelerometerReading(
          x: x,
          y: y,
          z: z,
          timestamp: DateTime.now(),
          magnitude: mag,
        );
        
        await DatabaseHelper.instance.insertReading(reading);
        loadRecentReadings();
      }
    } catch (e) {
     
    }
  }

  @override
  void dispose() {
    characteristicSubscription?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName.isEmpty ? 'Device' : widget.device.platformName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               if (currentlyInTremor)
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              border: Border.all(color: Colors.red, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ TREMOR DETECTED',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      if (lastAnalysis != null)
                        Text(
                          '${lastAnalysis!.severity} tremor at ${lastAnalysis!.dominantFrequency.toStringAsFixed(1)} Hz',
                          style: TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
Container(
  padding: EdgeInsets.all(8),
  margin: EdgeInsets.only(bottom: 8),
  decoration: BoxDecoration(
    color: mlTremorDetected ? Colors.orange.shade100 : Colors.green.shade100,
    border: Border.all(
      color: mlTremorDetected ? Colors.orange : Colors.green,
      width: 2,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(
        mlTremorDetected ? Icons.warning_amber : Icons.check_circle,
        color: mlTremorDetected ? Colors.orange : Colors.green,
      ),
      SizedBox(width: 8),
      Text(
        'ML Model: ${mlTremorDetected ? "Tremor Detected" : "Normal"}',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  ),
),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Current Reading', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          DataColumn(label: 'X', value: xValue.toStringAsFixed(2), color: Colors.red),
                          DataColumn(label: 'Y', value: yValue.toStringAsFixed(2), color: Colors.green),
                          DataColumn(label: 'Z', value: zValue.toStringAsFixed(2), color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Magnitude: ${magnitude.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Live Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: xDataPoints.isEmpty
                            ? const Center(child: Text('Waiting for data...'))
                            : LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: xDataPoints,
                                      isCurved: true,
                                      color: Colors.red,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                    LineChartBarData(
                                      spots: yDataPoints,
                                      isCurved: true,
                                      color: Colors.green,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                    LineChartBarData(
                                      spots: zDataPoints,
                                      isCurved: true,
                                      color: Colors.blue,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('X', Colors.red),
                          const SizedBox(width: 16),
                          _buildLegendItem('Y', Colors.green),
                          const SizedBox(width: 16),
                          _buildLegendItem('Z', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Readings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...recentReadings.take(5).map((reading) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${DateFormat('HH:mm:ss').format(reading.timestamp)}: '
                          'X:${reading.x.toStringAsFixed(1)} Y:${reading.y.toStringAsFixed(1)} Z:${reading.z.toStringAsFixed(1)} '
                          'Mag:${reading.magnitude.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class DataColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const DataColumn({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AccelerometerReading> allReadings = [];
  bool isLoading = true;
  

  @override
  void initState() {
    super.initState();
    loadAllReadings();
  }

  void loadAllReadings() async {
    final readings = await DatabaseHelper.instance.getAllReadings();
    setState(() {
      allReadings = readings;
      isLoading = false;
    });
  }
  Future<void> exportToCSV() async {
    final readings = await DatabaseHelper.instance.getAllReadings();
    
    // Create CSV content
    StringBuffer csv = StringBuffer();
    csv.writeln('timestamp,x,y,z,magnitude');
    
    for (var reading in readings) {
      csv.writeln(
        '${reading.timestamp.toIso8601String()},'
        '${reading.x},'
        '${reading.y},'
        '${reading.z},'
        '${reading.magnitude}'
      );
    }
    
    // Print to console
    print('=== CSV DATA START ===');
    print(csv.toString());
    print('=== CSV DATA END ===');
    print('Total readings: ${readings.length}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${readings.length} readings to console')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        actions: [
          IconButton(                        // ← NEW - Add this
    icon: const Icon(Icons.download),
    onPressed: exportToCSV, 
  ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text('This will delete all saved readings. This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await DatabaseHelper.instance.deleteAllReadings();
                loadAllReadings();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allReadings.isEmpty
              ? const Center(child: Text('No readings saved yet'))
              : ListView.builder(
                  itemCount: allReadings.length,
                  itemBuilder: (context, index) {
                    final reading = allReadings[index];
                    return ListTile(
                      title: Text(DateFormat('MMM dd, yyyy HH:mm:ss').format(reading.timestamp)),
                      subtitle: Text(
                        'X: ${reading.x.toStringAsFixed(2)}, '
                        'Y: ${reading.y.toStringAsFixed(2)}, '
                        'Z: ${reading.z.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        'Mag: ${reading.magnitude.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
    );
  }
}*/