import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'dart:math' as math;

class Impeller3DWidget extends StatefulWidget {
  const Impeller3DWidget({super.key});

  @override
  State<Impeller3DWidget> createState() => _Impeller3DWidgetState();
}

class _Impeller3DWidgetState extends State<Impeller3DWidget> {
  double _cameraRotationX =
      0.3; // Start with a slight tilt to show the cube better
  double _cameraRotationY = 0.5; // Start with a slight angle
  double _cameraDistance = 500.0; // Start zoomed out to see full cube
  double _baseScale = 1.0; // Track base scale for proper zoom handling
  Offset? _previousFocalPoint;

  void _onScaleStart(ScaleStartDetails details) {
    _previousFocalPoint = details.focalPoint;
    _baseScale = 1.0; // Initialize base scale to 1.0
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle scaling (camera distance) - use scale relative to the initial scale
      if (details.pointerCount > 1) {
        // Only zoom when using multiple fingers (pinch gesture)
        final scaleChange = details.scale / _baseScale;
        if (scaleChange != 1.0) {
          final newDistance = _cameraDistance / scaleChange;
          _cameraDistance = newDistance.clamp(100.0, 10000.0);
          _baseScale = details.scale;
        }
      } else if (details.pointerCount == 1 && _previousFocalPoint != null) {
        // Handle camera rotation - only when we have a single pointer
        final delta = details.focalPoint - _previousFocalPoint!;
        _cameraRotationY += delta.dx * 0.01; // Orbit horizontally
        _cameraRotationX += delta.dy * 0.01; // Orbit vertically
      }
      _previousFocalPoint = details.focalPoint;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _baseScale = 1.0; // Reset base scale for next gesture
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: CustomPaint(
          painter: CubePainter(
            cameraRotationX: _cameraRotationX,
            cameraRotationY: _cameraRotationY,
            cameraDistance: _cameraDistance,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class CubePainter extends CustomPainter {
  final double cameraRotationX;
  final double cameraRotationY;
  final double cameraDistance;

  CubePainter({
    required this.cameraRotationX,
    required this.cameraRotationY,
    required this.cameraDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final cubeSize = 100.0;

    // Define cube vertices in 3D space (cube stays at origin)
    final vertices = [
      vm.Vector3(-1, -1, -1), // 0: bottom-back-left
      vm.Vector3(1, -1, -1), // 1: bottom-back-right
      vm.Vector3(1, 1, -1), // 2: top-back-right
      vm.Vector3(-1, 1, -1), // 3: top-back-left
      vm.Vector3(-1, -1, 1), // 4: bottom-front-left
      vm.Vector3(1, -1, 1), // 5: bottom-front-right
      vm.Vector3(1, 1, 1), // 6: top-front-right
      vm.Vector3(-1, 1, 1), // 7: top-front-left
    ];

    // Calculate camera position in spherical coordinates
    final cameraX =
        cameraDistance * math.cos(cameraRotationX) * math.cos(cameraRotationY);
    final cameraY = cameraDistance * math.sin(cameraRotationX);
    final cameraZ =
        cameraDistance * math.cos(cameraRotationX) * math.sin(cameraRotationY);
    final cameraPosition = vm.Vector3(cameraX, cameraY, cameraZ);

    // Create view matrix (camera looking at origin)
    final target = vm.Vector3.zero();
    final up = vm.Vector3(0, 1, 0);
    final viewMatrix = vm.makeViewMatrix(cameraPosition, target, up);

    // Transform vertices with view matrix and keep 3D coordinates for depth sorting
    final transformed3DVertices = vertices.map((vertex) {
      final scaledVertex = vertex * cubeSize;
      return viewMatrix.transform3(scaledVertex);
    }).toList();

    // Project to 2D screen coordinates with orthographic projection
    final scale =
        200.0 / cameraDistance; // Increased base scale for better visibility
    final transformedVertices = transformed3DVertices.map((vertex) {
      return Offset(centerX + vertex.x * scale, centerY - vertex.y * scale);
    }).toList();

    // Define cube faces with their normals
    final faces = [
      {
        'indices': [0, 1, 2, 3],
        'normal': vm.Vector3(0, 0, -1),
        'color': Colors.red,
      }, // back face
      {
        'indices': [4, 5, 6, 7],
        'normal': vm.Vector3(0, 0, 1),
        'color': Colors.green,
      }, // front face
      {
        'indices': [0, 1, 5, 4],
        'normal': vm.Vector3(0, -1, 0),
        'color': Colors.blue,
      }, // bottom face
      {
        'indices': [2, 3, 7, 6],
        'normal': vm.Vector3(0, 1, 0),
        'color': Colors.yellow,
      }, // top face
      {
        'indices': [0, 3, 7, 4],
        'normal': vm.Vector3(-1, 0, 0),
        'color': Colors.orange,
      }, // left face
      {
        'indices': [1, 2, 6, 5],
        'normal': vm.Vector3(1, 0, 0),
        'color': Colors.purple,
      }, // right face
    ];

    // Light direction (from top-front-right)
    final lightDirection = vm.Vector3(0.5, 0.7, 0.5)..normalize();

    // Calculate face data with depth and lighting
    final faceData = <Map<String, dynamic>>[];
    for (final face in faces) {
      final indices = face['indices'] as List<int>;
      final normal =
          face['normal']
              as vm.Vector3; // Cube stays static, normals don't change
      final baseColor = face['color'] as Color;

      // Calculate average Z-depth for sorting
      final avgZ =
          indices
              .map((i) => transformed3DVertices[i].z)
              .reduce((a, b) => a + b) /
          indices.length;

      // Calculate lighting intensity (dot product of normal and light direction)
      final lightIntensity = math.max(0.0, normal.dot(lightDirection));

      // Apply lighting to color (ambient + diffuse lighting)
      final ambientStrength = 0.3;
      final diffuseStrength = 0.7;
      final finalIntensity =
          ambientStrength + (diffuseStrength * lightIntensity);

      final shadedColor = Color.lerp(
        Colors.black,
        baseColor,
        finalIntensity.clamp(0.0, 1.0),
      )!;

      faceData.add({
        'indices': indices,
        'color': shadedColor,
        'depth': avgZ,
        'lightIntensity': finalIntensity,
      });
    }

    // Sort faces by depth (painter's algorithm - draw back to front)
    faceData.sort(
      (a, b) => (a['depth'] as double).compareTo(b['depth'] as double),
    );

    // Paint faces with shading
    for (final face in faceData) {
      final indices = face['indices'] as List<int>;
      final color = face['color'] as Color;
      final lightIntensity = face['lightIntensity'] as double;

      final path = Path();
      path.moveTo(
        transformedVertices[indices[0]].dx,
        transformedVertices[indices[0]].dy,
      );
      for (int j = 1; j < indices.length; j++) {
        path.lineTo(
          transformedVertices[indices[j]].dx,
          transformedVertices[indices[j]].dy,
        );
      }
      path.close();

      // Create gradient for more realistic shading
      final rect = path.getBounds();
      final gradient = RadialGradient(
        center: const Alignment(-0.3, -0.3), // Light source position
        radius: 1.0,
        colors: [
          Color.lerp(color, Colors.white, lightIntensity * 0.3)!,
          color,
          Color.lerp(color, Colors.black, 0.2)!,
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // Draw edges with varying intensity based on lighting
      final edgeOpacity = (0.5 + lightIntensity * 0.5).clamp(0.3, 1.0);
      final edgePaint = Paint()
        ..color = Colors.white.withValues(alpha: edgeOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawPath(path, edgePaint);
    }

    // Draw instructions
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Drag to rotate • Pinch to zoom',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(20, size.height - 40));
  }

  @override
  bool shouldRepaint(CubePainter oldDelegate) {
    return oldDelegate.cameraRotationX != cameraRotationX ||
        oldDelegate.cameraRotationY != cameraRotationY ||
        oldDelegate.cameraDistance != cameraDistance;
  }
}
