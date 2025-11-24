// lib/worker.dart
import 'dart:typed_data';

/// Generates two raw RGBA images:
/// 1. 'dimming': Dims background pixels, leaves selected pixels TRANSPARENT.
/// 2. 'edges': White pixels for edges, everything else TRANSPARENT.
Map<String, Uint8List> generateLayers(Map<String, dynamic> request) {
  final int width = request['width'];
  final int height = request['height'];
  final Uint8List map = request['map'];
  final int target = request['target'];
  final int thickness = request['thickness'];
  final int dimAlpha = request['dimAlpha'];

  final int length = width * height * 4;
  final Uint8List edgeBytes = Uint8List(length);
  final Uint8List dimmingBytes = Uint8List(length);

  bool isTarget(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return map[y * width + x] == target;
  }

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int i = y * width + x;
      final int offset = i * 4;

      if (map[i] == target) {
        // --- SELECTED AREA ---
        dimmingBytes[offset + 3] = 0; 

        // Edge Detection
        bool isEdge = false;
        outerLoop:
        for (int dy = -thickness; dy <= thickness; dy++) {
          for (int dx = -thickness; dx <= thickness; dx++) {
            if (!isTarget(x + dx, y + dy)) {
              isEdge = true;
              break outerLoop;
            }
          }
        }

        if (isEdge) {
          edgeBytes[offset] = 255; edgeBytes[offset+1] = 255; edgeBytes[offset+2] = 255;
          edgeBytes[offset + 3] = 255; 
        }
      } else {
        // --- BACKGROUND AREA ---
        dimmingBytes[offset] = 0; dimmingBytes[offset+1] = 0; dimmingBytes[offset+2] = 0;
        dimmingBytes[offset + 3] = dimAlpha; 
        
        edgeBytes[offset + 3] = 0; 
      }
    }
  }

  return {'edges': edgeBytes, 'dimming': dimmingBytes};
}