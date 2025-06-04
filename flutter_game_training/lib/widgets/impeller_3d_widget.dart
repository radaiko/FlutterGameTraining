import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;
import '../logic/game_logic.dart';
import '../models/cube.dart';

class Impeller3DWidget extends StatefulWidget {
  const Impeller3DWidget({super.key});

  @override
  State<Impeller3DWidget> createState() => _Impeller3DWidgetState();
}

class _Impeller3DWidgetState extends State<Impeller3DWidget> {
  late Impeller3DGame game;

  @override
  void initState() {
    super.initState();
    game = Impeller3DGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<Impeller3DGame>.controlled(gameFactory: () => game);
  }
}

class Impeller3DGame extends FlameGame with HasCollisionDetection {
  final GameLogic _gameLogic = GameLogic();
  final List<CubeComponent> _cubeComponents = [];
  late CameraComponent _camera;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Set up camera with better positioning
    _camera = CameraComponent();
    _camera.viewfinder.zoom = 1.0;
    _camera.viewfinder.position = Vector2(0, 0);
    add(_camera);

    // Start a new game to generate cubes
    _gameLogic.startNewGame();

    // Add a simple background
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.grey.shade800,
      position: Vector2.zero(),
    ));

    // Create 2D representations of cubes for now
    _createCubeComponents();
  }

  void _createCubeComponents() {
    // Clear existing cube components
    for (final component in _cubeComponents) {
      component.removeFromParent();
    }
    _cubeComponents.clear();

    // Debug: Print cube count
    print('Creating ${_gameLogic.cubes.length} cube components');

    // Create components for each game cube
    for (final gameCube in _gameLogic.cubes) {
      final cubeComponent = CubeComponent(gameCube);
      add(cubeComponent);
      _cubeComponents.add(cubeComponent);
      print('Added cube at position: ${gameCube.position}');
    }

    // Fallback: If no cubes, add a test cube at center
    if (_gameLogic.cubes.isEmpty) {
      print('No cubes generated, adding test cube');
      final testCube = GameCube(position: vm64.Vector3(0, 0, 0));
      final testComponent = CubeComponent(testCube);
      add(testComponent);
      _cubeComponents.add(testComponent);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update cube components if needed
    for (
      int i = 0;
      i < _cubeComponents.length && i < _gameLogic.cubes.length;
      i++
    ) {
      _cubeComponents[i].updateFromGameCube(_gameLogic.cubes[i]);
    }
  }

  void selectCube(int cubeId) {
    // Find and select the cube
    for (int i = 0; i < _gameLogic.cubes.length; i++) {
      final cube = _gameLogic.cubes[i];
      if (cube.id == cubeId) {
        cube.isSelected = !cube.isSelected;

        // Update the component
        if (i < _cubeComponents.length) {
          _cubeComponents[i].updateFromGameCube(cube);
        }
        break;
      }
    }
  }
}

class CubeComponent extends RectangleComponent {
  GameCube gameCube;

  CubeComponent(this.gameCube)
    : super(
        size: Vector2(40.0, 40.0), // Make cubes more visible
        paint: Paint()
          ..color = gameCube.isSelected ? Colors.orange : Colors.blue,
      ) {
    // Position cubes in a grid pattern, centered around (0,0)
    position = Vector2(
      gameCube.position.x * 60.0, // Increased spacing
      gameCube.position.z * 60.0,
    );
    anchor = Anchor.center;
  }

  void updateFromGameCube(GameCube cube) {
    gameCube = cube;
    paint.color = cube.isSelected ? Colors.orange : Colors.blue;
    position = Vector2(
      cube.position.x * 60.0,
      cube.position.z * 60.0,
    );
  }

  // TODO: Add tap handling for cube selection
  // @override
  // bool onTapDown(TapDownEvent event) {
  //   final game = findGame() as Impeller3DGame?;
  //   game?.selectCube(gameCube.id);
  //   return true;
  // }
}
