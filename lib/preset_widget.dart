import 'package:flutter/material.dart';
import 'blocks_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Preset {
  final String name;
  final List<Map<String, dynamic>> blocks;
  final List<Map<String, dynamic>>? functionBlocks;
  Preset({required this.name, required this.blocks, this.functionBlocks});

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      name: json['name'],
      blocks: List<Map<String, dynamic>>.from(json['blocks']),
      functionBlocks: json['functionBlocks'] != null
          ? List<Map<String, dynamic>>.from(json['functionBlocks'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'blocks': blocks, 'functionBlocks': functionBlocks};
  }
}

class PresetGroup {
  final String groupName;
  final List<Preset> presets;
  PresetGroup({required this.groupName, required this.presets});
}

class PresetWidget extends StatefulWidget {
  final List<PlacedBlock> workspaceBlocks;
  final List<PlacedBlock> savedFunctionBlocks;
  final Map<String, int> inventoryCounts;
  final List<BlockType> actionTypes;
  final List<BlockType> parameterTypes;
  final Function(Map<String, int>, List<PlacedBlock>, List<PlacedBlock>)
  onApplyPreset;

  const PresetWidget({
    super.key,
    required this.workspaceBlocks,
    required this.savedFunctionBlocks,
    required this.inventoryCounts,
    required this.actionTypes,
    required this.parameterTypes,
    required this.onApplyPreset,
  });

  @override
  State<PresetWidget> createState() => PresetWidgetState();
}

