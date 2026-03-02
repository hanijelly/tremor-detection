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
        
        // Add to tremor detector
        tremorDetector.addDataPoint(x, y, z);
        
        // Analyze for tremor
       // Analyze for tremor
TremorAnalysis? analysis = tremorDetector.analyzeWindow();

// ADD THESE DEBUG LINES:
print('Analysis: isTremor=${analysis?.isTremor}, freq=${analysis?.dominantFrequency}, power=${analysis?.power}');

if (analysis != null) {
  lastAnalysis = analysis;
          
          // Check if tremor detected
         if (analysis.isTremor && !currentlyInTremor) {
  // Tremor just started
  print('🔔 TREMOR STARTED - Sending notification!'); // ADD THIS
  currentlyInTremor = true;
  tremorStartTime = DateTime.now();
  
  // Send notification
  await showTremorNotification(analysis);
  print('🔔 Notification sent!'); // ADD THIS
} else if (!analysis.isTremor && currentlyInTremor) {
            // Tremor ended
            currentlyInTremor = false;
            
            if (tremorStartTime != null) {
              double duration = DateTime.now().difference(tremorStartTime!).inSeconds.toDouble();
              
              // Save tremor event
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        actions: [
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
}