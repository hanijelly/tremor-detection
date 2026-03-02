import 'dart:math';

class TremorDetector {

static const int windowSize = 20;         
static const double samplingRate = 10.0;  
static const double minTremorFreq = 2.0;  
static const double maxTremorFreq = 15.0; 
static const double magnitudeThreshold = 0.05;
  
  
  List<double> xBuffer = [];
  List<double> yBuffer = [];
  List<double> zBuffer = [];
  
  
  void addDataPoint(double x, double y, double z) {
    xBuffer.add(x);
    yBuffer.add(y);
    zBuffer.add(z);
    
 
    if (xBuffer.length > windowSize) {
      xBuffer.removeAt(0);
      yBuffer.removeAt(0);
      zBuffer.removeAt(0);
    }
  }
  
  

  TremorAnalysis? analyzeWindow() {

    if (xBuffer.length < windowSize) {
      return null;
    }

    List<double> magnitudeBuffer = [];
    for (int i = 0; i < windowSize; i++) {
      double mag = sqrt(xBuffer[i] * xBuffer[i] + 
                       yBuffer[i] * yBuffer[i] + 
                       zBuffer[i] * zBuffer[i]);
      magnitudeBuffer.add(mag);
    }
    

    double average = magnitudeBuffer.reduce((a, b) => a + b) / magnitudeBuffer.length;
    List<double> acData = magnitudeBuffer.map((v) => v - average).toList();
    

    int zeroCrossings = 0;
    for (int i = 1; i < acData.length; i++) {
      if ((acData[i-1] >= 0 && acData[i] < 0) || (acData[i-1] < 0 && acData[i] >= 0)) {
        zeroCrossings++;
      }
    }
    
   
    double timeWindow = windowSize / samplingRate;
    double dominantFrequency = (zeroCrossings / 2) / timeWindow;
    

    double sumSquares = 0;
    for (var val in acData) {
      sumSquares += val * val;
    }
    double power = sqrt(sumSquares / acData.length);
    
    // Determine if tremor detected
    bool isTremor = false;
    String severity = 'None';
    
    if (dominantFrequency >= minTremorFreq && 
        dominantFrequency <= maxTremorFreq && 
        power > magnitudeThreshold) {
      isTremor = true;
      
      if (power < 1.0) {
        severity = 'Mild';
      } else if (power < 2.0) {
        severity = 'Moderate';
      } else {
        severity = 'Severe';
      }
    }
    
    return TremorAnalysis(
      isTremor: isTremor,
      dominantFrequency: dominantFrequency,
      power: power,
      severity: severity,
      timestamp: DateTime.now(),
    );
  }
  
  void reset() {
    xBuffer.clear();
    yBuffer.clear();
    zBuffer.clear();
  }
}

class TremorAnalysis {
  final bool isTremor;
  final double dominantFrequency; // Hz
  final double power; // Strength of oscillation
  final String severity; // Mild, Moderate, Severe
  final DateTime timestamp;
  
  TremorAnalysis({
    required this.isTremor,
    required this.dominantFrequency,
    required this.power,
    required this.severity,
    required this.timestamp,
  });
}