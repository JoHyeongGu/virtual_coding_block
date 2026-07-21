import 'dart:async';
import 'package:flutter/material.dart';
import 'block_container.dart';
import 'dial_block_widget.dart';
import 'packet.dart';
import 'dart:math';

class Preset {
  final String name;
  final List<Map<String, dynamic>> blocks;
  final List<Map<String, dynamic>>? functionBlocks;
  Preset({required this.name, required this.blocks, this.functionBlocks});
}

class PresetGroup {
  final String groupName;
  final List<Preset> presets;
  PresetGroup({required this.groupName, required this.presets});
}

class BlockType {
  final String id;
  final String name;
  final Color color;
  final int? command;
  final bool isPlayBlock;
  final bool isNumberBlock;
  final bool isSensorBlock;
  final bool isDirectionBlock;
  final bool isDialBlock;
  final String imagePath;

  const BlockType({
    required this.id,
    required this.name,
    required this.color,
    this.command,
    this.isPlayBlock = false,
    this.isNumberBlock = false,
    this.isSensorBlock = false,
    this.isDirectionBlock = false,
    this.isDialBlock = false,
    this.imagePath = '',
  });

  bool get isParamBlock =>
      isNumberBlock || isSensorBlock || isDirectionBlock || isDialBlock;
}

class PlacedBlock {
  final BlockType type;
  Offset position;
  PlacedBlock? attachedNumberBlock;
  PlacedBlock? attachedDialBlock;
  PlacedBlock? parentActionBlock;
  PlacedBlock? next;
  double dialValue;
  bool isDecimal;
  String dialInput;

  PlacedBlock(this.type, this.position)
    : dialValue = 1.0,
      isDecimal = false,
      dialInput = '01';
}

class DraggingGroupItem {
  final PlacedBlock block;
  final Offset relativeOffset;
  DraggingGroupItem(this.block, this.relativeOffset);
}

class BlocksView extends StatefulWidget {
  final bool play;
  final Function(List<int>) onSend;
  final VoidCallback onOpenTerminal;

  const BlocksView({
    super.key,
    required this.play,
    required this.onSend,
    required this.onOpenTerminal,
  });

  @override
  State<BlocksView> createState() => BlocksViewState();
}

class BlocksViewState extends State<BlocksView> {
  static const Color controlColor = Color.fromARGB(255, 255, 230, 79);
  static const double blockSpacing = 55.0;
  int _seqNum = 1;
  List<PlacedBlock> _savedFunctionBlocks = [];
  PlacedBlock? _editingBlock;

  int _frontSensor = 0;
  int _bottomSensor = 0;
  int _lightSensor = 0;

