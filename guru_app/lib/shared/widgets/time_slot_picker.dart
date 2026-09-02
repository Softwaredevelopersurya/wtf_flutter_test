import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/validators.dart';

class TimeSlotPicker extends StatefulWidget {
  final DateTime initialDate;
  final List<CallRequest> existingRequests;
  final ValueChanged<DateTime> onSlotSelected;
  final Color primaryColor;

  const TimeSlotPicker({
    super.key,
    required this.initialDate,
    required this.existingRequests,
    required this.onSlotSelected,
    this.primaryColor = AppColors.guruPrimary,
  });

  @override
  State<TimeSlotPicker> createState() => _TimeSlotPickerState();
}

class _TimeSlotPickerState extends State<TimeSlotPicker> {
  late DateTime _selectedDay;
  DateTime? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _next3Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      today,
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: 2)),
    ];
  }

  List<DateTime> _generateSlotsForDay(DateTime day) {
    final slots = <DateTime>[];
    // Slots from 9:00 AM to 7:00 PM in 30-minute blocks
    for (int hour = 9; hour <= 19; hour++) {
      slots.add(DateTime(day.year, day.month, day.day, hour, 0));
      if (hour < 19) {
        slots.add(DateTime(day.year, day.month, day.day, hour, 30));
      }
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _generateSlotsForDay(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3-Day Selector
        Text('Select Date (Next 3 Days)', style: AppTypography.bodyMediumSemiBold),
        AppSpacing.gapV8,
        Row(
          children: _next3Days.map((day) {
            final isSelected = day.year == _selectedDay.year &&
                day.month == _selectedDay.month &&
                day.day == _selectedDay.day;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                      _selectedSlot = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? widget.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected ? widget.primaryColor : AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(day).toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.gapV4,
                        Text(
                          DateFormat('d MMM').format(day),
                          style: AppTypography.bodyMediumSemiBold.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        AppSpacing.gapV16,

        // 30-min Time Slots
        Text('Available 30-min Blocks', style: AppTypography.bodyMediumSemiBold),
        AppSpacing.gapV8,

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final now = DateTime.now();
            final isPast = slot.isBefore(now);
            final conflictCheck = Validators.checkSlotConflict(
              targetTime: slot,
              existingRequests: widget.existingRequests,
            );
            final isConflict = !conflictCheck.isValid;
            final isUnavailable = isPast || isConflict;
            final isSelected = _selectedSlot == slot;

            Color backgroundColor;
            Color textColor;
            BorderSide borderSide;

            if (isSelected) {
              backgroundColor = widget.primaryColor;
              textColor = Colors.white;
              borderSide = BorderSide(color: widget.primaryColor);
            } else if (isUnavailable) {
              backgroundColor = Colors.grey.shade100;
              textColor = Colors.grey.shade400;
              borderSide = BorderSide(color: Colors.grey.shade200);
            } else {
              backgroundColor = Colors.white;
              textColor = AppColors.textPrimary;
              borderSide = const BorderSide(color: AppColors.borderLight);
            }

            return InkWell(
              onTap: isUnavailable
                  ? null
                  : () {
                      setState(() => _selectedSlot = slot);
                      widget.onSlotSelected(slot);
                    },
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.fromBorderSide(borderSide),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(slot),
                      style: AppTypography.bodySmall.copyWith(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        decoration: isUnavailable ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isConflict) ...[
                      AppSpacing.gapH4,
                      const Icon(Icons.block, size: 10, color: Colors.grey),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
