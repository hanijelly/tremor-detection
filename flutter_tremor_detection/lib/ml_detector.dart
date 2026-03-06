import 'dart:math';

class MLDetector {

  static const double powerThreshold = 0.05;
  static const double varianceThreshold = 0.001;
  
  bool detectTremor(List<double> magnitudeWindow) {
    if (magnitudeWindow.length < 20) return false;
    
 
    double mean = calcMean(magnitudeWindow);
    List<double> acSignal = magnitudeWindow.map((v) => v - mean).toList();
    

    double power = calcPower(acSignal);
    double variance = calculateVariance(acSignal);
    
    
    if (power > powerThreshold) {
      return true;
    }

    if (variance > 0.005) {
      return true;
    }
    
    return false;
  }
  
  double calcPower(List<double> data) {
    double sumSquares = 0;
    for (var val in data) {
      sumSquares += val * val;
    }
    return sqrt(sumSquares / data.length);
  }
  
  double calculateVariance(List<double> data) {
    double mean = calcMean(data);
    double sumSquaredDiff = 0;
    for (var val in data) {
      sumSquaredDiff += (val - mean) * (val - mean);
    }
    return sumSquaredDiff / data.length;
  }
  
  double calcMean(List<double> data) {
    return data.reduce((a, b) => a + b) / data.length;
  }
}