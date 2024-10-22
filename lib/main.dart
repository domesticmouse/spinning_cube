// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_math/vector_math.dart' as vm;

const String _kShaderBundlePath =
    'build/shaderbundles/spinning_cube.shaderbundle';

gpu.ShaderLibrary? _shaderLibrary;

gpu.ShaderLibrary get shaderLibrary {
  _shaderLibrary ??= gpu.ShaderLibrary.fromAsset(_kShaderBundlePath);
  if (_shaderLibrary == null) {
    throw Exception('Failed to load shader bundle');
  }

  return _shaderLibrary!;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  final Color _backgroundColor = Colors.black;
  double _angle = 0.0;

  late AnimationController _angleController;
  late Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    _angleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    _angleAnimation =
        Tween<double>(begin: 0.0, end: 8 * math.pi).animate(_angleController)
          ..addListener(
            () {
              setState(() {
                _angle = _angleAnimation.value;
              });
            },
          );
  }

  @override
  void dispose() {
    _angleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spinning Cube Demo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SizedBox.expand(
          child: CustomPaint(
            painter: SpinningCubePainter(
              backgroundColor: _backgroundColor,
              angle: _angle,
            ),
          ),
        ),
      ),
    );
  }
}

class SpinningCubePainter extends CustomPainter {
  const SpinningCubePainter({
    required this.backgroundColor,
    required this.angle,
  });
  final Color backgroundColor;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final colorTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.devicePrivate, size.width.ceil(), size.height.ceil());
    if (colorTexture == null) {
      throw Exception('Failed to create color texture');
    }

    final depthTexture = gpu.gpuContext.createTexture(
        gpu.StorageMode.deviceTransient, size.width.ceil(), size.height.ceil(),
        format: gpu.gpuContext.defaultDepthStencilFormat);
    if (depthTexture == null) {
      throw Exception('Failed to create depth texture');
    }

    final renderTarget = gpu.RenderTarget.singleColor(
      gpu.ColorAttachment(
          texture: colorTexture, clearValue: backgroundColor.vec4),
      depthStencilAttachment: gpu.DepthStencilAttachment(texture: depthTexture),
    );

    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    final renderPass = commandBuffer.createRenderPass(renderTarget);

    final vert = shaderLibrary['SimpleVertex'];
    if (vert == null) {
      throw Exception('Failed to load SimpleVertex vertex shader');
    }

    final frag = shaderLibrary['SimpleFragment'];
    if (frag == null) {
      throw Exception('Failed to load SimpleFragment fragment shader');
    }

    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);
    const floatsPerVertex = 6;
    final vertexList = <double>[
      // layout: x, y, z, r, g, b

      // Back Face
      -0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
      0.5, -0.5, -0.5, 0.0, 1.0, 0.0,
      0.5, 0.5, -0.5, 0.0, 0.0, 1.0,
      0.5, 0.5, -0.5, 0.0, 0.0, 1.0,
      -0.5, 0.5, -0.5, 1.0, 1.0, 0.0,
      -0.5, -0.5, -0.5, 1.0, 0.0, 0.0,

      // Front Face
      -0.5, -0.5, 0.5, 1.0, 0.0, 0.0,
      0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
      0.5, -0.5, 0.5, 0.0, 1.0, 0.0,
      0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
      -0.5, -0.5, 0.5, 1.0, 0.0, 0.0,
      -0.5, 0.5, 0.5, 1.0, 1.0, 0.0,

      // Left Face
      -0.5, 0.5, 0.5, 1.0, 0.0, 0.0,
      -0.5, -0.5, -0.5, 0.0, 0.0, 1.0,
      -0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
      -0.5, -0.5, -0.5, 0.0, 0.0, 1.0,
      -0.5, 0.5, 0.5, 1.0, 0.0, 0.0,
      -0.5, -0.5, 0.5, 1.0, 1.0, 0.0,

      // Right Face
      0.5, 0.5, 0.5, 1.0, 0.0, 0.0,
      0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
      0.5, -0.5, -0.5, 0.0, 0.0, 1.0,
      0.5, -0.5, -0.5, 0.0, 0.0, 1.0,
      0.5, -0.5, 0.5, 1.0, 1.0, 0.0,
      0.5, 0.5, 0.5, 1.0, 0.0, 0.0,

      // Bottom Face
      0.5, -0.5, -0.5, 0.0, 1.0, 0.0,
      -0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
      0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
      -0.5, -0.5, 0.5, 1.0, 1.0, 0.0,
      0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
      -0.5, -0.5, -0.5, 1.0, 0.0, 0.0,

      // Top Face
      -0.5, 0.5, -0.5, 1.0, 0.0, 0.0,
      0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
      0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
      0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
      -0.5, 0.5, 0.5, 1.0, 1.0, 0.0,
      -0.5, 0.5, -0.5, 1.0, 0.0, 0.0,
    ];
    final verticesDeviceBuffer = gpu.gpuContext.createDeviceBufferWithCopy(
      ByteData.sublistView(Float32List.fromList(vertexList)),
    );
    if (verticesDeviceBuffer == null) {
      throw Exception('Failed to create vertices device buffer');
    }

    final model = vm.Matrix4.identity()
      ..rotateY(angle)
      ..rotateX(angle / 2);
    final view = vm.Matrix4.translation(vm.Vector3(0.0, 0.0, -3.0));
    final projection =
        vm.makePerspectiveMatrix(vm.radians(45), size.aspectRatio, 0.1, 100);
    final vertUniforms = [model, view, projection];

    final vertUniformsDeviceBuffer = gpu.gpuContext.createDeviceBufferWithCopy(
        ByteData.sublistView(Float32List.fromList(
            vertUniforms.expand((m) => m.storage).toList())));

    if (vertUniformsDeviceBuffer == null) {
      throw Exception('Failed to create vert uniforms device buffer');
    }

    renderPass.bindPipeline(pipeline);

    renderPass.setCullMode(gpu.CullMode.backFace);

    final verticesView = gpu.BufferView(
      verticesDeviceBuffer,
      offsetInBytes: 0,
      lengthInBytes: verticesDeviceBuffer.sizeInBytes,
    );
    renderPass.bindVertexBuffer(
        verticesView, vertexList.length ~/ floatsPerVertex);

    final vertUniformsView = gpu.BufferView(
      vertUniformsDeviceBuffer,
      offsetInBytes: 0,
      lengthInBytes: vertUniformsDeviceBuffer.sizeInBytes,
    );

    renderPass.bindUniform(vert.getUniformSlot('VertInfo'), vertUniformsView);

    renderPass.draw();

    commandBuffer.submit();
    final image = colorTexture.asImage();
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension _ToVec4 on Color {
  vm.Vector4 get vec4 => vm.Vector4(r, g, b, a);
}
