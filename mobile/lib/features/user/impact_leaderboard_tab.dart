import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class ImpactLeaderboardTab extends ConsumerStatefulWidget {
  const ImpactLeaderboardTab({super.key});

  @override
  ConsumerState<ImpactLeaderboardTab> createState() =>
      _ImpactLeaderboardTabState();
}

class _ImpactLeaderboardTabState extends ConsumerState<ImpactLeaderboardTab> {
  final _authService = AuthService();
  bool _isLoading = false;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final token = ref.read(authTokenProvider);
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final list = await _authService.fetchLeaderboard(token);
      if (mounted) {
        setState(() {
          _leaderboard = list;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
        userDashboardReloadTriggerProvider, (_, __) => _loadLeaderboard());

    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?['userId'];
    final currentName = currentUser?['fullName'] ?? 'You';

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text('Community Recycling Leaderboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
              'Top Eco-Citizens saving plastic from landfills in Bangladesh',
              style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          const SizedBox(height: 16),
          if (_isLoading && _leaderboard.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_leaderboard.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                      'No recycling data yet. Be the first to deposit plastic!'),
                ),
              ),
            )
          else ...[
            ...List.generate(_leaderboard.length, (index) {
              final item = _leaderboard[index];
              final userId = item['userId'];
              final name = item['fullName'] ?? 'Citizen';
              final isMe = (currentUserId != null && userId == currentUserId) ||
                  name.toString().toLowerCase() ==
                      currentName.toString().toLowerCase();

              final displayName = isMe ? '$name (You)' : name;
              final plasticKg = item['totalPlasticKg'] != null
                  ? (item['totalPlasticKg'] as num).toDouble()
                  : 0.0;
              final level = item['loyaltyLevel'] ?? 'Eco Buddy';
              final rank = index + 1;

              return _buildLeaderboardItem(rank, displayName,
                  '${plasticKg.toStringAsFixed(2)} kg', level, isMe, rank == 1);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, String weight,
      String level, bool isMe, bool isTop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isMe ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMe
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: isMe ? AppTheme.subtle.withOpacity(0.5) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTop
              ? AppTheme.accent
              : (isMe ? AppTheme.primary : AppTheme.subtle),
          child: Text(
            '#$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTop
                  ? AppTheme.textDark
                  : (isMe ? Colors.white : AppTheme.primary),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isMe ? AppTheme.primary : AppTheme.textDark,
          ),
        ),
        subtitle: Text('🌿 $level'),
        trailing: Text(
          weight,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary),
        ),
      ),
    );
  }
}
