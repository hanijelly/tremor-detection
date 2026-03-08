import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'tremor_event.dart';

class TremorHistoryScreen extends StatefulWidget {
  const TremorHistoryScreen({super.key});

  @override
  State<TremorHistoryScreen> createState() => _TremorHistoryScreenState();
}

class _TremorHistoryScreenState extends State<TremorHistoryScreen> {
  List<TremorEvent> allEvents = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    loadTremorEvents();
  }
  
  void loadTremorEvents() async {
    final events = await DatabaseHelper.instance.getAllTremorEvents();
    setState(() {
      allEvents = events;
      isLoading = false;
    });
  }
  
  // Group events by date
  Map<DateTime, List<TremorEvent>> groupEventsByDate() {
    Map<DateTime, List<TremorEvent>> grouped = {};
    
    for (var event in allEvents) {
      DateTime date = DateTime(
        event.timestamp.year,
        event.timestamp.month,
        event.timestamp.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(event);
    }
    
    return grouped;
  }
  
  // Get tremors per day for last 30 days
  List<FlSpot> getTremorsPerDayData() {
    Map<DateTime, List<TremorEvent>> grouped = groupEventsByDate();
    List<FlSpot> spots = [];
    
    DateTime now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      DateTime date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      int count = grouped[date]?.length ?? 0;
      spots.add(FlSpot(29 - i.toDouble(), count.toDouble()));
    }
    
    return spots;
  }
  
  // Calculate statistics
  Map<String, dynamic> calculateStatistics() {
    if (allEvents.isEmpty) {
      return {
        'total': 0,
        'today': 0,
        'thisWeek': 0,
        'avgPerDay': 0.0,
        'mildCount': 0,
        'moderateCount': 0,
        'severeCount': 0,
      };
    }
    
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime weekAgo = today.subtract(const Duration(days: 7));
    
    int todayCount = 0;
    int weekCount = 0;
    int mildCount = 0;
    int moderateCount = 0;
    int severeCount = 0;
    
    for (var event in allEvents) {
      DateTime eventDate = DateTime(
        event.timestamp.year,
        event.timestamp.month,
        event.timestamp.day,
      );
      
      if (eventDate.isAtSameMomentAs(today)) {
        todayCount++;
      }
      
      if (eventDate.isAfter(weekAgo) || eventDate.isAtSameMomentAs(weekAgo)) {
        weekCount++;
      }
      
      switch (event.severity) {
        case 'Mild':
          mildCount++;
          break;
        case 'Moderate':
          moderateCount++;
          break;
        case 'Severe':
          severeCount++;
          break;
      }
    }
    
    // Calculate days with data
    Map<DateTime, List<TremorEvent>> grouped = groupEventsByDate();
    int daysWithData = grouped.keys.length;
    double avgPerDay = daysWithData > 0 ? allEvents.length / daysWithData : 0;
    
    return {
      'total': allEvents.length,
      'today': todayCount,
      'thisWeek': weekCount,
      'avgPerDay': avgPerDay,
      'mildCount': mildCount,
      'moderateCount': moderateCount,
      'severeCount': severeCount,
    };
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tremor History')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final stats = calculateStatistics();
    final tremorsPerDay = getTremorsPerDayData();
    final groupedEvents = groupEventsByDate();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tremor History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Tremor Tracking'),
                  content: const Text(
                    'This screen shows your tremor history over time. '
                    'The graph displays tremors per day for the last 30 days. '
                    'Green dots = mild tremors, orange = moderate, red = severe.\n\n'
                    'Track trends to understand your condition better.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: allEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tremor events recorded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to your device to start tracking',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Tremors',
                        '${stats['total']}',
                        Icons.analytics,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Today',
                        '${stats['today']}',
                        Icons.today,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'This Week',
                        '${stats['thisWeek']}',
                        Icons.calendar_week,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Avg/Day',
                        stats['avgPerDay'].toStringAsFixed(1),
                        Icons.trending_up,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Severity Breakdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Severity Breakdown',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSeverityIndicator(
                              'Mild',
                              stats['mildCount'],
                              Colors.green,
                            ),
                            _buildSeverityIndicator(
                              'Moderate',
                              stats['moderateCount'],
                              Colors.orange,
                            ),
                            _buildSeverityIndicator(
                              'Severe',
                              stats['severeCount'],
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Tremors per Day Graph
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tremors per Day (Last 30 Days)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 5,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 5 == 0) {
                                        return Text(
                                          '${(30 - value.toInt())}d',
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: tremorsPerDay,
                                  isCurved: true,
                                  color: Colors.blue,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blue.withOpacity(0.3),
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
                
                const SizedBox(height: 24),
                
                // Disease Progression Insight
                if (allEvents.length >= 7)
                  Card(
                    color: _getProgressionColor(stats),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getProgressionIcon(stats),
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Trend Analysis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getProgressionMessage(stats),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Event List by Date
                const Text(
                  'Recent Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                ...groupedEvents.entries.take(7).map((entry) {
                  DateTime date = entry.key;
                  List<TremorEvent> events = entry.value;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${events.length} tremor(s)'),
                      children: events.map((event) {
                        return ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getSeverityColor(event.severity),
                            ),
                          ),
                          title: Text(DateFormat('HH:mm:ss').format(event.timestamp)),
                          subtitle: Text(
                            '${event.severity} • Duration: ${event.duration.toStringAsFixed(1)}s',
                          ),
                          trailing: Text(
                            '${event.magnitude.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSeverityIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Mild':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'Severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Color _getProgressionColor(Map<String, dynamic> stats) {
    double avgPerDay = stats['avgPerDay'];
    if (avgPerDay < 2) return Colors.green;
    if (avgPerDay < 5) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getProgressionIcon(Map<String, dynamic> stats) {
    double avgPerDay = stats['avgPerDay'];
    if (avgPerDay < 2) return Icons.trending_down;
    if (avgPerDay < 5) return Icons.trending_flat;
    return Icons.trending_up;
  }
  
  String _getProgressionMessage(Map<String, dynamic> stats) {
    double avgPerDay = stats['avgPerDay'];
    
    if (avgPerDay < 2) {
      return 'Your tremors are well-controlled. Average ${avgPerDay.toStringAsFixed(1)} per day. Keep up your current treatment!';
    } else if (avgPerDay < 5) {
      return 'Moderate tremor activity detected. Average ${avgPerDay.toStringAsFixed(1)} per day. Consider discussing with your doctor.';
    } else {
      return 'Elevated tremor frequency detected. Average ${avgPerDay.toStringAsFixed(1)} per day. Please consult with your healthcare provider.';
    }
  }
}


