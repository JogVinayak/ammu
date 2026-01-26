import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

class IntervalPicker extends StatelessWidget {
  final int currentInterval;
  final Function(int) onChanged;

  const IntervalPicker({
    super.key,
    required this.currentInterval,
    required this.onChanged,
  });

  static const List<int> intervals = [2, 3, 5, 10, 15, 30, 45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Reminder Interval'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How often would you like to be reminded?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: intervals.map((interval) => _IntervalOption(
                        interval: interval,
                        isSelected: interval == currentInterval,
                        onTap: () {
                          onChanged(interval);
                          Navigator.pop(context);
                        },
                      )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalOption extends StatelessWidget {
  final int interval;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntervalOption({
    required this.interval,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
      title: Text(
        'Every ${Helpers.formatInterval(interval)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
    );
  }
}

class ActiveHoursPicker extends StatefulWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Function(TimeOfDay start, TimeOfDay end) onChanged;

  const ActiveHoursPicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onChanged,
  });

  @override
  State<ActiveHoursPicker> createState() => _ActiveHoursPickerState();
}

class _ActiveHoursPickerState extends State<ActiveHoursPicker> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.startTime;
    _endTime = widget.endTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Active Hours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Set when you want to receive reminders',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Start time
          _TimeSelector(
            label: 'Start Time',
            time: _startTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (picked != null) {
                setState(() => _startTime = picked);
              }
            },
          ),
          const SizedBox(height: 16),
          // End time
          _TimeSelector(
            label: 'End Time',
            time: _endTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (picked != null) {
                setState(() => _endTime = picked);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onChanged(_startTime, _endTime);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.waterLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Text(
                  Helpers.formatTime(time),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GoalPicker extends StatefulWidget {
  final int currentGoal;
  final Function(int) onChanged;

  const GoalPicker({
    super.key,
    required this.currentGoal,
    required this.onChanged,
  });

  @override
  State<GoalPicker> createState() => _GoalPickerState();
}

class _GoalPickerState extends State<GoalPicker> {
  late double _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.currentGoal.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Daily Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Set your daily water intake goal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            Helpers.formatMl(_goal.round()),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _goal,
            min: 1000,
            max: 5000,
            divisions: 40,
            label: Helpers.formatMl(_goal.round()),
            onChanged: (value) {
              setState(() => _goal = value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1L', style: Theme.of(context).textTheme.bodySmall),
              Text('5L', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onChanged(_goal.round());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
