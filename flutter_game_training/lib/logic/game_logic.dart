import 'package:flutter_game_training/logic/structure_generator.dart';
import 'package:flutter_game_training/models/cube.dart';
import 'package:flutter_game_training/models/player.dart';

class GameLogic {
  List<GameCube> cubes = [];
  final int _cubeLeft = 0;

  int get cubeCount => cubes.length;
  int get level => Player.level;
  int get cubesLeft => _cubeLeft;

  // Example method to start a new game
  void startNewGame() {
    cubes = StructureGenerator.generate(Player.level);
    // TODO: load the cubes into the an impeller 3D widget
  }
}
