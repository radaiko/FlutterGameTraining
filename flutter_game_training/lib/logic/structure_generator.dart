import 'package:flutter_game_training/models/cube.dart';
import 'package:vector_math/vector_math_64.dart';

class StructureGenerator {
  static List<GameCube> generate(int level) {
    List<GameCube> cubes = [];
    var cubeCount = _getCubeCountForLevel(level);
    
    // Create a simple grid layout that's easier to see
    int gridSize = (cubeCount / 3).ceil(); // Rough grid size
    double spacing = 1.0; // Spacing between cubes
    
    for (int i = 0; i < cubeCount; i++) {
      double x = (i % gridSize) * spacing - (gridSize - 1) * spacing / 2;
      double y = 0.0; // Keep all cubes at the same height for now
      double z = (i ~/ gridSize) * spacing - (gridSize - 1) * spacing / 2;
      
      Vector3 position = Vector3(x, y, z);
      cubes.add(GameCube(position: position));
    }
    return cubes;
  }

  static int _getCubeCountForLevel(int level) {
    return 3 + (level * 2); // Starts with 3 cubes, increases by 2 each level
  }
}
