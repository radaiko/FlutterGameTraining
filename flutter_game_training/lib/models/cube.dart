import 'package:vector_math/vector_math_64.dart';

enum SlideDirection { up, down, left, right, forward, backward }

class GameCube {
  Vector3 position;
  SlideDirection slideDirection;
  bool isSelected;
  int id;

  static final double _sideLength = 2.0;
  static final int _edgeSubdivisions =
      4; // Number of segments per edge for rounding
  final List<List<double>> _vertices = [];
  final List<List<int>> _faces = [];

  static int get cubeSize => _sideLength.toInt();
  List<List<double>> get vertices => _vertices;
  List<List<int>> get faces => _faces;

  static int _nextId = 0;

  GameCube({required this.position, this.isSelected = false})
    : slideDirection =
          SlideDirection.values[(SlideDirection.values.length *
                  (DateTime.now().millisecondsSinceEpoch % 1000) /
                  1000)
              .floor()],
      id = _nextId++ {
    _generateVertices();
    _generateFaces();
  }

  Vector3 getSlideVector() {
    switch (slideDirection) {
      case SlideDirection.up:
        return Vector3(0, 1, 0);
      case SlideDirection.down:
        return Vector3(0, -1, 0);
      case SlideDirection.left:
        return Vector3(-1, 0, 0);
      case SlideDirection.right:
        return Vector3(1, 0, 0);
      case SlideDirection.forward:
        return Vector3(0, 0, 1);
      case SlideDirection.backward:
        return Vector3(0, 0, -1);
    }
  }

  bool canSlideInDirection(List<GameCube> allCubes) {
    Vector3 slideVector = getSlideVector();
    Vector3 targetPosition = position + slideVector;

    // Check if any other cube is blocking this direction
    for (GameCube cube in allCubes) {
      if (cube.id != id && cube.position.distanceTo(targetPosition) < 0.5) {
        return false;
      }
    }
    return true;
  }

  // Generate vertices for a cube with rounded edges
  void _generateVertices() {
    double halfSide = _sideLength / 2;
    double step = _sideLength / _edgeSubdivisions;

    // Generate vertices for each face and edges
    for (int i = 0; i <= _edgeSubdivisions; i++) {
      for (int j = 0; j <= _edgeSubdivisions; j++) {
        double x = -halfSide + i * step;
        double y = -halfSide + j * step;

        // Front face (z = halfSide)
        _vertices.add([x, y, halfSide]);
        // Back face (z = -halfSide)
        _vertices.add([x, y, -halfSide]);

        // Top face (y = halfSide)
        if (j == _edgeSubdivisions) {
          _vertices.add([x, halfSide, -halfSide + i * step]);
        }
        // Bottom face (y = -halfSide)
        if (j == 0) {
          _vertices.add([x, -halfSide, -halfSide + i * step]);
        }

        // Right face (x = halfSide)
        if (i == _edgeSubdivisions) {
          _vertices.add([halfSide, y, -halfSide + j * step]);
        }
        // Left face (x = -halfSide)
        if (i == 0) {
          _vertices.add([-halfSide, y, -halfSide + j * step]);
        }
      }
    }

    // Additional vertices for edges to smooth out corners
    for (int i = 0; i <= _edgeSubdivisions; i++) {
      double t = -halfSide + i * step;
      // Edges parallel to x-axis
      _vertices.add([t, halfSide, halfSide]);
      _vertices.add([t, -halfSide, halfSide]);
      _vertices.add([t, halfSide, -halfSide]);
      _vertices.add([t, -halfSide, -halfSide]);
      // Edges parallel to y-axis
      _vertices.add([halfSide, t, halfSide]);
      _vertices.add([-halfSide, t, halfSide]);
      _vertices.add([halfSide, t, -halfSide]);
      _vertices.add([-halfSide, t, -halfSide]);
      // Edges parallel to z-axis
      _vertices.add([halfSide, halfSide, t]);
      _vertices.add([halfSide, -halfSide, t]);
      _vertices.add([-halfSide, halfSide, t]);
      _vertices.add([-halfSide, -halfSide, t]);
    }
  }

  // Generate faces (quads) for the cube
  void _generateFaces() {
    int n = _edgeSubdivisions + 1;

    // Helper function to get vertex index
    int getVertexIndex(int i, int j, int faceType) {
      if (faceType == 0) return (i * n + j) * 2; // Front
      if (faceType == 1) return (i * n + j) * 2 + 1; // Back
      if (faceType == 2 && j == n - 1) return 2 * n * n + i; // Top
      if (faceType == 3 && j == 0) return 2 * n * n + n + i; // Bottom
      if (faceType == 4 && i == n - 1) return 2 * n * n + 2 * n + j; // Right
      if (faceType == 5 && i == 0) return 2 * n * n + 3 * n + j; // Left
      return -1; // Invalid
    }

    // Generate quads for each face
    for (int faceType = 0; faceType < 6; faceType++) {
      for (int i = 0; i < _edgeSubdivisions; i++) {
        for (int j = 0; j < _edgeSubdivisions; j++) {
          int v1 = getVertexIndex(i, j, faceType);
          int v2 = getVertexIndex(i + 1, j, faceType);
          int v3 = getVertexIndex(i + 1, j + 1, faceType);
          int v4 = getVertexIndex(i, j + 1, faceType);
          if (v1 != -1 && v2 != -1 && v3 != -1 && v4 != -1) {
            _faces.add([v1, v2, v3, v4]);
          }
        }
      }
    }

    // Additional faces for edge strips
    for (int i = 0; i < _edgeSubdivisions; i++) {
      int base = 2 * n * n + 4 * n;
      // Example: Connect top front edge to front face
      _faces.add([
        getVertexIndex(i, n - 1, 0),
        getVertexIndex(i + 1, n - 1, 0),
        base + i,
        base + i + 1,
      ]);
      // Add similar connections for other edges
    }
  }
}
