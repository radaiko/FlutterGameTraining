import 'package:vector_math/vector_math_64.dart';

enum SlideDirection { up, down, left, right, forward, backward }

// TODO: every cube should have a unique ID
// TODO: every cube should have only one slide direction
// TODO: every cube should have a position in 3D space
// TODO: every cube should slide in it's direction when presed on it until it leaves the screen and be removed
// TODO: draw a direction arrow on the cube to indicate the slide direction

class GameCube {
  Vector3 position;
  SlideDirection slideDirection;
  bool isSelected;
  int id;

  GameCube({
    required this.position,
    required this.slideDirection,
    required this.id,
    this.isSelected = false,
  });

  GameCube copyWith({
    Vector3? position,
    SlideDirection? slideDirection,
    bool? isSelected,
    int? id,
  }) {
    return GameCube(
      position: position ?? Vector3.copy(this.position),
      slideDirection: slideDirection ?? this.slideDirection,
      isSelected: isSelected ?? this.isSelected,
      id: id ?? this.id,
    );
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
}
