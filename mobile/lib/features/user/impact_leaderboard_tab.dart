import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class ImpactLeaderboardTab extends ConsumerStatefulWidget {
  const ImpactLeaderboardTab({super.key});

  @override
  ConsumerState<ImpactLeaderboardTab> createState() => _ImpactLeaderboardTabState();
}

class _ImpactLeaderboardTabState extends ConsumerState<ImpactLeaderboardTab> {
  bool _isLoading = false;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      var list = await api.getLeaderboard().catchError((_) => <dynamic>[]);
      if (list.isEmpty) {
        list = await api.getAllUsers().catchError((_) => <dynamic>[]);
      }

      if (mounted) {
        final citizenList = list.where((u) => u['role'] == null || u['role'] == 'USER').toList();
        citizenList.sort((a, b) {
          final tA = (a['totalTokens'] as num?)?.toInt() ?? ((a['tokensEarned'] as num?)?.toInt() ?? 0);
          final tB = (b['totalTokens'] as num?)?.toInt() ?? ((b['tokensEarned'] as num?)?.toInt() ?? 0);
          return tB.compareTo(tA);
        });

        setState(() {
          _users = citizenList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userDashboardReloadTriggerProvider, (_, __) => _fetchLeaderboard());
    final currentPhone = ref.watch(userPhoneProvider) ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Eco Champions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                tooltip: 'Refresh rankings',
                onPressed: _fetchLeaderboard,
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Top Dhaka citizens recycling plastic for a cleaner planet', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                : RefreshIndicator(
                    onRefresh: _fetchLeaderboard,
                    color: AppTheme.primary,
                    child: ListView.separated(
                      itemCount: _users.isNotEmpty ? _users.length : _fallbackLeaderboard.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final u = _users.isNotEmpty ? (_users[index] as Map<String, dynamic>) : _fallbackLeaderboard[index];
                        final name = u['fullName']?.toString() ?? 'Eco Hero';
                        final phone = u['phoneNumber']?.toString() ?? '';
                        final tokens = (u['totalTokens'] as num?)?.toInt() ?? 0;
                        final kg = (tokens / 100.0).toStringAsFixed(1);
                        final level = u['loyaltyLevel']?.toString() ?? 'Eco Citizen';
                        final isCurrentUser = currentPhone.isNotEmpty && phone.contains(currentPhone);

                        final rank = index + 1;
                        String badgeIcon = '#$rank';
                        Color badgeColor = AppTheme.subtle;
                        Color textColor = AppTheme.primary;

                        if (rank == 1) {
                          badgeIcon = '🥇';
                          badgeColor = const Color(0xFFFEF3C7);
                          textColor = const Color(0xFFD97706);
                        } else if (rank == 2) {
                          badgeIcon = '🥈';
                          badgeColor = const Color(0xFFF1F5F9);
                          textColor = const Color(0xFF475569);
                        } else if (rank == 3) {
                          badgeIcon = '🥉';
                          badgeColor = const Color(0xFFFFEDD5);
                          textColor = const Color(0xFFC2410C);
                        }

                        return Card(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: isCurrentUser ? Border.all(color: AppTheme.primary, width: 2) : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(badgeIcon, style: TextStyle(fontWeight: FontWeight.bold, fontSize: rank <= 3 ? 18 : 13, color: textColor)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textDark)),
                                          if (isCurrentUser) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(4)),
                                              child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('$level • $tokens Tokens', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$kg kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                                    const Text('Recycled', style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _fallbackLeaderboard = [
    {'fullName': 'Tania Sultana', 'phoneNumber': '+8801822222222', 'totalTokens': 4850, 'loyaltyLevel': 'Nature Hero'},
    {'fullName': 'Rakibul Islam', 'phoneNumber': '+8801711111111', 'totalTokens': 1450, 'loyaltyLevel': 'Green Friend'},
    {'fullName': 'Mahmud Hasan', 'phoneNumber': '+8801933333334', 'totalTokens': 820, 'loyaltyLevel': 'Eco Buddy'},
    {'fullName': 'Sabbir Ahmed', 'phoneNumber': '+8801644444445', 'totalTokens': 320, 'loyaltyLevel': 'Eco Buddy'},
  ];
}
