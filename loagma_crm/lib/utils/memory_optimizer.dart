import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';

class MemoryOptimizer {
  static const MethodChannel _channel = MethodChannel('memory_optimizer');

  /// Optimize memory usage for Android devices
  static Future<void> optimizeMemory() async {
    if (Platform.isAndroid) {
      try {
        // Force garbage collection
        await _channel.invokeMethod('forceGC');

        // Clear image cache
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        // Limit image cache size
        PaintingBinding.instance.imageCache.maximumSize = 50;
        PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB

        print('✅ Memory optimization completed');
      } catch (e) {
        print('⚠️ Memory optimization failed: $e');
      }
    }
  }

  /// Clear image caches specifically
  static void clearImageCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Set conservative image cache limits
  static void setConservativeImageLimits() {
    PaintingBinding.instance.imageCache.maximumSize = 30;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 30 << 20; // 30MB
  }
}
