import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tremor_detector.dart';
import 'database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double tremorThreshold = 0.15;
  double minFrequency = 4.0;
  double maxFrequency = 12.0;
  bool alertsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    loadSettings();
  }
  
  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tremorThreshold = prefs.getDouble('tremor_threshold') ?? 0.15;
      minFrequency = prefs.getDouble('min_frequency') ?? 4.0;
      maxFrequency = prefs.getDouble('max_frequency') ?? 12.0;
      alertsEnabled = prefs.getBool('alerts_enabled') ?? true;
      soundEnabled = prefs.getBool('sound_enabled') ?? true;
      vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
    
    // Apply to detector
    TremorDetector.updateSettings(
      newThreshold: tremorThreshold,
      newMinFreq: minFrequency,
      newMaxFreq: maxFrequency,
    );
  }
  
  void saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tremor_threshold', tremorThreshold);
    await prefs.setDouble('min_frequency', minFrequency);
    await prefs.setDouble('max_frequency', maxFrequency);
    await prefs.setBool('alerts_enabled', alertsEnabled);
    await prefs.setBool('sound_enabled', soundEnabled);
    await prefs.setBool('vibration_enabled', vibrationEnabled);
    
    TremorDetector.updateSettings(
      newThreshold: tremorThreshold,
      newMinFreq: minFrequency,
      newMaxFreq: maxFrequency,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Detection Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detection Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Tremor Sensitivity'),
                  const Text(
                    'Lower = more sensitive (detects smaller tremors)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: tremorThreshold,
                    min: 0.05,
                    max: 0.5,
                    divisions: 18,
                    label: tremorThreshold.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        tremorThreshold = value;
                      });
                    },
                  ),
                  Text(
                    'Current: ${tremorThreshold.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text('Frequency Range'),
                  const Text(
                    'Parkinsonian tremors: 4-12 Hz (recommended)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Min Frequency', style: TextStyle(fontSize: 12)),
                            Slider(
                              value: minFrequency,
                              min: 2.0,
                              max: 8.0,
                              divisions: 12,
                              label: '${minFrequency.toStringAsFixed(1)} Hz',
                              onChanged: (value) {
                                setState(() {
                                  minFrequency = value;
                                  if (minFrequency >= maxFrequency) {
                                    maxFrequency = minFrequency + 1;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Max Frequency', style: TextStyle(fontSize: 12)),
                            Slider(
                              value: maxFrequency,
                              min: 6.0,
                              max: 20.0,
                              divisions: 14,
                              label: '${maxFrequency.toStringAsFixed(1)} Hz',
                              onChanged: (value) {
                                setState(() {
                                  maxFrequency = value;
                                  if (maxFrequency <= minFrequency) {
                                    minFrequency = maxFrequency - 1;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Range: ${minFrequency.toStringAsFixed(1)} - ${maxFrequency.toStringAsFixed(1)} Hz',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        tremorThreshold = 0.15;
                        minFrequency = 4.0;
                        maxFrequency = 12.0;
                      });
                      saveSettings();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset to Default'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notification Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Enable Alerts'),
                    subtitle: const Text('Notify when tremor detected'),
                    value: alertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        alertsEnabled = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Sound'),
                    subtitle: const Text('Play notification sound'),
                    value: soundEnabled,
                    onChanged: alertsEnabled ? (value) {
                      setState(() {
                        soundEnabled = value;
                      });
                    } : null,
                  ),
                  
                  SwitchListTile(
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate on tremor detection'),
                    value: vibrationEnabled,
                    onChanged: alertsEnabled ? (value) {
                      setState(() {
                        vibrationEnabled = value;
                      });
                    } : null,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Data Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Data?'),
                          content: const Text(
                            'This will delete all tremor events and readings. '
                            'This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete All'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        await DatabaseHelper.instance.deleteAllReadings();
                        await DatabaseHelper.instance.deleteAllTremorEvents();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All data cleared')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // App Info
          const Center(
            child: Column(
              children: [
                Text('Tremor Detection App', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Version 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


