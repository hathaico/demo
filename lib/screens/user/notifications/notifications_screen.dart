import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/notification_service.dart';
import '../../../services/settings_service.dart';
import '../../../widgets/safe_network_image.dart';

enum _OrderStatusStage {
  awaitingConfirmation,
  processing,
  completed,
  canceled,
  other,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<bool> _notificationsEnabledFuture;
  List<StoreNotification> _currentNotifications = const [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationsEnabledFuture = SettingsService.getNotificationsEnabled();
  }

  Future<void> _markAllAsRead() async {
    final unread = _currentNotifications
        .where((n) => !n.isRead && !n.isSample)
        .toList();
    if (unread.isEmpty) {
      return;
    }

    await NotificationService.markAllAsRead(unread);
    if (mounted) {
      setState(() {
        _unreadCount = 0;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openNotification(StoreNotification notification) async {
    await NotificationService.markNotificationAsRead(notification);
    if (!mounted) {
      return;
    }

    final stage = _stageForNotification(notification);
    final presentation = _presentationFor(notification, stageOverride: stage);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NotificationDetailSheet(
          notification: notification,
          presentation: presentation,
        );
      },
    );
  }

  _OrderStatusStage _stageForNotification(StoreNotification notification) {
    if (notification.category != NotificationCategory.order) {
      return _OrderStatusStage.other;
    }

    final content = '${notification.title} ${notification.body}'
        .toLowerCase()
        .trim();

    if (content.contains('hủy') ||
        content.contains('đã hủy') ||
        content.contains('huỷ')) {
      return _OrderStatusStage.canceled;
    }
    if (content.contains('chờ xác nhận') ||
        content.contains('đang chờ xác nhận') ||
        content.contains('đợi xác nhận')) {
      return _OrderStatusStage.awaitingConfirmation;
    }
    if (content.contains('đã giao') ||
        content.contains('giao thành công') ||
        content.contains('hoàn tất') ||
        content.contains('hoàn thành') ||
        content.contains('đã nhận hàng')) {
      return _OrderStatusStage.completed;
    }
    if (content.contains('đang xử lý') ||
        content.contains('đang được xử lý') ||
        content.contains('đang chuẩn bị') ||
        content.contains('chuẩn bị giao') ||
        content.contains('đang đóng gói') ||
        content.contains('đang giao') ||
        content.contains('đang vận chuyển')) {
      return _OrderStatusStage.processing;
    }

    return _OrderStatusStage.other;
  }

  _NotificationPresentation _presentationFor(
    StoreNotification notification, {
    _OrderStatusStage? stageOverride,
  }) {
    final stage = stageOverride ?? _stageForNotification(notification);
    final category = notification.category;

    if (category == NotificationCategory.order &&
        stage != _OrderStatusStage.other) {
      return _NotificationPresentation(
        icon: stage.icon,
        color: stage.color,
        label: stage.label,
        description: stage.helperText,
        category: category,
      );
    }

    return _NotificationPresentation(
      icon: category.icon,
      color: category.color,
      label: category.label,
      description: category.helperText,
      category: category,
    );
  }

  void _updateUnreadCount(int count) {
    if (_unreadCount == count) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _unreadCount = count;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Đánh dấu đã đọc'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _notificationsEnabledFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notificationsEnabled = snapshot.data ?? true;
          if (!notificationsEnabled) {
            _updateUnreadCount(0);
            return _buildDisabledState(theme);
          }

          return StreamBuilder<List<StoreNotification>>(
            stream: NotificationService.watchNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return _buildLoadingState(theme);
              }

              if (snapshot.hasError) {
                _updateUnreadCount(0);
                return _buildErrorState(snapshot.error);
              }

              final notifications =
                  (snapshot.data ?? const <StoreNotification>[]).toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _currentNotifications = notifications;

              if (notifications.isEmpty) {
                _updateUnreadCount(0);
                return _buildEmptyState(theme);
              }

              final unreadCount = notifications
                  .where((n) => !n.isRead && !n.isSample)
                  .length;
              _updateUnreadCount(unreadCount);

              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final notification = notifications[index];
                          final stage = _stageForNotification(notification);
                          final presentation = _presentationFor(
                            notification,
                            stageOverride: stage,
                          );
                          return _NotificationTile(
                            notification: notification,
                            presentation: presentation,
                            onTap: () => _openNotification(notification),
                          );
                        }, childCount: notifications.length),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có thông báo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Thông báo đơn hàng đang tắt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Bật lại thông báo để không bỏ lỡ các cập nhật quan trọng về tiến trình xử lý đơn hàng.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await SettingsService.setNotificationsEnabled(true);
                if (mounted) {
                  setState(() {
                    _notificationsEnabledFuture =
                        SettingsService.getNotificationsEnabled();
                  });
                }
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Bật thông báo'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      width: 180,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Không tải được thông báo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              error?.toString() ?? 'Vui lòng thử lại sau ít phút.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.presentation,
    required this.onTap,
  });

  final StoreNotification notification;
  final _NotificationPresentation presentation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead && !notification.isSample;
    final accent = presentation.color;
    final iconData = presentation.icon;
    final statusLabel = presentation.label;
    final bool isStockNotification =
        notification.category == NotificationCategory.stock;
    final String? productImage = notification.imageUrl;
    final bool hasProductImage =
        productImage != null && productImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread
                  ? accent.withOpacity(0.35)
                  : theme.dividerColor.withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(
                  icon: iconData,
                  accent: accent,
                  isUnread: isUnread,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isUnread
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      if (!isStockNotification) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(iconData, size: 16, color: accent.darken(0.1)),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: accent.darken(0.1),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _InfoChip(
                            icon: Icons.access_time,
                            label: _formatRelative(notification.createdAt),
                          ),
                          if (!isStockNotification)
                            _InfoChip(
                              icon: iconData,
                              label: statusLabel,
                              background: accent.withOpacity(0.1),
                              foreground: accent.darken(0.1),
                            ),
                          if (notification.orderId != null)
                            _InfoChip(
                              icon: Icons.receipt_long,
                              label: 'Đơn #${notification.orderId}',
                              background: theme.colorScheme.secondaryContainer,
                              foreground:
                                  theme.colorScheme.onSecondaryContainer,
                            ),
                          if (notification.isSample)
                            const _InfoChip(
                              icon: Icons.remove_red_eye_outlined,
                              label: 'Mẫu minh hoạ',
                              background: Color(0xFFE0E0E0),
                              foreground: Colors.black87,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasProductImage) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.15),
                      ),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeNetworkImage(
                      imageUrl: productImage,
                      fit: BoxFit.cover,
                      placeholderText: notification.title,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.accent,
    required this.isUnread,
  });

  final IconData icon;
  final Color accent;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.25), accent.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: accent.darken(0.1), size: 26),
        ),
        if (isUnread)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: foreground ?? theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  foreground?.withOpacity(0.9) ??
                  theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({
    required this.notification,
    required this.presentation,
  });

  final StoreNotification notification;
  final _NotificationPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = presentation.color;
    final iconData = presentation.icon;
    final statusLabel = presentation.label;
    final helper = presentation.description;
    final bool isStockNotification =
        notification.category == NotificationCategory.stock;
    final String? productImage = notification.imageUrl;
    final bool hasProductImage =
        productImage != null && productImage.isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.12),
                      ),
                      child: Icon(
                        iconData,
                        color: accent.darken(0.1),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatFullDate(notification.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (hasProductImage) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.12),
                      ),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: SafeNetworkImage(
                        imageUrl: productImage,
                        fit: BoxFit.cover,
                        placeholderText: notification.title,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Text(
                  notification.body,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                if (!isStockNotification && helper != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(iconData, color: accent.darken(0.1), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent.darken(0.1),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                helper,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    if (!isStockNotification)
                      _InfoChip(
                        icon: iconData,
                        label: statusLabel,
                        background: accent.withOpacity(0.12),
                        foreground: accent.darken(0.1),
                      ),
                    if (notification.orderId != null)
                      _InfoChip(
                        icon: Icons.receipt_long,
                        label: 'Mã đơn: ${notification.orderId}',
                        background: theme.colorScheme.secondaryContainer,
                        foreground: theme.colorScheme.onSecondaryContainer,
                      ),
                    if (notification.productId != null)
                      _InfoChip(
                        icon: Icons.style,
                        label: 'Sản phẩm: ${notification.productId}',
                        background: theme.colorScheme.tertiaryContainer,
                        foreground: theme.colorScheme.onTertiaryContainer,
                      ),
                    if (notification.isSample)
                      const _InfoChip(
                        icon: Icons.remove_red_eye_outlined,
                        label: 'Thông báo minh hoạ',
                        background: Color(0xFFE0E0E0),
                        foreground: Colors.black87,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationPresentation {
  const _NotificationPresentation({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.category,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? description;
  final NotificationCategory category;
}

String _formatRelative(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);
  if (difference.inMinutes < 1) {
    return 'Vừa xong';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  }
  return _formatFullDate(time);
}

String _formatFullDate(DateTime time) {
  final day = time.day.toString().padLeft(2, '0');
  final month = time.month.toString().padLeft(2, '0');
  final year = time.year.toString();
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute $day/$month/$year';
}

extension _OrderStatusStagePresentation on _OrderStatusStage {
  String get label {
    switch (this) {
      case _OrderStatusStage.awaitingConfirmation:
        return 'Chờ xác nhận';
      case _OrderStatusStage.processing:
        return 'Đang xử lý';
      case _OrderStatusStage.completed:
        return 'Hoàn tất';
      case _OrderStatusStage.canceled:
        return 'Đã hủy';
      case _OrderStatusStage.other:
        return 'Thông báo khác';
    }
  }

  String get helperText {
    switch (this) {
      case _OrderStatusStage.awaitingConfirmation:
        return 'Đơn hàng đã được tạo và đang chờ quản trị viên xác nhận.';
      case _OrderStatusStage.processing:
        return 'Đơn hàng đang được chuẩn bị hoặc vận chuyển tới khách hàng.';
      case _OrderStatusStage.completed:
        return 'Đơn hàng đã hoàn tất và bàn giao thành công cho khách hàng.';
      case _OrderStatusStage.canceled:
        return 'Đơn hàng đã được hủy bởi quản trị viên hoặc khách hàng.';
      case _OrderStatusStage.other:
        return 'Thông báo bổ sung liên quan đến đơn hàng của bạn.';
    }
  }

  IconData get icon {
    switch (this) {
      case _OrderStatusStage.awaitingConfirmation:
        return Icons.watch_later_outlined;
      case _OrderStatusStage.processing:
        return Icons.sync_outlined;
      case _OrderStatusStage.completed:
        return Icons.check_circle_outline;
      case _OrderStatusStage.canceled:
        return Icons.cancel_outlined;
      case _OrderStatusStage.other:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (this) {
      case _OrderStatusStage.awaitingConfirmation:
        return Colors.orangeAccent;
      case _OrderStatusStage.processing:
        return Colors.blueAccent;
      case _OrderStatusStage.completed:
        return Colors.teal;
      case _OrderStatusStage.canceled:
        return Colors.redAccent;
      case _OrderStatusStage.other:
        return Colors.grey;
    }
  }
}

extension _NotificationCategoryPresentation on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.order:
        return 'Đơn hàng';
      case NotificationCategory.promotion:
        return 'Khuyến mãi';
      case NotificationCategory.stock:
        return 'Tồn kho';
      case NotificationCategory.support:
        return 'Hỗ trợ';
      case NotificationCategory.system:
        return 'Hệ thống';
    }
  }

  String get helperText {
    switch (this) {
      case NotificationCategory.order:
        return 'Cập nhật liên quan đến đơn hàng của bạn.';
      case NotificationCategory.promotion:
        return 'Thông báo ưu đãi và khuyến mãi đang diễn ra.';
      case NotificationCategory.stock:
        return 'Thông tin tồn kho, bổ sung hoặc hết hàng.';
      case NotificationCategory.support:
        return 'Tin nhắn hỗ trợ và chăm sóc khách hàng.';
      case NotificationCategory.system:
        return 'Thông báo hệ thống và cập nhật dịch vụ.';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.order:
        return Icons.inventory_2_outlined;
      case NotificationCategory.promotion:
        return Icons.local_offer_outlined;
      case NotificationCategory.stock:
        return Icons.storefront_outlined;
      case NotificationCategory.support:
        return Icons.headset_mic_outlined;
      case NotificationCategory.system:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (this) {
      case NotificationCategory.order:
        return Colors.blueAccent;
      case NotificationCategory.promotion:
        return Colors.pinkAccent;
      case NotificationCategory.stock:
        return Colors.deepOrangeAccent;
      case NotificationCategory.support:
        return Colors.teal;
      case NotificationCategory.system:
        return Colors.indigo;
    }
  }
}

extension _ColorBrightness on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