class PresetWidgetState extends State<PresetWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _groupExpansionState = {};

  Future<void> _savePreset(String name, PlacedBlock draggedBlock) async {
    List<Map<String, dynamic>> blocksData = [];
    List<Map<String, dynamic>> functionBlocksData = [];
    List<PlacedBlock> sequence = _getDescendants(draggedBlock);
    sequence.insert(0, draggedBlock);
    for (final current in sequence) {
      final data = <String, dynamic>{'id': current.type.id};
      PlacedBlock? param = current.attachedNumberBlock;
      param ??= current.attachedDialBlock;
      if (param == null) {
        param = widget.workspaceBlocks.firstWhere(
          (b) => b.parentActionBlock == current,
          orElse: () => PlacedBlock(
            const BlockType(id: '', name: '', color: Colors.transparent),
            Offset.zero,
          ),
        );
        if (param.type.id.isEmpty) {
          param = null;
        }
      }
      if (param != null) {
        data['param'] = param.type.id;
        if (param.type.isDialBlock) {
          data['dialInput'] = param.dialInput;
          data['isDecimal'] = param.isDecimal;
        }
      }
      blocksData.add(data);
    }
    for (final b in widget.savedFunctionBlocks) {
      final data = <String, dynamic>{'id': b.type.id};
      PlacedBlock? param = b.attachedNumberBlock;
      param ??= b.attachedDialBlock;
      if (param != null) {
        data['param'] = param.type.id;
        if (param.type.isDialBlock) {
          data['dialInput'] = param.dialInput;
          data['isDecimal'] = param.isDecimal;
        }
      }
      functionBlocksData.add(data);
    }
    await _firestore
        .collection('presets')
        .doc(name)
        .set(
          Preset(
            name: name,
            blocks: blocksData,
            functionBlocks: functionBlocksData,
          ).toJson(),
          SetOptions(merge: true),
        );
  }

  Future<void> _deletePreset(String name) async {
    await _firestore.collection('presets').doc(name).delete();
  }

  Future<void> _renamePreset(String oldName, String newName) async {
    DocumentSnapshot doc = await _firestore
        .collection('presets')
        .doc(oldName)
        .get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['name'] = newName;
      await _firestore.collection('presets').doc(newName).set(data);
      await _firestore.collection('presets').doc(oldName).delete();
    }
  }

  void showSavePresetDialog(PlacedBlock block) {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리셋 저장'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _savePreset(value, block);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _showRenamePresetDialog(String oldName) {
    TextEditingController nameController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리셋 이름 변경'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty && value != oldName) {
              _renamePreset(oldName, value);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  List<PlacedBlock> _getDescendants(PlacedBlock root) {
    List<PlacedBlock> descendants = [];
    PlacedBlock current = root;
    while (true) {
      PlacedBlock? child = widget.workspaceBlocks.where((b) {
        if (b.type.isNumberBlock ||
            b.type.isSensorBlock ||
            b.type.isDirectionBlock) {
          return false;
        }
        double expectedX =
            current.position.dx + _getChildXOffset(current.type, b.type);
        double expectedY =
            current.position.dy + _getSpacing(current.type, b.type);
        return (b.position.dx - expectedX).abs() <= 10.0 &&
            (b.position.dy - expectedY).abs() <= 10.0;
      }).firstOrNull;
      if (child == null) break;
      descendants.add(child);
      current = child;
    }
    return descendants;
  }

  double _getChildXOffset(BlockType parent, BlockType child) {
    double offset = 0;
    if (parent.id == 'IF' || parent.id == 'REPEAT') {
      offset += 50;
    }
    if (child.id == 'CLOSE') offset -= 50;
    return offset;
  }

  double _getSpacing(BlockType current, BlockType next) {
    if ((current.id == 'IF' || current.id == 'REPEAT') && next.id == 'CLOSE') {
      return 85.0;
    }
    return 55.0;
  }

  void _applyPreset(Preset preset) {
    Map<String, int> newInventory = Map.from(widget.inventoryCounts);
    List<PlacedBlock> newWorkspace = [];
    List<PlacedBlock> newFunctionBlocks = [];

    for (var p in preset.blocks) {
      final type = widget.actionTypes.firstWhere((t) => t.id == p['id']);
      final actionBlock = PlacedBlock(type, Offset.zero);
      newInventory[type.id] = (newInventory[type.id] ?? 0) - 1;
      if (p.containsKey('param')) {
        final paramType = widget.parameterTypes.firstWhere(
          (t) => t.id == p['param'],
        );
        final paramBlock = PlacedBlock(paramType, Offset.zero);
        newInventory[paramType.id] = (newInventory[paramType.id] ?? 0) - 1;
        if (paramType.isDialBlock) {
          paramBlock.dialInput = p['dialInput'] ?? '01';
          paramBlock.isDecimal = p['isDecimal'] ?? false;
          actionBlock.attachedDialBlock = paramBlock;
        } else {
          actionBlock.attachedNumberBlock = paramBlock;
        }
        paramBlock.parentActionBlock = actionBlock;
      }
      newWorkspace.add(actionBlock);
    }
    if (preset.functionBlocks != null) {
      for (var p in preset.functionBlocks!) {
        final type = widget.actionTypes.firstWhere((t) => t.id == p['id']);
        final actionBlock = PlacedBlock(type, Offset.zero);
        if (p.containsKey('param')) {
          final paramType = widget.parameterTypes.firstWhere(
            (t) => t.id == p['param'],
          );
          final paramBlock = PlacedBlock(paramType, Offset.zero);
          if (paramType.isDialBlock) {
            paramBlock.dialInput = p['dialInput'] ?? '01';
            paramBlock.isDecimal = p['isDecimal'] ?? false;
            actionBlock.attachedDialBlock = paramBlock;
          } else {
            actionBlock.attachedNumberBlock = paramBlock;
          }
          paramBlock.parentActionBlock = actionBlock;
        }
        newFunctionBlocks.add(actionBlock);
      }
    }
    List<PlacedBlock> finalWorkspace = [];
    double currentX = 300;
    double currentY = 200;
    BlockType? prev;
    for (final b in newWorkspace) {
      if (prev != null) {
        currentY += _getSpacing(prev, b.type);
        currentX += _getChildXOffset(prev, b.type);
      }
      b.position = Offset(currentX, currentY);
      finalWorkspace.add(b);
      if (b.attachedNumberBlock != null) {
        b.attachedNumberBlock!.position = Offset(currentX + 120, currentY + 5);
        finalWorkspace.add(b.attachedNumberBlock!);
      }
      if (b.attachedDialBlock != null) {
        b.attachedDialBlock!.position = Offset(currentX + 170, currentY + 5);
        finalWorkspace.add(b.attachedDialBlock!);
      }
      prev = b.type;
    }
    widget.onApplyPreset(newInventory, finalWorkspace, newFunctionBlocks);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Presets",
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                child: Stack(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_copy_outlined),
                          SizedBox(width: 15),
                          Text("프리셋 불러오기", style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 10,
                      ).copyWith(top: 80, left: 25, right: 25),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('presets').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          final Map<String, List<Preset>> groupedPresets = {};

                          for (var doc in docs) {
                            final data = doc.data() as Map<String, dynamic>?;
                            if (data == null) continue;

                            final Preset p = Preset.fromJson(data);
                            final String groupName = p.name.contains('@')
                                ? p.name.split('@')[0]
                                : '기타 그룹';

                            groupedPresets
                                .putIfAbsent(groupName, () => [])
                                .add(p);
                          }

                          if (groupedPresets.isEmpty) {
                            return const Center(child: Text("저장된 프리셋이 없습니다."));
                          }

                          return ListView(
                            children: groupedPresets.entries.map((entry) {
                              final String groupName = entry.key;
                              final List<Preset> presets = entry.value;

                              _groupExpansionState.putIfAbsent(
                                groupName,
                                () => false,
                              );

                              return ExpansionTile(
                                title: Text(
                                  groupName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                initiallyExpanded: false,
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    _groupExpansionState[groupName] = expanded;
                                  });
                                },
                                children: presets.map((p) {
                                  return ListTile(
                                    title: Text(
                                      p.name.contains('@')
                                          ? p.name.split('@')[1]
                                          : p.name,
                                    ),
                                    onTap: () {
                                      _applyPreset(p);
                                      Navigator.pop(context);
                                    },
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _showRenamePresetDialog(p.name),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () =>
                                              _deletePreset(p.name),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
      icon: const Icon(Icons.folder_open, color: Colors.black),
    );
  }
}
