import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/schedule_color_group.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleColorGroupsScreen extends StatelessWidget {
  const ScheduleColorGroupsScreen({super.key});

  static const String defaultActiveGroupId = 'preset:warm_cool';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleColorGroups),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await context
                  .read<AppSettingsProvider>()
                  .setScheduleActiveColorGroupId(defaultActiveGroupId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
            },
            child: Text(l10n.resetButton),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleColorGroupEditorScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.scheduleColorGroupCreate),
      ),
      body: Consumer<AppSettingsProvider>(
        builder: (context, provider, child) {
          final active = provider.scheduleEffectiveActiveColorGroup;
          final presets = provider.schedulePresetColorGroups;
          final customs = provider.scheduleCustomColorGroups;
          final activeId = provider.scheduleActiveColorGroupId;

          return WebDesktopContent(
            padding: EdgeInsets.zero,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionTitle(title: l10n.scheduleColorGroupPresets),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final group in presets)
                        _ScheduleColorGroupTile(
                          group: group,
                          displayName: _displayNameForGroup(group, l10n),
                          isSelected: activeId == group.id,
                          canEdit: false,
                          onApply: () async {
                            await provider.setScheduleActiveColorGroupId(
                              group.id,
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: l10n.scheduleColorGroupMyGroups),
                const SizedBox(height: 8),
                Card(
                  child: customs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.scheduleColorGroupNoMyGroups,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : Column(
                          children: [
                            for (final group in customs)
                              _ScheduleColorGroupTile(
                                group: group,
                                displayName: group.name,
                                isSelected: activeId == group.id,
                                canEdit: true,
                                onApply: () async {
                                  await provider.setScheduleActiveColorGroupId(
                                    group.id,
                                  );
                                },
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ScheduleColorGroupEditorScreen(
                                            group: group,
                                          ),
                                    ),
                                  );
                                },
                                onDelete: () async {
                                  final ok = await _confirmDelete(
                                    context,
                                    l10n,
                                    group.name,
                                  );
                                  if (ok != true) return;
                                  await provider.deleteScheduleColorGroup(
                                    group.id,
                                  );
                                },
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.applyButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final c in active.incompleteColors.take(8))
                              _ColorDot(color: c),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final c in active.completedColors.take(8))
                              _ColorDot(color: c),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _displayNameForGroup(
    ScheduleColorGroup group,
    AppLocalizations l10n,
  ) {
    switch (group.id) {
      case 'preset:warm_cool':
        return l10n.scheduleColorPresetWarmCool;
      case 'preset:forest_lavender':
        return l10n.scheduleColorPresetForestLavender;
      case 'preset:sunset_ocean':
        return l10n.scheduleColorPresetSunsetOcean;
      case 'preset:grayscale':
        return l10n.scheduleColorPresetGrayscale;
    }
    return group.name;
  }

  static Future<bool?> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    String name,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.scheduleColorGroupDeleteMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

class _ScheduleColorGroupTile extends StatelessWidget {
  final ScheduleColorGroup group;
  final String displayName;
  final bool isSelected;
  final bool canEdit;
  final VoidCallback onApply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ScheduleColorGroupTile({
    required this.group,
    required this.displayName,
    required this.isSelected,
    required this.canEdit,
    required this.onApply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final leading = SizedBox(
      width: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorDot(
            color: group.incompleteColors.isEmpty
                ? Colors.transparent
                : group.incompleteColors.first,
          ),
          const SizedBox(width: 6),
          _ColorDot(
            color: group.completedColors.isEmpty
                ? Colors.transparent
                : group.completedColors.first,
          ),
        ],
      ),
    );

    return ListTile(
      leading: leading,
      title: Text(displayName),
      subtitle: Text(
        '${l10n.incomplete}: ${group.incompleteColorsArgb.length} · ${l10n.completed}: ${group.completedColorsArgb.length}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Icon(Icons.check, color: theme.colorScheme.primary)
          else
            Icon(Icons.circle_outlined, color: theme.colorScheme.outline),
          if (canEdit) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    return;
                  case 'delete':
                    onDelete?.call();
                    return;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(AppLocalizations.of(context)!.edit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(AppLocalizations.of(context)!.delete),
                ),
              ],
            ),
          ],
        ],
      ),
      onTap: onApply,
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class ScheduleColorGroupEditorScreen extends StatefulWidget {
  final ScheduleColorGroup? group;

  const ScheduleColorGroupEditorScreen({super.key, this.group});

  @override
  State<ScheduleColorGroupEditorScreen> createState() =>
      _ScheduleColorGroupEditorScreenState();
}

class _ScheduleColorGroupEditorScreenState
    extends State<ScheduleColorGroupEditorScreen> {
  late final TextEditingController _nameController;
  late List<Color> _incompleteColors;
  late List<Color> _completedColors;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _incompleteColors =
        widget.group?.incompleteColors.toList() ??
        [Colors.orange.shade300, Colors.amber.shade300, Colors.pink.shade200];
    _completedColors =
        widget.group?.completedColors.toList() ??
        [
          Colors.lightBlue.shade300,
          Colors.teal.shade200,
          Colors.indigo.shade200,
        ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.group != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.edit : l10n.scheduleColorGroupCreate),
        centerTitle: true,
        actions: [TextButton(onPressed: _save, child: Text(l10n.save))],
      ),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.scheduleColorGroupName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ColorListEditor(
                  title: l10n.incomplete,
                  colors: _incompleteColors,
                  onAdd: () async {
                    final picked = await _showColorPicker(
                      context,
                      initialColor: _incompleteColors.isEmpty
                          ? AppTheme.primaryColor
                          : _incompleteColors.last,
                    );
                    if (picked == null) return;
                    setState(
                      () => _incompleteColors = [..._incompleteColors, picked],
                    );
                  },
                  onRemoveAt: (i) => setState(() {
                    final next = [..._incompleteColors];
                    next.removeAt(i);
                    _incompleteColors = next;
                  }),
                  onEditAt: (i) async {
                    final picked = await _showColorPicker(
                      context,
                      initialColor: _incompleteColors[i],
                    );
                    if (picked == null) return;
                    setState(() {
                      final next = [..._incompleteColors];
                      next[i] = picked;
                      _incompleteColors = next;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ColorListEditor(
                  title: l10n.completed,
                  colors: _completedColors,
                  onAdd: () async {
                    final picked = await _showColorPicker(
                      context,
                      initialColor: _completedColors.isEmpty
                          ? AppTheme.secondaryColor
                          : _completedColors.last,
                    );
                    if (picked == null) return;
                    setState(
                      () => _completedColors = [..._completedColors, picked],
                    );
                  },
                  onRemoveAt: (i) => setState(() {
                    final next = [..._completedColors];
                    next.removeAt(i);
                    _completedColors = next;
                  }),
                  onEditAt: (i) async {
                    final picked = await _showColorPicker(
                      context,
                      initialColor: _completedColors[i],
                    );
                    if (picked == null) return;
                    setState(() {
                      final next = [..._completedColors];
                      next[i] = picked;
                      _completedColors = next;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_incompleteColors.isEmpty || _completedColors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleColorGroupNeedAtLeastOneColor)),
      );
      return;
    }

    final provider = context.read<AppSettingsProvider>();

    if (widget.group == null) {
      await provider.createScheduleColorGroup(
        name: name,
        incompleteColorsArgb: _incompleteColors
            .map((e) => e.toARGB32())
            .toList(),
        completedColorsArgb: _completedColors.map((e) => e.toARGB32()).toList(),
      );
    } else {
      await provider.updateScheduleColorGroup(
        widget.group!.copyWith(
          name: name,
          incompleteColorsArgb: _incompleteColors
              .map((e) => e.toARGB32())
              .toList(),
          completedColorsArgb: _completedColors
              .map((e) => e.toARGB32())
              .toList(),
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  static Future<Color?> _showColorPicker(
    BuildContext context, {
    required Color initialColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    Color selectedColor = initialColor;

    return showDialog<Color>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.selectColor),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.hue),
                Slider(
                  value: HSLColor.fromColor(selectedColor).hue,
                  min: 0,
                  max: 360,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      final hsl = HSLColor.fromColor(selectedColor);
                      selectedColor = hsl.withHue(value).toColor();
                    });
                  },
                ),
                Text(l10n.saturation),
                Slider(
                  value: HSLColor.fromColor(selectedColor).saturation,
                  min: 0,
                  max: 1,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      final hsl = HSLColor.fromColor(selectedColor);
                      selectedColor = hsl.withSaturation(value).toColor();
                    });
                  },
                ),
                Text(l10n.lightness),
                Slider(
                  value: HSLColor.fromColor(selectedColor).lightness,
                  min: 0,
                  max: 1,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      final hsl = HSLColor.fromColor(selectedColor);
                      selectedColor = hsl.withLightness(value).toColor();
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedColor),
              child: Text(l10n.ok),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorListEditor extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;
  final ValueChanged<int> onEditAt;

  const _ColorListEditor({
    required this.title,
    required this.colors,
    required this.onAdd,
    required this.onRemoveAt,
    required this.onEditAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.scheduleColorGroupAddColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < colors.length; i++)
              _EditableColorChip(
                color: colors[i],
                onTap: () => onEditAt(i),
                onDelete: () => onRemoveAt(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _EditableColorChip extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EditableColorChip({
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(
              Icons.close,
              color:
                  ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