  final List<PresetGroup> _presetGroups = [
    PresetGroup(
      groupName: "[VRWARE StoryCoding] 앨리스",
      presets: [
        Preset(
          name: "1스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': "NUM_2"},
            {'id': 'MOVE', 'param': "DIR_RIGHT"},
            {'id': 'MOVE', 'param': "NUM_2"},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "1스테이지, 스텝 2",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', "param": "NUM_3"},
            {'id': 'MOVE'},
            {'id': 'MOVE', "param": "DIR_RIGHT"},
            {'id': 'MOVE'},
            {'id': 'MOVE', "param": "DIR_LEFT"},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "1스테이지, 스텝 3",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_2'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'MOVE', 'param': 'NUN_2'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "2스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_6'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "2스테이지, 스텝 2",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_3'},
            {'id': 'MOVE', 'param': 'NUM_3'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'CLOSE'},
            {'id': 'MOVE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "3스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_2'},
            {'id': 'MOVE', 'param': 'NUM_3'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'CLOSE'},
            {'id': 'MOVE', 'param': 'NUM_3'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "4스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_6'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'MOVE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "4스테이지, 스텝 2",
          blocks: [
            {'id': 'START'},
            {'id': 'FUNCTION'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'PLAY'},
          ],
          functionBlocks: [
            {'id': 'REPEAT', 'param': 'NUM_3'},
            {'id': 'MOVE'},
            {'id': 'IF', 'param': 'SENSOR_FLOOR'},
            {'id': 'LED_ON', 'param': 'NUM_2'},
            {'id': 'CLOSE'},
            {'id': 'CLOSE'},
          ],
        ),
        Preset(
          name: "5스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_2'},
            {'id': 'MOVE', 'param': 'NUM_2'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "5스테이지, 스텝 2",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_3'},
            {'id': 'REPEAT', 'param': 'NUM_2'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'MOVE', 'param': 'NUM_2'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "5스테이지, 스텝 3",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_3'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "5스테이지, 스텝 4",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_4'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
      ],
    ),
    PresetGroup(
      groupName: "[VRWARE StroyCoding] 인어공주",
      presets: [
        Preset(
          name: "1스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_2'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'MOVE', 'param': 'NUM_3'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "1스테이지, 스텝 2",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_3'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "1스테이지, 스텝 3",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_3'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'MOVE', 'param': 'NUM_3'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "2스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_4'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'MOVE'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "2스테이지, 스텝 2",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_4'},
            {'id': 'REPEAT', 'param': 'NUM_2'},
            {'id': 'MOVE', 'param': 'DIR_LEFT'},
            {'id': 'MOVE', 'param': 'NUM_4'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "2스테이지, 스텝 3",
          blocks: [
            {'id': 'START'},
            {'id': 'REPEAT', 'param': 'NUM_3'},
            {'id': 'MOVE', 'param': 'NUM_5'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "3스테이지, 스텝 1",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE', 'param': 'NUM_4'},
            {'id': 'MOVE', 'param': 'DIR_RIGHT'},
            {'id': 'MOVE', 'param': 'NUM_2'},
            {'id': 'PLAY'},
          ],
        ),
        Preset(
          name: "3스테이지, 스텝 2",
          blocks: [
            {'id': 'START'},
            {'id': 'MOVE'},
            {'id': 'REPEAT'},
            {'id': 'IF', 'param': 'SENSOR_FRONT'},
            {'id': 'SOUND', 'param': 'NUM_5'},
            {'id': 'ELSE'},
            {'id': 'MOVE', 'param': 'NUM_2'},
            {'id': 'CLOSE'},
            {'id': 'CLOSE'},
            {'id': 'PLAY'},
          ],
        ),
      ],
    ),
  ];

  void _applyPreset(Preset preset) {
    List<PlacedBlock> existingBlocks = List.from(_workspaceBlocks);
    List<PlacedBlock> newWorkspace = [];
    Map<String, int> tempCounts = Map.from(_inventoryCounts);

    bool canApply = true;

    for (var p in preset.blocks) {
      PlacedBlock? found = existingBlocks.firstWhere(
        (b) => b.type.id == p['id'],
        orElse: () => PlacedBlock(
          BlockType(id: 'dummy', name: '', color: Colors.transparent),
          Offset.zero,
        ),
      );

      PlacedBlock currentActionBlock;

      if (found.type.id != 'dummy') {
        existingBlocks.remove(found);
        found.attachedNumberBlock = null;
        found.parentActionBlock = null;
        currentActionBlock = found;
      } else if ((tempCounts[p['id']] ?? 0) > 0) {
        tempCounts[p['id']] = tempCounts[p['id']]! - 1;
        final type = _actionTypes.firstWhere((t) => t.id == p['id']);
        currentActionBlock = PlacedBlock(type, Offset.zero);
      } else {
        canApply = false;
        break;
      }

      newWorkspace.add(currentActionBlock);

      if (p.containsKey('param')) {
        String paramId = p['param'];
        PlacedBlock? paramFound = existingBlocks.firstWhere(
          (b) => b.type.id == paramId,
          orElse: () => PlacedBlock(
            BlockType(id: 'dummy', name: '', color: Colors.transparent),
            Offset.zero,
          ),
        );

        PlacedBlock currentParamBlock;

        if (paramFound.type.id != 'dummy') {
          existingBlocks.remove(paramFound);
          paramFound.attachedNumberBlock = null;
          paramFound.parentActionBlock = null;
          currentParamBlock = paramFound;
        } else if ((tempCounts[paramId] ?? 0) > 0) {
          tempCounts[paramId] = tempCounts[paramId]! - 1;
          final paramType = _parameterTypes.firstWhere((t) => t.id == paramId);
          currentParamBlock = PlacedBlock(paramType, Offset.zero);
        } else {
          canApply = false;
          break;
        }

        currentActionBlock.attachedNumberBlock = currentParamBlock;
        currentParamBlock.parentActionBlock = currentActionBlock;
        newWorkspace.add(currentParamBlock);
      }
    }

    if (canApply) {
      setState(() {
        _inventoryCounts = tempCounts;
        _workspaceBlocks.clear();

        if (preset.functionBlocks != null) {
          _savedFunctionBlocks = [];
          for (var fb in preset.functionBlocks!) {
            final actionType = _actionTypes.firstWhere((t) => t.id == fb['id']);
            final actionBlock = PlacedBlock(actionType, Offset.zero);

            if (fb.containsKey('param')) {
              final paramId = fb['param'];
              final paramType = _parameterTypes.firstWhere(
                (t) => t.id == paramId,
              );
              final paramBlock = PlacedBlock(paramType, Offset.zero);
              actionBlock.attachedNumberBlock = paramBlock;
              paramBlock.parentActionBlock = actionBlock;
            }
            _savedFunctionBlocks.add(actionBlock);
          }
        } else {
          _savedFunctionBlocks = [];
        }

        double currentX = 300.0;
        double currentY = 200.0;
        BlockType? prevType;

        for (var b in newWorkspace) {
          if (b.type.isNumberBlock ||
              b.type.isSensorBlock ||
              b.type.isDirectionBlock) {
            b.position = Offset(
              b.parentActionBlock!.position.dx + 120,
              b.parentActionBlock!.position.dy + 5,
            );
            _workspaceBlocks.add(b);
            continue;
          }

          if (prevType != null) {
            double spacing =
                ((prevType.id == 'IF' || prevType.id == 'REPEAT') &&
                    b.type.id == 'CLOSE')
                ? (blockSpacing + 30.0)
                : blockSpacing;
            currentY += spacing;
            currentX += _getChildXOffset(prevType, b.type);
          }
          b.position = Offset(currentX, currentY);
          prevType = b.type;
          _workspaceBlocks.add(b);
        }

        for (var b in existingBlocks) {
          b.attachedNumberBlock = null;
          b.parentActionBlock = null;
        }
        _workspaceBlocks.addAll(existingBlocks);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('블록 총 개수가 부족합니다.')));
    }
  }

  final List<BlockType> _actionTypes = [
    const BlockType(
      id: "START",
      name: '시작',
      color: Color(0xFFE4552D),
      command: 0x04,
    ),
    const BlockType(id: "FUNCTION", name: '함수', color: Color(0xFFE4552D)),
    const BlockType(
      id: "MOVE",
      name: '이동하기',
      color: Color(0xFF23CAB8),
      command: 0x05,
    ),
    const BlockType(
      id: "LED_ON",
      name: 'LED 켜기',
      color: Color(0xFF23CAB8),
      command: 0x0B,
    ),
    const BlockType(
      id: "SOUND",
      name: '소리내기',
      color: Color(0xFF23CAB8),
      command: 0x0F,
    ),
    const BlockType(id: "WAIT", name: '기다리기', color: Colors.yellow),
    const BlockType(
      id: "REPEAT",
      name: '반복하기',
      color: controlColor,
      command: 0x03,
    ),
    const BlockType(id: "IF", name: '만약에', color: controlColor, command: 0x0C),
    const BlockType(
      id: "ELSE",
      name: '아니면',
      color: controlColor,
      command: 0x0E,
    ),
    const BlockType(id: "CLOSE", name: '', color: controlColor, command: 0),
    const BlockType(
      id: "PLAY",
      name: '',
      color: Colors.grey,
      isPlayBlock: true,
    ),
  ];

  final List<BlockType> _parameterTypes = [
    const BlockType(
      id: 'NUM_1',
      name: '1',
      color: Colors.white,
      command: 1,
      isNumberBlock: true,
      imagePath: 'assets/block_images/count_1.png',
    ),
    const BlockType(
      id: 'NUM_2',
      name: '2',
      color: Colors.white,
      command: 2,
      isNumberBlock: true,
      imagePath: 'assets/block_images/count_2.png',
    ),
    const BlockType(
      id: 'NUM_3',
      name: '3',
      color: Colors.white,
      command: 3,
      isNumberBlock: true,
      imagePath: 'assets/block_images/count_3.png',
    ),
    const BlockType(
      id: 'NUM_4',
      name: '4',
      color: Colors.white,
      command: 4,
      isNumberBlock: true,
      imagePath: 'assets/block_images/count_4.png',
    ),
    const BlockType(
      id: 'NUM_5',
      name: '5',
      color: Colors.white,
      command: 5,
      isNumberBlock: true,
      imagePath: 'assets/block_images/count_5.png',
    ),
    const BlockType(
      id: 'NUM_6',
      name: '6',
      color: Colors.white,
      command: 6,
      isNumberBlock: true,
      imagePath: 'assets/block_images/count_6.png',
    ),
    const BlockType(
      id: 'NUM_7',
      name: '7',
      color: Colors.white,
      command: 7,
      isNumberBlock: true,
      imagePath: 'assets/block_images/count_7.png',
    ),
    const BlockType(
      id: 'DIR_FORWARD',
      name: '앞으로',
      color: Colors.white,
      command: 0x05,
      isDirectionBlock: true,
      imagePath: 'assets/block_images/forward_arrow.png',
    ),
    const BlockType(
      id: 'DIR_BACKWARD',
      name: '뒤로',
      color: Colors.white,
      command: 0x06,
      isDirectionBlock: true,
      imagePath: 'assets/block_images/backward_arrow.png',
    ),
    const BlockType(
      id: 'DIR_LEFT',
      name: '왼쪽',
      color: Colors.white,
      command: 0x07,
      isDirectionBlock: true,
      imagePath: 'assets/block_images/left_arrow.png',
    ),
    const BlockType(
      id: 'DIR_RIGHT',
      name: '오른쪽',
      color: Colors.white,
      command: 0x08,
      isDirectionBlock: true,
      imagePath: 'assets/block_images/right_arrow.png',
    ),
    const BlockType(
      id: 'SENSOR_FRONT',
      name: '전방센서',
      color: Colors.white,
      command: 8,
      isSensorBlock: true,
    ),
    const BlockType(
      id: 'SENSOR_FLOOR',
      name: '바닥센서',
      color: Colors.white,
      command: 9,
      isSensorBlock: true,
    ),
    const BlockType(
      id: 'SENSOR_LIGHT',
      name: '빛센서',
      color: Colors.white,
      command: 10,
      isSensorBlock: true,
    ),
    const BlockType(
      id: 'NUM_RANDOM',
      name: '랜덤',
      color: Colors.white,
      imagePath: 'assets/block_images/count_random.png',
      isNumberBlock: true,
    ),
    const BlockType(
      id: 'DIAL',
      name: '',
      color: Colors.black,
      isDialBlock: true,
    ),
  ];

  Map<String, int> _inventoryCounts = {
    'START': 1,
    'MOVE': 4,
    'FUNCTION': 1,
    'WAIT': 2,
    'LED_ON': 2,
    'SOUND': 1,
    'PLAY': 1,
    'REPEAT': 1,
    'IF': 1,
    'ELSE': 1,
    'CLOSE': 2,
    'NUM_1': 1,
    'NUM_2': 3,
    'NUM_3': 3,
    'NUM_4': 2,
    'NUM_5': 1,
    'NUM_6': 1,
    'NUM_7': 1,
    'DIR_FORWARD': 6,
    'DIR_BACKWARD': 6,
    'DIR_LEFT': 6,
    'DIR_RIGHT': 6,
    'SENSOR_FRONT': 1,
    'SENSOR_FLOOR': 1,
    'SENSOR_LIGHT': 1,
    'NUM_RANDOM': 2,
    'DIAL': 2,
  };

  final List<PlacedBlock> _workspaceBlocks = [];
  List<DraggingGroupItem> _activeDraggingGroup = [];
  PlacedBlock? _primaryDraggedBlock;
  PlacedBlock? _blinkingPlayBlock;

  Completer<void>? _responseCompleter;
  bool _isPlaying = false;
  int? _executingStep;

  @override
  void didUpdateWidget(covariant BlocksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.play && !widget.play) {
      setState(() {
        _workspaceBlocks.clear();
        _activeDraggingGroup.clear();
        _primaryDraggedBlock = null;
        _inventoryCounts.updateAll(
          (key, value) =>
              {
                'START': 1,
                'FUNCTION': 1,
                'WAIT': 2,
                'MOVE': 4,
                'LED_ON': 2,
                'SOUND': 1,
                'PLAY': 1,
                'REPEAT': 1,
                'IF': 1,
                'ELSE': 1,
                'CLOSE': 2,
                'NUM_1': 1,
                'NUM_2': 3,
                'NUM_3': 3,
                'NUM_4': 2,
                'NUM_5': 1,
                'NUM_6': 1,
                'NUM_7': 1,
                'DIR_FORWARD': 6,
                'DIR_BACKWARD': 6,
                'DIR_LEFT': 6,
                'DIR_RIGHT': 6,
                'SENSOR_FRONT': 1,
                'SENSOR_FLOOR': 1,
                'SENSOR_LIGHT': 1,
                'NUM_RANDOM': 2,
                'DIAL': 2,
              }[key] ??
              3,
        );
      });
    }
  }

  double _getChildXOffset(BlockType parent, BlockType child) {
    double offset = 0;
    if (parent.id == 'IF' || parent.id == 'REPEAT') {
      offset += 50;
    }
    if (child.id == 'CLOSE') offset -= 50;
    return offset;
  }

  List<PlacedBlock> _getDescendants(PlacedBlock root) {
    List<PlacedBlock> descendants = [];
    PlacedBlock current = root;
    while (true) {
      PlacedBlock? child = _workspaceBlocks.where((b) {
        if (b.type.isNumberBlock ||
            b.type.isSensorBlock ||
            b.type.isDirectionBlock) {
          return false;
        }
        double expectedX =
            current.position.dx + _getChildXOffset(current.type, b.type);
        double spacing =
            ((current.type.id == 'IF' || current.type.id == 'REPEAT') &&
                b.type.id == 'CLOSE')
            ? (blockSpacing + 30)
            : blockSpacing;
        double expectedY = current.position.dy + spacing;
        return (b.position.dx - expectedX).abs() <= 10.0 &&
            (b.position.dy - expectedY).abs() <= 10.0;
      }).firstOrNull;
      if (child == null) break;
      descendants.add(child);
      current = child;
    }
    return descendants;
  }

  void _snapBlock(PlacedBlock block) {
    if (block.type.isParamBlock) {
      for (var other in _workspaceBlocks) {
        if (other.type.isParamBlock ||
            other.type.isPlayBlock ||
            other.type.id == 'START') {
          continue;
        }

        if (block.type.isDialBlock) {
          if (other.attachedDialBlock != null &&
              other.attachedDialBlock != block) {
            continue;
          }

          double targetX = other.position.dx + 170;
          double targetY = other.position.dy + 5;

          if ((block.position.dx - targetX).abs() < 40 &&
              (block.position.dy - targetY).abs() < 40) {
            block.position = Offset(targetX, targetY);
            other.attachedDialBlock = block;
            block.parentActionBlock = other;
            return;
          }
        } else {
          if (other.attachedNumberBlock != null &&
              other.attachedNumberBlock != block) {
            continue;
          }

          double targetX = other.position.dx + 120;
          double targetY = other.position.dy + 5;

          if ((block.position.dx - targetX).abs() < 40 &&
              (block.position.dy - targetY).abs() < 40) {
            block.position = Offset(targetX, targetY);
            other.attachedNumberBlock = block;
            block.parentActionBlock = other;
            return;
          }
        }
      }
    } else {
      for (var other in _workspaceBlocks) {
        if (other == block || other.type.isParamBlock) {
          continue;
        }

        if (!other.type.isPlayBlock) {
          double spacing =
              ((other.type.id == 'IF' || other.type.id == 'REPEAT') &&
                  block.type.id == 'CLOSE')
              ? (blockSpacing + 15.0)
              : blockSpacing;
          double expectedX =
              other.position.dx + _getChildXOffset(other.type, block.type);
          double expectedY = other.position.dy + spacing;

          if ((block.position.dx - expectedX).abs() < 40 &&
              (block.position.dy - expectedY).abs() < 40) {
            bool isSlotTaken = _workspaceBlocks.any((b) {
              if (b == other || b == block || b.type.isParamBlock) {
                return false;
              }
              if (_activeDraggingGroup.any((item) => item.block == b)) {
                return false;
              }

              bool physicallyOccupying =
                  (b.position.dx - expectedX).abs() < 35 &&
                  (b.position.dy - expectedY).abs() < 35;
              double bSpc =
                  ((other.type.id == 'IF' || other.type.id == 'REPEAT') &&
                      b.type.id == 'CLOSE')
                  ? (blockSpacing + 15.0)
                  : blockSpacing;
              double bExpX =
                  other.position.dx + _getChildXOffset(other.type, b.type);
              bool logicallyAttached =
                  (b.position.dx - bExpX).abs() < 35 &&
                  (b.position.dy - (other.position.dy + bSpc)).abs() < 35;
              return physicallyOccupying || logicallyAttached;
            });

            if (!isSlotTaken) {
              block.position = Offset(expectedX, expectedY);
              return;
            }
          }
        }

        if (other.type.id != 'START' && !block.type.isPlayBlock) {
          double spacing =
              ((block.type.id == 'IF' || block.type.id == 'REPEAT') &&
                  other.type.id == 'CLOSE')
              ? (blockSpacing + 15.0)
              : blockSpacing;
          double expectedX =
              other.position.dx - _getChildXOffset(block.type, other.type);
          double expectedY = other.position.dy - spacing;

          if ((block.position.dx - expectedX).abs() < 40 &&
              (block.position.dy - expectedY).abs() < 40) {
            bool isSlotTaken = _workspaceBlocks.any((p) {
              if (p == other ||
                  p == block ||
                  p.type.isParamBlock ||
                  p.type.isPlayBlock) {
                return false;
              }
              if (_activeDraggingGroup.any((item) => item.block == p)) {
                return false;
              }

              bool physicallyOccupying =
                  (p.position.dx - expectedX).abs() < 35 &&
                  (p.position.dy - expectedY).abs() < 35;
              double pSpc =
                  ((p.type.id == 'IF' || p.type.id == 'REPEAT') &&
                      other.type.id == 'CLOSE')
                  ? (blockSpacing + 15.0)
                  : blockSpacing;
              double pExpX =
                  p.position.dx + _getChildXOffset(p.type, other.type);
              bool logicallyAttached =
                  (other.position.dx - pExpX).abs() < 35 &&
                  (other.position.dy - (p.position.dy + pSpc)).abs() < 35;
              return physicallyOccupying || logicallyAttached;
            });

            bool blockHasChildren = _activeDraggingGroup.any(
              (item) => item.block != block && !item.block.type.isParamBlock,
            );
            if (!isSlotTaken && !blockHasChildren) {
              block.position = Offset(expectedX, expectedY);
              return;
            }
          }
        }
      }
    }
  }

  int _findMatchingClose(List<PlacedBlock> seq, int start, int end) {
    int depth = 0;
    for (int i = start + 1; i < end; i++) {
      if (seq[i].type.id == 'IF' || seq[i].type.id == 'REPEAT') {
        depth++;
      } else if (seq[i].type.id == 'CLOSE') {
        if (depth == 0) return i;
        depth--;
      }
    }
    return end;
  }

  int _findMatchingElse(List<PlacedBlock> seq, int start, int end) {
    int depth = 0;
    for (int i = start + 1; i < end; i++) {
      if (seq[i].type.id == 'IF' || seq[i].type.id == 'REPEAT') {
        depth++;
      } else if (seq[i].type.id == 'CLOSE') {
        if (depth == 0) return -1;
        depth--;
      } else if (seq[i].type.id == 'ELSE') {
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  void handleIncomingData(List<int> data) {
    if (data.length >= 5 && data.first == 0x7C && data.last == 0x7E) {
      List<int> decoded = [];
      for (int i = 1; i < data.length - 1; i++) {
        if (data[i] == 0x7D && i + 1 < data.length - 1) {
          decoded.add(data[i + 1] ^ 0x20);
          i++;
        } else {
          decoded.add(data[i]);
        }
      }
      if (decoded.isNotEmpty && decoded[0] == 0x02) {
        // decoded[0]=CMD, decoded[1]=SEQ
        int offset = 2;

        _frontSensor = decoded[offset] | (decoded[offset + 1] << 8);
        _bottomSensor = decoded[offset + 2] | (decoded[offset + 3] << 8);
        _lightSensor = decoded[offset + 4] | (decoded[offset + 5] << 8);
      }
    }

    if (_isPlaying &&
        _responseCompleter != null &&
        !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete();
    }
  }

  double getParamValue(PlacedBlock? paramBlock, PlacedBlock? dialBlock) {
    if (dialBlock != null) {
      double base = double.tryParse(dialBlock.dialInput) ?? 1.0;
      return dialBlock.isDecimal ? base / 10.0 : base;
    }
    if (paramBlock == null) return 1.0;
    if (paramBlock.type.id == 'NUM_RANDOM') {
      return (Random().nextInt(7) + 1).toDouble();
    }
    return double.tryParse(paramBlock.type.name) ?? 1.0;
  }

  Future<void> _executeAst(List<PlacedBlock> seq, int start, int end) async {
    int i = start;
    while (i < end) {
      if (!_isPlaying) break;
      PlacedBlock block = seq[i];
      setState(() => _executingStep = _workspaceBlocks.indexOf(block));

      if (block.type.id == 'REPEAT') {
        int? count = getParamValue(
          block.attachedNumberBlock,
          block.attachedDialBlock,
        ).toInt();
        int closeIdx = _findMatchingClose(seq, i, end);

        if (count <= 0) {
          while (_isPlaying) {
            await _executeAst(seq, i + 1, closeIdx);
          }
        } else {
          for (int c = 0; c < count; c++) {
            if (!_isPlaying) break;
            await _executeAst(seq, i + 1, closeIdx);
          }
        }
        i = closeIdx;
      } else if (block.type.id == 'IF') {
        bool condition = true;

        if (block.attachedNumberBlock != null &&
            block.attachedNumberBlock!.type.isSensorBlock) {
          List<int> packetBytes = createPacket(0x03, _seqNum, []);
          widget.onSend(packetBytes);
          _seqNum = (_seqNum % 255) + 1;

          _responseCompleter = Completer<void>();
          await _responseCompleter!.future;

          String sensorId = block.attachedNumberBlock!.type.id;
          if (sensorId == 'SENSOR_FRONT') {
            condition = _frontSensor <= 0x0800;
          } else if (sensorId == 'SENSOR_FLOOR') {
            condition = _bottomSensor > 0x0800;
          } else if (sensorId == 'SENSOR_LIGHT') {
            condition = _lightSensor <= 0x00C0;
          }
        }

        int elseIdx = _findMatchingElse(seq, i, end);
        int closeIdx = _findMatchingClose(seq, i, end);

        if (condition) {
          await _executeAst(seq, i + 1, elseIdx != -1 ? elseIdx : closeIdx);
        } else if (elseIdx != -1) {
          await _executeAst(seq, elseIdx + 1, closeIdx);
        }
        i = closeIdx;
      } else if (block.type.id == 'ELSE' || block.type.id == 'CLOSE') {
        i++;
      } else if (block.type.id == 'WAIT') {
        int val =
            int.tryParse(block.attachedNumberBlock?.type.name ?? '1') ?? 1;
        await Future.delayed(Duration(seconds: val));
        i++;
      } else if (block.type.id == 'FUNCTION') {
        await _executeAst(_savedFunctionBlocks, 0, _savedFunctionBlocks.length);
        i++;
      } else if (!block.type.isPlayBlock) {
        int cmd = block.type.command!;
        List<int> payload = [];

        if (block.type.id == 'MOVE') {
          double val = getParamValue(
            block.attachedNumberBlock?.type.isDirectionBlock == true
                ? null
                : block.attachedNumberBlock,
            block.attachedDialBlock,
          );
          if (block.attachedNumberBlock != null &&
              block.attachedNumberBlock!.type.isDirectionBlock) {
            cmd = block.attachedNumberBlock!.type.command!;
          }
          payload = [(val * 10).toInt(), 0, 0, 0];
        } else if (block.type.id == 'LED_ON') {
          double val = getParamValue(
            block.attachedNumberBlock,
            block.attachedDialBlock,
          );
          payload = [val.toInt(), 0, 0, 0];
        } else if (block.type.id == 'SOUND') {
          double val = getParamValue(
            block.attachedNumberBlock,
            block.attachedDialBlock,
          );
          payload = [val.toInt(), 0];
        }

        List<int> packetBytes = createPacket(cmd, _seqNum, payload);
        widget.onSend(packetBytes);
        _seqNum = (_seqNum % 255) + 1;

        _responseCompleter = Completer<void>();
        await _responseCompleter!.future;
        i++;
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
        i++;
      }
    }
  }

  Future<void> _playSequenceFrom(PlacedBlock playBlock) async {
    if (_isPlaying) return;
    PlacedBlock current = playBlock;
    List<PlacedBlock> sequence = [current];

    while (true) {
      PlacedBlock? prev = _workspaceBlocks.where((b) {
        if (b.type.isNumberBlock ||
            b.type.isSensorBlock ||
            b.type.isDirectionBlock) {
          return false;
        }
        double expectedX =
            b.position.dx + _getChildXOffset(b.type, current.type);
        double expectedY = b.position.dy + blockSpacing;
        return (current.position.dx - expectedX).abs() < 5 &&
            (current.position.dy - expectedY).abs() < 5;
      }).firstOrNull;

      if (prev == null) break;
      sequence.insert(0, prev);
      current = prev;
    }

    bool hasStart = sequence.any((b) => b.type.id == 'START');
    if (!hasStart) {
      if (sequence.isNotEmpty && sequence.first.type.id == 'FUNCTION') {
        _savedFunctionBlocks = sequence.sublist(1).map((b) {
          var newB = PlacedBlock(b.type, b.position);
          if (b.attachedNumberBlock != null) {
            newB.attachedNumberBlock = PlacedBlock(
              b.attachedNumberBlock!.type,
              b.attachedNumberBlock!.position,
            );
          }
          return newB;
        }).toList();
      }

      for (int i = 0; i < 3; i++) {
        setState(() => _blinkingPlayBlock = playBlock);
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() => _blinkingPlayBlock = null);
        await Future.delayed(const Duration(milliseconds: 150));
      }
      return;
    }

    setState(() => _isPlaying = true);
    await _executeAst(sequence, 0, sequence.length);
    setState(() {
      _isPlaying = false;
      _executingStep = null;
    });
  }

  void _stopSequence() {
    setState(() {
      _isPlaying = false;
      _executingStep = null;
      _blinkingPlayBlock = null;
    });

    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete();
    }
  }

  Widget _buildDraggingFeedback(PlacedBlock rootBlock) {
    if (rootBlock.type.isParamBlock) {
      return Material(
        color: Colors.transparent,
        child: _buildBlockItem(rootBlock.type, false, rootBlock),
      );
    }
    final descendants = _getDescendants(rootBlock);
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBlockItem(rootBlock.type, false, rootBlock),
          if (rootBlock.attachedNumberBlock != null)
            Positioned(
              left: 120,
              top: 5,
              child: _buildBlockItem(
                rootBlock.attachedNumberBlock!.type,
                false,
                rootBlock.attachedNumberBlock,
              ),
            ),
          if (rootBlock.attachedDialBlock != null)
            Positioned(
              left: 170,
              top: 5,
              child: _buildBlockItem(
                rootBlock.attachedDialBlock!.type,
                false,
                rootBlock.attachedDialBlock,
              ),
            ),
          ...List.generate(descendants.length, (index) {
            final desc = descendants[index];
            final double relativeY = desc.position.dy - rootBlock.position.dy;
            final double relativeX = desc.position.dx - rootBlock.position.dx;
            return Positioned(
              top: relativeY,
              left: relativeX,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildBlockItem(desc.type, false, desc),
                  if (desc.attachedNumberBlock != null)
                    Positioned(
                      left: 120,
                      top: 5,
                      child: _buildBlockItem(
                        desc.attachedNumberBlock!.type,
                        false,
                        desc.attachedNumberBlock,
                      ),
                    ),
                  if (desc.attachedDialBlock != null)
                    Positioned(
                      left: 170,
                      top: 5,
                      child: _buildBlockItem(
                        desc.attachedDialBlock!.type,
                        false,
                        desc.attachedDialBlock,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: DragTarget<BlockType>(
                onAcceptWithDetails: (details) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  setState(() {
                    final type = details.data;
                    if ((_inventoryCounts[type.id] ?? 0) > 0) {
                      _inventoryCounts[type.id] =
                          _inventoryCounts[type.id]! - 1;
                      final newBlock = PlacedBlock(
                        type,
                        renderBox.globalToLocal(details.offset),
                      );
                      _workspaceBlocks.add(newBlock);
                      _snapBlock(newBlock);
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: Stack(
                      children: [
                        ...List.generate(_workspaceBlocks.length, (index) {
                          final block = _workspaceBlocks[index];
                          bool isExecuting = false;
                          if (_executingStep != null) {
                            if (block.type.isParamBlock) {
                              if (block.parentActionBlock != null &&
                                  _workspaceBlocks.indexOf(
                                        block.parentActionBlock!,
                                      ) ==
                                      _executingStep) {
                                isExecuting = true;
                              }
                            } else {
                              isExecuting = _executingStep == index;
                            }
                          }

                          final isBeingDragged = _primaryDraggedBlock == block;
                          final isHidden =
                              _activeDraggingGroup.any(
                                (item) => item.block == block,
                              ) &&
                              !isBeingDragged;

                          return Positioned(
                            left: block.position.dx,
                            top: block.position.dy,
                            child: Opacity(
                              opacity: isHidden ? 0.0 : 1.0,
                              child: IgnorePointer(
                                ignoring: isHidden,
                                child: Draggable<PlacedBlock>(
                                  data: block,
                                  maxSimultaneousDrags: _editingBlock == block
                                      ? 0
                                      : 1,
                                  feedback: _buildDraggingFeedback(block),
                                  childWhenDragging: const SizedBox.shrink(),
                                  onDragStarted: () {
                                    setState(() {
                                      _primaryDraggedBlock = block;
                                      if (block.type.isParamBlock) {
                                        if (block.parentActionBlock != null) {
                                          if (block.type.isDialBlock) {
                                            block
                                                    .parentActionBlock!
                                                    .attachedDialBlock =
                                                null;
                                          } else {
                                            block
                                                    .parentActionBlock!
                                                    .attachedNumberBlock =
                                                null;
                                          }
                                          block.parentActionBlock = null;
                                        }
                                        _activeDraggingGroup = [
                                          DraggingGroupItem(block, Offset.zero),
                                        ];
                                      } else {
                                        _activeDraggingGroup = [
                                          DraggingGroupItem(block, Offset.zero),
                                        ];
                                        List<PlacedBlock> descendants =
                                            _getDescendants(block);
                                        List<PlacedBlock> fullActionList = [
                                          block,
                                          ...descendants,
                                        ];
                                        for (var b in fullActionList) {
                                          if (b != block) {
                                            _activeDraggingGroup.add(
                                              DraggingGroupItem(
                                                b,
                                                b.position - block.position,
                                              ),
                                            );
                                          }
                                          if (b.attachedNumberBlock != null) {
                                            _activeDraggingGroup.add(
                                              DraggingGroupItem(
                                                b.attachedNumberBlock!,
                                                b
                                                        .attachedNumberBlock!
                                                        .position -
                                                    block.position,
                                              ),
                                            );
                                          }
                                          if (b.attachedDialBlock != null) {
                                            _activeDraggingGroup.add(
                                              DraggingGroupItem(
                                                b.attachedDialBlock!,
                                                b.attachedDialBlock!.position -
                                                    block.position,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    });
                                  },
                                  onDragEnd: (details) {
                                    final RenderBox renderBox =
                                        context.findRenderObject() as RenderBox;
                                    setState(() {
                                      final newPos = renderBox.globalToLocal(
                                        details.offset,
                                      );
                                      block.position = newPos;
                                      for (var item in _activeDraggingGroup) {
                                        if (item.block != block) {
                                          item.block.position =
                                              newPos + item.relativeOffset;
                                        }
                                      }
                                      Offset posBeforeSnap = block.position;
                                      _snapBlock(block);
                                      Offset snapDelta =
                                          block.position - posBeforeSnap;
                                      for (var item in _activeDraggingGroup) {
                                        if (item.block != block) {
                                          item.block.position += snapDelta;
                                        }
                                      }
                                      _primaryDraggedBlock = null;
                                      _activeDraggingGroup.clear();
                                    });
                                  },
                                  child: _buildBlockItem(
                                    block.type,
                                    isExecuting,
                                    block,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 700),
            right: widget.play ? 20 : -200,
            top: 40,
            bottom: 40,
            width: 180,
            child: DragTarget<PlacedBlock>(
              onAcceptWithDetails: (details) {
                setState(() {
                  final block = details.data;
                  if (block.parentActionBlock != null) {
                    block.parentActionBlock!.attachedNumberBlock = null;
                  }
                  for (var other in _workspaceBlocks) {
                    if (other.attachedNumberBlock == block) {
                      other.attachedNumberBlock = null;
                    }
                  }
                  _workspaceBlocks.remove(block);
                  _inventoryCounts[block.type.id] =
                      (_inventoryCounts[block.type.id] ?? 0) + 1;

                  for (var item in _activeDraggingGroup) {
                    if (item.block != block) {
                      _workspaceBlocks.remove(item.block);
                      _inventoryCounts[item.block.type.id] =
                          (_inventoryCounts[item.block.type.id] ?? 0) + 1;
                    }
                  }
                  _activeDraggingGroup.clear();
                  _primaryDraggedBlock = null;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(10),
                          children: [
                            ..._actionTypes.map((block) {
                              final count = _inventoryCounts[block.id] ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Opacity(
                                  opacity: count > 0 ? 1.0 : 0.0,
                                  child: IgnorePointer(
                                    ignoring: count <= 0,
                                    child: Draggable<BlockType>(
                                      data: block,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: _buildBlockItem(block, false),
                                      ),
                                      child: _buildBlockItem(block, false),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Wrap(
                                spacing: 7,
                                runSpacing: 3,
                                alignment: WrapAlignment.start,
                                children: _parameterTypes.map((block) {
                                  final count = _inventoryCounts[block.id] ?? 0;
                                  return Opacity(
                                    opacity: count > 0 ? 1.0 : 0.0,
                                    child: IgnorePointer(
                                      ignoring: count <= 0,
                                      child: Draggable<BlockType>(
                                        data: block,
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: _buildBlockItem(block, false),
                                        ),
                                        child: _buildBlockItem(block, false),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                        child: Column(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: "Presets",
                                  pageBuilder: (context, _, __) => Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.7,
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.4,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20.0),
                                            topRight: Radius.circular(20.0),
                                          ),
                                        ),
                                        child: ListView(
                                          children: _presetGroups
                                              .map(
                                                (g) => ExpansionTile(
                                                  title: Text(g.groupName),
                                                  children: g.presets
                                                      .map(
                                                        (p) => ListTile(
                                                          title: Text(p.name),
                                                          onTap: () {
                                                            _applyPreset(p);
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.folder_open,
                                color: Colors.blueGrey,
                              ),
                              label: const Text('프리셋 열기'),
                            ),
                            TextButton.icon(
                              onPressed: widget.onOpenTerminal,
                              icon: const Icon(
                                Icons.terminal,
                                color: Colors.blueGrey,
                              ),
                              label: const Text('터미널 열기'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockItem(
    BlockType block,
    bool isExecuting, [
    PlacedBlock? placedBlock,
  ]) {
    final bool isParam = block.isParamBlock;
    final double width = block.isDialBlock ? 70.0 : (isParam ? 45.0 : 170.0);
    final double height = isParam ? 50.0 : 60.0;

    Color indicatorColor = block.isPlayBlock ? Colors.grey[600]! : Colors.grey;
    if (isExecuting) indicatorColor = Colors.yellow;
    if (block.isPlayBlock &&
        placedBlock != null &&
        _blinkingPlayBlock == placedBlock) {
      indicatorColor = Colors.yellow;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          BlockContainer(
            height: height,
            blockShapePos: BlockShapePos.none,
            backgroundColor: block.color,
            borderColor: Colors.white,
            child: Center(
              child: block.isPlayBlock
                  ? Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            "assets/block_images/vrware_logo.png",
                            width: 60,
                          ),
                          IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? Icons.stop_circle
                                  : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: placedBlock != null
                                ? () {
                                    if (_isPlaying) {
                                      _stopSequence();
                                    } else {
                                      _playSequenceFrom(placedBlock);
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    )
                  : block.isDialBlock
                  ? (placedBlock != null
                        ? DialBlockWidget(
                            placedBlock: placedBlock,
                            onFocusChanged: (hasFocus) {
                              setState(() {
                                _editingBlock = hasFocus ? placedBlock : null;
                              });
                            },
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Text(
                                '01',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ))
                  : isParam
                  ? ((block.isNumberBlock || block.isDirectionBlock)
                        ? Image.asset(
                            block.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Text(
                              block.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Text(
                            block.name,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(
                          block.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          if (block.id == 'CLOSE')
            Positioned(
              left: -2,
              bottom: height - 11,
              child: Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: block.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 4),
                    left: BorderSide(color: Colors.white, width: 4),
                    right: BorderSide(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          if (block.id == 'IF' || block.id == 'REPEAT')
            Positioned(
              left: -2,
              top: height - 3.5,
              child: Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: block.color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 4),
                    left: BorderSide(color: Colors.white, width: 4),
                    right: BorderSide(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          if (!isParam)
            Positioned(
              left: 10,
              top: 30,
              child: Container(
                width: 10,
                height: 7,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          if (!isParam &&
              !block.isPlayBlock &&
              block.id != 'START' &&
              (placedBlock == null || placedBlock.attachedNumberBlock == null))
            Positioned(
              right: 20,
              top: 28,
              child: Container(
                width: 15,
                height: 15,
                color: Colors.black,
                padding: EdgeInsets.all(3),
                child: Row(
                  spacing: 5,
                  children: [
                    Flexible(
                      child: Column(
                        spacing: 5,
                        children: [
                          Flexible(child: Container(color: Colors.white)),
                          Flexible(child: Container(color: Colors.white)),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Column(
                        spacing: 5,
                        children: [
                          Flexible(child: Container(color: Colors.white)),
                          Flexible(child: Container(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
