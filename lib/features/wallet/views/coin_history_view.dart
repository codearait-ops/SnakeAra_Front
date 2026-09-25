import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_models.dart';

/// Screen displaying the player's coin balance and transaction history.
class CoinHistoryView extends StatefulWidget {
  const CoinHistoryView({super.key});

  @override
  State<CoinHistoryView> createState() => _CoinHistoryViewState();
}

class _CoinHistoryViewState extends State<CoinHistoryView> {
  late final WalletController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WalletController>();
    // Initial display uses recent_transactions returned by GET /wallet
    _controller.fetchWalletBalance();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      if (_controller.hasMoreTransactions.value &&
          !_controller.isLoadingMore.value) {
        _controller.loadMoreTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: 'wallet_coins_title'.tr,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFFFFD700),
              size: 22,
            ),
            tooltip: 'skin_shop_tooltip'.tr,
            onPressed: () => Get.toNamed('/shop'),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final balance = _controller.balance.value;
          final transactions = _controller.transactions;
          final isLoading = _controller.isLoading.value;

          return Column(
            children: [
              const SizedBox(height: 12),

              // --- Top Balance Summary Card ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF262010), Color(0xFF161B22)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'total_coins_balance'.tr,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFFFFD700),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$balance',
                              style: GoogleFonts.vazirmatn(
                                color: const Color(0xFFFFD700),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/shop'),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: Text(
                        'shop'.tr,
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // --- Direct Rewarded Ad Card for Coins (15 coins / cooldown / max views) ---
              Obx(() {
                final adInfo = _controller.adRewardInfo.value;
                final cooldown = _controller.secondsUntilNextAd.value;
                final canWatch = _controller.canWatchAd;
                final isDailyCapReached =
                    adInfo.viewsToday >= adInfo.maxDailyViews;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: canWatch
                          ? const Color(0xFFFFD700).withValues(alpha: 0.35)
                          : Colors.white10,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: canWatch
                              ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.ondemand_video_rounded,
                          color: canWatch
                              ? const Color(0xFFFFD700)
                              : Colors.white38,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'free_coins_ad_badge'.trParams({
                                    'count': '${adInfo.rewardAmount}',
                                  }),
                                  style: GoogleFonts.vazirmatn(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'views_today_badge'.trParams({
                                      'current': '${adInfo.viewsToday}',
                                      'max': '${adInfo.maxDailyViews}',
                                    }),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDailyCapReached
                                  ? 'daily_ad_limit_reached'.tr
                                  : (cooldown > 0
                                        ? 'ad_cooldown_msg'.tr
                                        : 'watch_ad_reward_prompt'.tr),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: canWatch
                            ? () => _controller.watchAdForCoins(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.08,
                          ),
                          disabledForegroundColor: Colors.white38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isDailyCapReached
                              ? 'daily_mission_completed'.tr
                              : (cooldown > 0
                                    ? '${(cooldown ~/ 60).toString().padLeft(2, '0')}:${(cooldown % 60).toString().padLeft(2, '0')}'
                                    : 'watch_ad_btn'.tr),
                          style: GoogleFonts.vazirmatn(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // --- Transactions Section Header ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'transaction_history'.tr,
                      style: GoogleFonts.vazirmatn(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isLoading)
                      const AppLoadingWidget.small(
                        size: 16,
                        color: Color(0xFFFFD700),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- Transactions List ---
              Expanded(
                child: transactions.isEmpty && !isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white24,
                              size: 54,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'no_transactions_yet'.tr,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _controller.fetchWalletBalance();
                        },
                        color: const Color(0xFFFFD700),
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          itemCount: transactions.length +
                              (_controller.hasMoreTransactions.value ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == transactions.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: _controller.isLoadingMore.value
                                      ? const AppLoadingWidget.small(
                                          size: 20,
                                          color: Color(0xFFFFD700),
                                        )
                                      : TextButton.icon(
                                          onPressed: () => _controller
                                              .loadMoreTransactions(),
                                          icon: const Icon(
                                            Icons.expand_more_rounded,
                                            color: Color(0xFFFFD700),
                                            size: 20,
                                          ),
                                          label: Text(
                                            'load_more_transactions'.tr,
                                            style: GoogleFonts.vazirmatn(
                                              color: const Color(0xFFFFD700),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            }
                            final tx = transactions[index];
                            return _buildTransactionTile(tx);
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTransactionTile(CoinTransactionModel tx) {
    final isCredit = tx.isCredit;
    final color = isCredit ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final icon = tx.typeIcon;

    final hasDetailedDesc = tx.description != null &&
        tx.description!.trim().isNotEmpty &&
        tx.description != tx.displayTitle &&
        tx.description != tx.typeLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.displayTitle,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasDetailedDesc) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.description!,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white60,
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.typeLabel,
                        style: GoogleFonts.vazirmatn(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(tx.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isCredit ? '+' : ''}${tx.amount}',
                style: GoogleFonts.vazirmatn(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFFFD700),
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
