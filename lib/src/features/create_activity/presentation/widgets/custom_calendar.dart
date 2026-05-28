import 'package:intl/intl.dart';
import 'package:area_connect/src/imports/imports.dart';

class CustomCalendarWidget extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const CustomCalendarWidget({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CustomCalendarWidget> createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CustomCalendarWidget> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  int get _daysInMonth {
    return DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
  }

  int get _firstWeekdayOffset {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // 0 index for Sunday, 1 for Monday, etc. DateTime.weekday is 1-7 (Mon-Sun).
    // We want Sun=0, Mon=1, ..., Sat=6
    return firstDay.weekday == 7 ? 0 : firstDay.weekday;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Panel (Gradient)
            Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFC78453), Color(0xFFF37A33)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_selectedDate.day}',
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF382B24),
                          height: 1,
                        ),
                      ).center,
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE').format(_selectedDate).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF382B24),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF382B24).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Right Panel (Calendar Grid)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Month Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Color(0xFFC78453)),
                          onPressed: _previousMonth,
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_focusedMonth),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF382B24),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: Color(0xFFC78453)),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Weekdays Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children:
                          ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                              .map(
                                (day) => SizedBox(
                                  width: 32,
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 12),
                    // Days Grid
                    Column(
                      children: List.generate(6, (rowIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: List.generate(7, (colIndex) {
                              final index = rowIndex * 7 + colIndex;
                              final offset = _firstWeekdayOffset;
                              final day = index - offset + 1;
                              final isCurrentMonth =
                                  day > 0 && day <= _daysInMonth;

                              Widget cellContent = const SizedBox.shrink();

                              if (isCurrentMonth) {
                                final date = DateTime(_focusedMonth.year,
                                    _focusedMonth.month, day);
                                final isSelected =
                                    date.year == _selectedDate.year &&
                                        date.month == _selectedDate.month &&
                                        date.day == _selectedDate.day;

                                cellContent = GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = date;
                                    });
                                    widget.onDateSelected(date);
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFFB3825F)
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$day',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF382B24),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: cellContent,
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
