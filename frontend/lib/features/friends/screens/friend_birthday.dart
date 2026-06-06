import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:frontend/config/app_colors.dart';
import '../providers/friend_provider.dart';

class BirthdayModel {
  final String id;
  final String name;
  final DateTime date;
  final String avatarUrl;

  BirthdayModel({
    required this.id,
    required this.name,
    required this.date,
    this.avatarUrl = '',
  });
}

class FriendBirthdayScreen extends StatefulWidget {
  const FriendBirthdayScreen({super.key});

  @override
  State<FriendBirthdayScreen> createState() => _FriendBirthdayScreenState();
}

class _FriendBirthdayScreenState extends State<FriendBirthdayScreen> {
  bool isCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<BirthdayModel> allBirthdays = [];

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  List<Widget> _flatListItems = [];
  final Map<String, int> _monthToIdxMap = {};

  bool _hasScrolledToCurrent = false;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);

    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;

    _itemPositionsListener.itemPositions.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FriendProvider>();
      if (provider.friends.isEmpty) {
        await provider.loadFriends();
      }
      await provider.loadFriendBirthdays();
    });
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (!isCalendarView || _isProgrammaticScroll || _flatListItems.isEmpty) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final topItem = positions.reduce((min, item) => item.index < min.index ? item : min);

    String? targetMonthKey;
    _monthToIdxMap.forEach((key, idx) {
      if (idx <= topItem.index) {
        targetMonthKey = key;
      }
    });

    if (targetMonthKey != null) {
      final parts = targetMonthKey!.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      if (_focusedDay.year != year || _focusedDay.month != month) {
        setState(() {
          _focusedDay = DateTime(year, month, _focusedDay.day);
        });
      }
    }
  }

  void _scrollToMonth(DateTime date) {
    final monthKeyStr = '${date.year}-${date.month}';
    final targetIdx = _monthToIdxMap[monthKeyStr];

    if (targetIdx != null && _itemScrollController.isAttached) {
      setState(() {
        _isProgrammaticScroll = true;
      });

      _itemScrollController.scrollTo(
        index: targetIdx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      ).then((_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) setState(() => _isProgrammaticScroll = false);
        });
      });
    }
  }

  void _processBirthdayData(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    final friends = provider.friends;
    final currentYear = DateTime.now().year;

    List<BirthdayModel> tempAll = [];

    for (var friend in friends) {
      final dobString = provider.friendBirthdays[friend.friendId];
      if (dobString == null || dobString.isEmpty) continue;

      final dob = DateTime.tryParse(dobString);
      if (dob == null) continue;

      tempAll.add(BirthdayModel(
        id: '${friend.friendId}_$currentYear',
        name: friend.fullName,
        date: DateTime(currentYear, dob.month, dob.day),
        avatarUrl: friend.avatar,
      ));

      tempAll.add(BirthdayModel(
        id: '${friend.friendId}_${currentYear + 1}',
        name: friend.fullName,
        date: DateTime(currentYear + 1, dob.month, dob.day),
        avatarUrl: friend.avatar,
      ));
    }

    tempAll.sort((a, b) => a.date.compareTo(b.date));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && allBirthdays.length != tempAll.length) {
        setState(() {
          allBirthdays = tempAll;
          _buildFlatListStructure();
        });
      }
    });
  }

  void _buildFlatListStructure() {
    List<Widget> items = [];
    _monthToIdxMap.clear();
    final int currentYear = DateTime.now().year;
    final DateTime today = DateTime.now();

    for (int year = currentYear; year <= currentYear + 1; year++) {
      for (int month = 1; month <= 12; month++) {
        final String monthKeyStr = '$year-$month';

        _monthToIdxMap[monthKeyStr] = items.length;

        items.add(_buildMonthBanner(month, year));

        final monthsBirthdays = allBirthdays.where((b) => b.date.month == month && b.date.year == year).toList();

        if (monthsBirthdays.isEmpty) {
          items.add(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Center(
                child: Text(
                  'Không có sinh nhật nào trong tháng này',
                  style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          );
        } else {
          final List<int> sortedDays = monthsBirthdays.map((b) => b.date.day).toSet().toList()..sort();

          for (int day in sortedDays) {
            final DateTime currentLoopDate = DateTime(year, month, day);
            final bool isToday = isSameDay(currentLoopDate, today);
            final dayBirthdays = monthsBirthdays.where((b) => b.date.day == day).toList();

            items.add(
              Container(
                width: double.infinity,
                color: isToday ? const Color(0xFFE5F0FF) : const Color(0xFFF5F5F5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(top: 4),
                child: Text(
                  isToday
                      ? 'Hôm nay • ${DateFormat('EEEE, d MMMM', 'vi_VN').format(currentLoopDate)}'
                      : DateFormat('EEEE, d MMMM', 'vi_VN').format(currentLoopDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isToday ? const Color(0xFF005bb5) : Colors.grey.shade700,
                  ),
                ),
              ),
            );

            items.addAll(dayBirthdays.map((b) => _buildBirthdayItem(b, showPrefixName: true)));
          }
        }
      }
    }
    _flatListItems = items;
  }

  bool _hasBirthday(DateTime date) {
    return allBirthdays.any((b) => b.date.month == date.month && b.date.day == date.day);
  }

  @override
  Widget build(BuildContext context) {
    _processBirthdayData(context);

    if (_flatListItems.isNotEmpty && !_hasScrolledToCurrent && isCalendarView) {
      _hasScrolledToCurrent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMonth(DateTime.now());
      });
    }

    final provider = context.watch<FriendProvider>();
    final isLoading = provider.friendsState == LoadingState.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : (isCalendarView ? _buildCalendarView() : _buildListView()),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isCalendarView && !isLoading
          ? Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                elevation: 2,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                onPressed: () {
                  final now = DateTime.now();
                  setState(() {
                    _focusedDay = now;
                    _selectedDay = now;
                  });
                  _scrollToMonth(now);
                },
                label: const Text(
                  'Hôm nay',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (isCalendarView) {
      String monthYear = 'Tháng ${_focusedDay.month}, ${_focusedDay.year}';
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => setState(() {
            isCalendarView = false;
            _hasScrolledToCurrent = false;
          }),
        ),
        title: Text(monthYear, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500)),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
            onPressed: () {
              final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
              if (prevMonth.year >= DateTime.now().year) {
                setState(() {
                  _focusedDay = prevMonth;
                  _selectedDay = prevMonth;
                });
                _scrollToMonth(prevMonth);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black, size: 28),
            onPressed: () {
              final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              if (nextMonth.year <= DateTime.now().year + 1) {
                setState(() {
                  _focusedDay = nextMonth;
                  _selectedDay = nextMonth;
                });
                _scrollToMonth(nextMonth);
              }
            },
          ),
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black), onPressed: () {}),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: false,
      title: const Text('Sinh nhật', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500)),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined, color: Colors.black),
          onPressed: () => setState(() => isCalendarView = true),
        ),
        IconButton(icon: const Icon(Icons.history, color: Colors.black), onPressed: () {}),
        IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black), onPressed: () {}),
      ],
    );
  }

  Widget _buildListView() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int currentYear = now.year;

    final pastBirthdays = allBirthdays.where((b) => b.date.year == currentYear && b.date.isBefore(today)).toList();
    final upcomingBirthdays = allBirthdays.where((b) => b.date.year == currentYear && !b.date.isBefore(today)).toList();

    if (allBirthdays.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu sinh nhật bạn bè', style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (pastBirthdays.isNotEmpty) ...[
          _buildSectionTitle('Sinh nhật đã qua'),
          ...pastBirthdays.map((b) => _buildBirthdayItem(b, showPrefixName: false)),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        ],
        if (upcomingBirthdays.isNotEmpty) ...[
          _buildSectionTitle('Sinh nhật sắp tới'),
          ...upcomingBirthdays.map((b) => _buildBirthdayItem(b, showPrefixName: false)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildCalendarView() {
    final currentYear = DateTime.now().year;

    return Column(
      children: [
        TableCalendar(
          locale: 'vi_VN',
          firstDay: DateTime.utc(currentYear, 1, 1),
          lastDay: DateTime.utc(currentYear + 1, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _scrollToMonth(selectedDay);
          },
          onPageChanged: (focusedDay) {
            if (!_isProgrammaticScroll) {
              setState(() {
                _focusedDay = focusedDay;
                _selectedDay = focusedDay;
              });
              _scrollToMonth(focusedDay);
            }
          },
          headerVisible: false,
          daysOfWeekHeight: 30,
          startingDayOfWeek: StartingDayOfWeek.monday,
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
            weekendStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: const BoxDecoration(),
            todayTextStyle: const TextStyle(color: Colors.black),
            selectedDecoration: BoxDecoration(
              color: const Color(0xFFE5F0FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0091FF), width: 1.5),
            ),
            selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (_hasBirthday(date)) {
                return Positioned(
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A93),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.cake, size: 10, color: Colors.white),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        Expanded(
          child: _flatListItems.isEmpty
              ? const SizedBox()
              : ScrollablePositionedList.builder(
                  itemCount: _flatListItems.length,
                  itemBuilder: (context, index) => _flatListItems[index],
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 60),
                ),
        ),
      ],
    );
  }

  Widget _buildMonthBanner(int month, int year) {
    String imageUrl;
    switch (month) {
      case 1: imageUrl = 'https://images.unsplash.com/photo-1483921020237-2ff51e8e4b22?q=80&w=600&auto=format&fit=crop'; break;
      case 2: imageUrl = 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?q=80&w=600&auto=format&fit=crop'; break;
      case 3: imageUrl = 'https://images.unsplash.com/photo-1522748906645-95d8adfd52c7?q=80&w=600&auto=format&fit=crop'; break;
      case 4: imageUrl = 'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?q=80&w=600&auto=format&fit=crop'; break;
      case 5: imageUrl = 'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?q=80&w=600&auto=format&fit=crop'; break;
      case 6: imageUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop'; break;
      case 7: imageUrl = 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=600&auto=format&fit=crop'; break;
      case 8: imageUrl = 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=600&auto=format&fit=crop'; break;
      case 9: imageUrl = 'https://images.unsplash.com/photo-1477414348463-c0eb7f1359b6?q=80&w=600&auto=format&fit=crop'; break;
      case 10: imageUrl = 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=600&auto=format&fit=crop'; break;
      case 11: imageUrl = 'https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?q=80&w=600&auto=format&fit=crop'; break;
      case 12:
      default: imageUrl = 'https://images.unsplash.com/photo-1491002052546-bf38f186af56?q=80&w=600&auto=format&fit=crop'; break;
    }

    return Container(
      height: 110,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 15),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.35), BlendMode.darken),
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Text(
        'Tháng $month, $year',
        style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2,
          shadows: [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4)],
        ),
      ),
    );
  }

  Widget _buildBirthdayItem(BirthdayModel user, {bool showPrefixName = false}) {
    String dateStr = DateFormat('EEEE, d MMMM', 'vi_VN').format(user.date);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            child: user.avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          Positioned(
            bottom: -2, right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A93),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.cake, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
      title: Text(
        showPrefixName ? 'Sinh nhật ${user.name}' : user.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        maxLines: 1, overflow: TextOverflow.ellipsis,
      ),
      subtitle: !showPrefixName ? Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFFE5F0FF), shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0091FF), size: 20),
      ),
    );
  }
}
