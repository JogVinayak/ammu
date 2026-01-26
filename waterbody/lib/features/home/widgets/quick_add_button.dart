import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

class QuickAddButton extends StatelessWidget {
  final int amountMl;
  final VoidCallback onTap;
  final bool isSelected;
  final IconData? icon;

  const QuickAddButton({
    super.key,
    required this.amountMl,
    required this.onTap,
    this.isSelected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.backgroundWhite),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textDark.withValues(alpha: 0.1)
                      : AppColors.waterLight),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.textWhite
                      : (isDark ? AppColors.textDark : AppColors.primary),
                  size: 24,
                ),
                const SizedBox(height: 4),
              ],
              Text(
                '+${Helpers.formatMl(amountMl)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? AppColors.textWhite
                      : (isDark ? AppColors.textDark : AppColors.textPrimary),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAddGrid extends StatelessWidget {
  final List<int> amounts;
  final Function(int) onAmountSelected;
  final VoidCallback onCustomTap;

  const QuickAddGrid({
    super.key,
    this.amounts = const [150, 250, 350, 500],
    required this.onAmountSelected,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Quick Add',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...amounts.map((amount) => QuickAddButton(
                  amountMl: amount,
                  onTap: () => onAmountSelected(amount),
                )),
            _CustomAmountButton(onTap: onCustomTap),
          ],
        ),
      ],
    );
  }
}

class _CustomAmountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CustomAmountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.textDark.withValues(alpha: 0.1)
                  : AppColors.waterLight,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: isDark ? AppColors.textDark : AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Custom',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? AppColors.textDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom amount dialog
class CustomAmountDialog extends StatefulWidget {
  final int initialAmount;
  final Function(int) onConfirm;

  const CustomAmountDialog({
    super.key,
    this.initialAmount = 250,
    required this.onConfirm,
  });

  @override
  State<CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<CustomAmountDialog> {
  late int _amount;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
    _controller.text = _amount.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Add Custom Amount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider
          Text(
            '${Helpers.formatMl(_amount)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _amount.toDouble(),
            min: 50,
            max: 1000,
            divisions: 19,
            label: Helpers.formatMl(_amount),
            onChanged: (value) {
              setState(() {
                _amount = value.round();
                _controller.text = _amount.toString();
              });
            },
          ),
          const SizedBox(height: 16),
          // Text field for manual input
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: 'ml',
              hintText: 'Enter amount',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null && parsed > 0 && parsed <= 2000) {
                setState(() {
                  _amount = parsed;
                });
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
            widget.onConfirm(_amount);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
