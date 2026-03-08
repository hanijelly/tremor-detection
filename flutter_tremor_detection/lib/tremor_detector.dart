import 'dart:math';

class TremorDetector {
  // Configurable parameters (can be adjusted from settings)
  static int windowSize = 50;  // Increased for better frequency resolution
  static double samplingRate = 10.0;
  static double minTremorFreq = 4.0;  // Parkinsonian tremor range
  static double maxTremorFreq = 12.0;
  static double magnitudeThreshold = 0.15;  // Increased to reduce false positives
  static double largeMotionThreshold = 2.5;  // Ignore large voluntary movements
  
  List<double> xBuffer = [];
  List<double> yBuffer = [];
  List<double> zBuffer = [];
  List<double> magnitudeBuffer = [];
  
  // Tracking state
  int consecutiveTremorFrames = 0;
  static const int minConsecutiveFrames = 5;  // Must detect tremor for 5 frames (0.5s)
  
  void addDataPoint(double x, double y, double z) {
    xBuffer.add(x);
    yBuffer.add(y);
    zBuffer.add(z);
    
    double mag = sqrt(x * x + y * y + z * z);
    magnitudeBuffer.add(mag);
    
    if (xBuffer.length > windowSize) {
      xBuffer.removeAt(0);
      yBuffer.removeAt(0);
      zBuffer.removeAt(0);
      magnitudeBuffer.removeAt(0);
    }
  }
  
  TremorAnalysis? analyzeWindow() {
    if (xBuffer.length < windowSize) {
      return null;
    }
    
    // Check for large voluntary movements first
    double maxMag = magnitudeBuffer.reduce(max);
    double minMag = magnitudeBuffer.reduce(min);
    double range = maxMag - minMag;
    
    if (range > largeMotionThreshold) {
      // This is a large movement, not a tremor
      consecutiveTremorFrames = 0;
      return TremorAnalysis(
        isTremor: false,
        dominantFrequency: 0,
        power: 0,
        severity: 'None',
        timestamp: DateTime.now(),
        confidence: 0,
      );
    }
    
    // Remove DC component (average)
    double average = magnitudeBuffer.reduce((a, b) => a + b) / magnitudeBuffer.length;
    List<double> acData = magnitudeBuffer.map((v) => v - average).toList();
    
    // Count zero crossings for frequency detection
    int zeroCrossings = 0;
    for (int i = 1; i < acData.length; i++) {
      if ((acData[i-1] >= 0 && acData[i] < 0) || (acData[i-1] < 0 && acData[i] >= 0)) {
        zeroCrossings++;
      }
    }
    
    double timeWindow = windowSize / samplingRate;
    double dominantFrequency = (zeroCrossings / 2) / timeWindow;
    
    // Calculate power (RMS of AC component)
    double sumSquares = 0;
    for (var val in acData) {
      sumSquares += val * val;
    }
    double power = sqrt(sumSquares / acData.length);
    
    // Calculate variance for rhythm detection
    double mean = acData.reduce((a, b) => a + b) / acData.length;
    double variance = 0;
    for (var val in acData) {
      variance += (val - mean) * (val - mean);
    }
    variance /= acData.length;
    
    // Detect tremor with multiple criteria
    bool meetsFrequencyRange = dominantFrequency >= minTremorFreq && 
                                dominantFrequency <= maxTremorFreq;
    bool meetsPowerThreshold = power > magnitudeThreshold;
    bool hasRhythmicPattern = variance > 0.001;  // Tremors are rhythmic
    
    bool currentFrameIsTremor = meetsFrequencyRange && meetsPowerThreshold && hasRhythmicPattern;
    
    // Require consecutive frames to confirm tremor (reduce noise)
    if (currentFrameIsTremor) {
      consecutiveTremorFrames++;
    } else {
      consecutiveTremorFrames = 0;
    }
    
    bool isTremor = consecutiveTremorFrames >= minConsecutiveFrames;
    
    // Calculate confidence
    double confidence = 0;
    if (isTremor) {
      confidence = min(1.0, (power / magnitudeThreshold) * 0.5 + 
                            (variance / 0.01) * 0.3 + 
                            0.2);
    }
    
    // Determine severity
    String severity = 'None';
    if (isTremor) {
      if (power < 0.3) {
        severity = 'Mild';
      } else if (power < 0.6) {
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
      confidence: confidence,
    );
  }
  
  void reset() {
    xBuffer.clear();
    yBuffer.clear();
    zBuffer.clear();
    magnitudeBuffer.clear();
    consecutiveTremorFrames = 0;
  }
  
  // Update settings
  static void updateSettings({
    int? newWindowSize,
    double? newMinFreq,
    double? newMaxFreq,
    double? newThreshold,
  }) {
    if (newWindowSize != null) windowSize = newWindowSize;
    if (newMinFreq != null) minTremorFreq = newMinFreq;
    if (newMaxFreq != null) maxTremorFreq = newMaxFreq;
    if (newThreshold != null) magnitudeThreshold = newThreshold;
  }
}

class TremorAnalysis {
  final bool isTremor;
  final double dominantFrequency;
  final double power;
  final String severity;
  final DateTime timestamp;
  final double confidence;  // 0-1, how confident we are
  
  TremorAnalysis({
    required this.isTremor,
    required this.dominantFrequency,
    required this.power,
    required this.severity,
    required this.timestamp,
    required this.confidence,
  });
}

/*import 'dart:math';

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
*/