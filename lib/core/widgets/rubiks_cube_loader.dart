import 'dart:math' as math;
import 'package:flutter/material.dart';

class RubiksCubeLoader extends StatefulWidget {
  final double size;
  final Duration duration;

  const RubiksCubeLoader({
    Key? key,
    this.size = 120.0,
    this.duration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<RubiksCubeLoader> createState() => _RubiksCubeLoaderState();
}

class _RubiksCubeLoaderState extends State<RubiksCubeLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // 27 Cubies: x, y, z coordinates from -1 to 1
  // We track their current logical position
  List<_CubieState> _cubies = [];

  // Current animation state
  int _moveIndex = 0;
  // Axis: 0=X, 1=Y, 2=Z
  // Slice: -1, 0, 1
  List<List<int>> _moves = [
    [1, -1], // Rotate Bottom Horizontal (around Y axis, Y=-1) - conceptually
    // Actually, for visual variety:
    [1, 1], // Top Slice (Y=1) around Y
    [0, 1], // Right Slice (X=1) around X
    [2, 1], // Front Slice (Z=1) around Z
  ];

  @override
  void initState() {
    super.initState();
    _initCubies();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack, // Mechanical snap
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _applyPermutation();
        _controller.reset();
        _moveIndex = (_moveIndex + 1) % _moves.length;
        _controller.forward();
      }
    });

    _controller.forward();
  }

  void _initCubies() {
    _cubies = [];
    for (int x = -1; x <= 1; x++) {
      for (int y = -1; y <= 1; y++) {
        for (int z = -1; z <= 1; z++) {
          _cubies.add(_CubieState(x, y, z));
        }
      }
    }
  }

  void _applyPermutation() {
    // Logically update cubie positions after a 90 degree turn
    final move = _moves[_moveIndex];
    final axis = move[0];
    final slice = move[1];

    setState(() {
      for (var cubie in _cubies) {
        bool inSlice = false;
        if (axis == 0 && cubie.x == slice) inSlice = true;
        if (axis == 1 && cubie.y == slice) inSlice = true;
        if (axis == 2 && cubie.z == slice) inSlice = true;

        if (inSlice) {
          // Rotate 90 degrees logic
          // (x, y) -> (-y, x) around Z for example
          // Since we rotate visually negative or positive, let's standardize on -90 deg visual = logical proper rotation

          int nx = cubie.x;
          int ny = cubie.y;
          int nz = cubie.z;

          if (axis == 0) {
            // Rotate around X: Y->Z, Z->-Y
            // y, z -> -z, y
            int tempY = ny;
            ny = -nz;
            nz = tempY;
          } else if (axis == 1) {
            // Rotate around Y: Z->X, X->-Z
            // z, x -> -x, z
            int tempZ = nz;
            nz = -nx;
            nx = tempZ;
          } else if (axis == 2) {
            // Rotate around Z: X->Y, Y->-X
            // x, y -> -y, x
            int tempX = nx;
            nx = -ny;
            ny = tempX;
          }

          cubie.x = nx;
          cubie.y = ny;
          cubie.z = nz;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final move = _moves[_moveIndex];
        final axis = move[0];
        final slice = move[1];
        final angle = -math.pi / 2 * _animation.value;

        // Sort cubies for painter's algorithm (render back to front)
        // Camera is looking from positive X, Y, Z generally in isometric
        // Simple depth sort: X + Y + Z descending?
        // Or transform centered first.
        // Let's rely on standard Stack order for now, but simple sorting helps.
        // Ideal isometric sort is (x + y + z)

        List<_CubieState> sortedCubies = List.from(_cubies);
        sortedCubies.sort((a, b) {
          // Basic depth sorting for isometric view
          // -x, -y, -z is back
          // Sort by distance from camera
          // Camera at say (10, 10, 10)
          // Far cubies drawn first (smaller indices)
          // Dist formula d = (x-10)^2 + ...
          // Simplify: just sum coords since camera is diagonal
          return (a.x + a.y + a.z).compareTo(b.x + b.y + b.z);
          // Actually, standard isometric is usually drawing (1,1,1) last (front-most)
          // so we sort ascending? No, wait.
          // Paint order: Back -> Front.
          // (-1,-1,-1) is furthest back. (1,1,1) is front.
          // So sort logic: Compare sum. Smallest sum = draw first.
        });

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: sortedCubies.map((cubie) {
              return _buildCubie(cubie, axis, slice, angle);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCubie(_CubieState cubie, int axis, int slice, double angle) {
    // Check if this cubie is moving
    bool isMoving = false;
    if (axis == 0 && cubie.x == slice) isMoving = true;
    if (axis == 1 && cubie.y == slice) isMoving = true;
    if (axis == 2 && cubie.z == slice) isMoving = true;

    double rotationAngle = isMoving ? angle : 0.0;

    // Apply global isometric view + local animation
    // Global view: Rotate X 45, Y 45?
    // "True" isometric: rotateX(35.264), rotateY(45)

    Matrix4 transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001); // Perspective

    // Global Camera Rotation (Static)
    transform.rotateX(math.pi / 6); // ~30 deg look down
    transform.rotateY(-math.pi / 4); // ~45 deg sideways

    // Apply Slice Rotation
    if (rotationAngle != 0) {
      if (axis == 0) transform.rotateX(rotationAngle);
      if (axis == 1) transform.rotateY(rotationAngle);
      if (axis == 2) transform.rotateZ(rotationAngle);
    }

    // Apply Translation (spacing)
    // double gap = widget.size / 3 * 0.55; // spacing factor - unused
    transform.translate(cubie.x * widget.size / 3.5,
        cubie.y * widget.size / 3.5, cubie.z * widget.size / 3.5);

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Center(
        child: Container(
          width: widget.size / 3.5,
          height: widget.size / 3.5,
          child: _CubieWidget(
              baseColor: _getCubieColor(cubie),
              highlight: isMoving // Highlight moving pieces
              ),
        ),
      ),
    );
  }

  Color _getCubieColor(_CubieState cubie) {
    // Return a base color based on position (for variety/debug)
    // or just uniform premium color
    // Let's use position to hint at faces
    if (cubie.x == 1) return const Color(0xFFFF4747); // Right - Red
    if (cubie.x == -1) return const Color(0xFFFFB547); // Left - Orange
    if (cubie.y == 1)
      return const Color(
          0xFFFFFFFF); // Down - White? In 3D Y is usually up/down. Flutter Y is down.
    if (cubie.y == -1) return const Color(0xFFFFFF00); // Up - Yellow
    if (cubie.z == 1) return const Color(0xFF00D1FF); // Front - Cyan/Blue
    if (cubie.z == -1) return const Color(0xFF05CD99); // Back - Green

    return const Color(0xFF2B3674); // Core/Internal - Dark Blue
  }
}

class _CubieState {
  int x, y, z;
  _CubieState(this.x, this.y, this.z);
}

class _CubieWidget extends StatelessWidget {
  final Color baseColor;
  final bool highlight;

  const _CubieWidget({required this.baseColor, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    // 3D-looking Container using standard BoxDecoration techniques
    // To look like a cube, we need to fake 3 visible faces or use a real 3D renderer if we wanted perfection.
    // Simplifying: Just a rounded "tile" that rotates in 3D space provided by parent Transform

    return Container(
      decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            // Soft shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
            // Highlight glow if moving
            if (highlight)
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor,
              baseColor.withOpacity(0.8),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          )),
      // Optional: Add inner details or logo
    );
  }
}
