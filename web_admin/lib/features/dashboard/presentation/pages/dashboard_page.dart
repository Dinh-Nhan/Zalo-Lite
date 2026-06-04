import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/router/router.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../../feeds/presentation/providers/feed_provider.dart';
import '../providers/dashboard_provider.dart';

// ============================================================
// DASHBOARD PAGE
// ============================================================

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _StatsGrid(),
          const SizedBox(height: 24),
          _ChartsRow(),
          const SizedBox(height: 24),
          _buildContentRow(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: AppTextStyles.displayMedium),
            Text(
              'Welcome back, Admin · ${now.formatted}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildContentRow(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 900;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _NewUsersCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _RecentFeedsCard()),
          ],
        );
      }
      return Column(
        children: [
          _NewUsersCard(),
          const SizedBox(height: 16),
          _RecentFeedsCard(),
        ],
      );
    });
  }
}

// ─── Stats Grid ──────────────────────────────────────────────

class _StatsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = constraints.maxWidth > 900
          ? 4
          : constraints.maxWidth > 600
              ? 2
              : 1;

      return statsAsync.when(
        loading: () => GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0,
          children: List.generate(
              4,
              (_) => const StatCard(
                    title: '',
                    value: '',
                    icon: Icons.people,
                    gradient: AppColors.primaryGradient,
                    isLoading: true,
                  )),
        ),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (stats) => GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0,
          children: [
            StatCard(
              title: 'Total Users',
              value: stats.totalUsers.compact,
              icon: Icons.people_rounded,
              gradient: AppColors.primaryGradient,
              subtitle: 'Registered accounts',
            ),
            StatCard(
              title: 'Total Posts',
              value: stats.totalPosts.compact,
              icon: Icons.article_rounded,
              gradient: AppColors.infoGradient,
              subtitle: 'Published posts',
            ),
            StatCard(
              title: 'Friendships',
              value: stats.totalFriendships.compact,
              icon: Icons.group_rounded,
              gradient: AppColors.successGradient,
              subtitle: '${stats.totalAccepted.compact} accepted',
            ),
            StatCard(
              title: 'Acceptance Rate',
              value: stats.totalFriendships > 0
                  ? '${((stats.totalAccepted / stats.totalFriendships) * 100).toStringAsFixed(0)}%'
                  : '—',
              icon: Icons.handshake_rounded,
              gradient: AppColors.warningGradient,
              subtitle: 'Friend request success',
            ),
          ],
        ),
      );
    });
  }
}

// ─── Charts Row ───────────────────────────────────────────────

class _ChartsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 900;
      final charts = [
        Expanded(child: _UserGrowthChart()),
        if (isWide) const SizedBox(width: 16),
        Expanded(
          child: statsAsync.when(
            data: (stats) => _FriendshipPieChart(stats: stats),
            loading: () => SectionCard(
                child: const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppLoadingWidget())),
            error: (e, _) => SectionCard(
                child: AppErrorWidget(message: e.toString())),
          ),
        ),
      ];

      return isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: charts,
            )
          : Column(
              children: [
                _UserGrowthChart(),
                const SizedBox(height: 16),
                statsAsync.when(
                  data: (stats) => _FriendshipPieChart(stats: stats),
                  loading: () => SectionCard(
                      child: const Padding(
                          padding: EdgeInsets.all(60),
                          child: AppLoadingWidget())),
                  error: (e, _) =>
                      SectionCard(child: AppErrorWidget(message: e.toString())),
                ),
              ],
            );
    });
  }
}

// ─── User Growth Line Chart ───────────────────────────────────

class _UserGrowthChart extends StatelessWidget {
  // Simulated weekly data (replace with real Firestore aggregation)
  final List<double> _weeklyUsers = const [12, 28, 18, 45, 33, 60, 52];
  final List<String> _days = const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'User Registrations (This Week)',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 24, 20),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.border.withOpacity(0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 20,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= _days.length) return const SizedBox();
                      return Text(_days[i], style: AppTextStyles.caption);
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _weeklyUsers
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: AppColors.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.25),
                        AppColors.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
              minY: 0,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Friendship Pie Chart ─────────────────────────────────────

class _FriendshipPieChart extends StatefulWidget {
  final DashboardStats stats;
  const _FriendshipPieChart({required this.stats});

  @override
  State<_FriendshipPieChart> createState() => _FriendshipPieChartState();
}

class _FriendshipPieChartState extends State<_FriendshipPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final accepted = widget.stats.totalAccepted.toDouble();
    final pending = ((widget.stats.totalFriendships - widget.stats.totalAccepted)
        .toDouble()
        .clamp(0.0, double.infinity)) as double;

    return SectionCard(
      title: 'Friendship Status',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse?.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse!
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.success,
                        value: accepted == 0 ? 0.01 : accepted,
                        title: '${accepted.toInt()}',
                        radius: _touchedIndex == 0 ? 56 : 48,
                        titleStyle: AppTextStyles.caption
                            .copyWith(color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: AppColors.warning,
                        value: pending == 0 ? 0.01 : pending,
                        title: '${pending.toInt()}',
                        radius: _touchedIndex == 1 ? 56 : 48,
                        titleStyle: AppTextStyles.caption
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Legend(color: AppColors.success, label: 'Accepted'),
                  const SizedBox(height: 8),
                  _Legend(color: AppColors.warning, label: 'Pending'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

// ─── New Users Card ──────────────────────────────────────────

class _NewUsersCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(newUsersStreamProvider);

    return SectionCard(
      title: 'New Users (Last 7 Days)',
      trailing: TextButton(
        onPressed: () => context.go(AppRoutes.users),
        child: const Text('View all'),
      ),
      child: usersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: AppLoadingWidget(),
        ),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (users) {
          if (users.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: AppEmptyWidget(
                title: 'No new users',
                subtitle: 'No users registered in the last 7 days',
                icon: Icons.person_outline,
              ),
            );
          }
          return Column(
            children: users
                .map((user) => _UserListTile(user: user))
                .toList(),
          );
        },
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final dynamic user;
  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/users/${user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage:
                  user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
              child: user.avatar.isEmpty
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(user.email,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge.fromString(user.isActive ? 'active' : 'banned'),
                const SizedBox(height: 4),
                Text(
                  DateTimeX(user.createdAt as DateTime).timeAgo,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Feeds Card ───────────────────────────────────────

class _RecentFeedsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedsAsync = ref.watch(recentFeedsStreamProvider);

    return SectionCard(
      title: 'Recent Posts',
      trailing: TextButton(
        onPressed: () => context.go(AppRoutes.feeds),
        child: const Text('View all'),
      ),
      child: feedsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: AppLoadingWidget(),
        ),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (feeds) {
          if (feeds.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: AppEmptyWidget(
                title: 'No posts yet',
                subtitle: 'Recent posts will appear here',
                icon: Icons.article_outlined,
              ),
            );
          }
          return Column(
            children: feeds
                .map((feed) => _FeedListTile(feed: feed))
                .toList(),
          );
        },
      ),
    );
  }
}

class _FeedListTile extends StatelessWidget {
  final dynamic feed;
  const _FeedListTile({required this.feed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/feeds/${feed.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                feed.type == 'story'
                    ? Icons.auto_stories_rounded
                    : Icons.article_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feed.caption.isNotEmpty ? feed.caption : '(No caption)',
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${feed.likeCount} likes · ${feed.viewCount} views',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text(
              DateTimeX(feed.createdAt as DateTime).timeAgo,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
