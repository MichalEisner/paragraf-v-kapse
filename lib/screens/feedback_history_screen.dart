import 'package:flutter/material.dart';
import '../models/feedback_ticket_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/native_bridge_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_logo_action.dart';

class FeedbackHistoryScreen extends StatelessWidget {
  final AppState appState;

  const FeedbackHistoryScreen({super.key, required this.appState});

  static Route route(AppState appState) {
    return MaterialPageRoute(
      builder: (_) => FeedbackHistoryScreen(appState: appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.isDark = isDark;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final tickets = appState.feedbackTickets;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PARAGRAF V KAPSE',
                  style: AppTypography.labelBadge(color: AppColors.outline),
                ),
                Text(
                  'Historie podnětů',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
              ],
            ),
            actions: const [
              AppLogoAction(),
            ],
          ),
          body: tickets.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return _buildTicketCard(context, ticket);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.feedback_outlined,
                size: 48,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Zatím žádné odeslané podněty',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Pokud narazíte na chybu ve výpočtu nebo máte návrh na vylepšení, můžete podnět odeslat z Nastavení aplikace.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Zpět do nastavení'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, FeedbackTicket ticket) {
    final statusColor = ticket.statusColor;

    return Card(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.hairlineBorder),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FeedbackDetailScreen(
                appState: appState,
                ticketId: ticket.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${ticket.id}',
                          style: AppTypography.labelLaw(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticket.category,
                        style: AppTypography.labelBadge(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ticket.statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          ticket.statusLabel,
                          style: AppTypography.labelBadge(color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                ticket.title,
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),

              // Description snippet
              Text(
                ticket.description,
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer: Date + Messages count + Chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Text(
                        CzechDateFormatter.formatDateTime(ticket.createdAt),
                        style: AppTypography.bodySm(color: AppColors.outline).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${ticket.messages.length} ${ticket.messages.length == 1 ? "zpráva" : (ticket.messages.length < 5 ? "zprávy" : "zpráv")}',
                              style: AppTypography.labelBadge(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedbackDetailScreen extends StatefulWidget {
  final AppState appState;
  final String ticketId;

  const FeedbackDetailScreen({
    super.key,
    required this.appState,
    required this.ticketId,
  });

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOnline = true;
  bool _isCheckingConnectivity = false;
  bool _simulatedOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isCheckingConnectivity = true);
    final connected = await NativeBridgeService.isInternetConnected();
    if (mounted) {
      setState(() {
        _isOnline = _simulatedOffline ? false : connected;
        _isCheckingConnectivity = false;
      });
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply([FeedbackTicket? ticket]) async {
    if (ticket != null && (ticket.status == TicketStatus.resolved || ticket.status == TicketStatus.closed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          content: const Text('Podnět byl již vyřešen. Do vyřešeného podnětu nelze psát.'),
        ),
      );
      return;
    }

    if (!_simulatedOffline) {
      final connected = await NativeBridgeService.isInternetConnected();
      if (!connected && mounted) {
        setState(() => _isOnline = false);
      }
    }

    if (!_isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Bez připojení k internetu nelze odeslat zprávu.')),
            ],
          ),
        ),
      );
      return;
    }

    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    widget.appState.addMessageToTicket(widget.ticketId, text);
    _replyController.clear();
    // Scroll down
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _simulateAdminResponse(FeedbackTicket ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulace zprávy administrátora',
                style: AppTypography.headlineSm(color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                'Připraveno pro budoucí propojení s administrátorským panelem. Vyberte ukázkovou reakci podpory:',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_top, color: AppColors.warning, size: 20),
                ),
                title: const Text('Označit: V řešení'),
                subtitle: const Text('Admin odpoví: „Prověřujeme chybu výpočtu u DPP.“'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.appState.updateTicketStatus(ticket.id, TicketStatus.inProgress);
                  widget.appState.addMessageToTicket(
                    ticket.id,
                    'Dobrý den, děkujeme za nahlášení. Váš podnět jsme předali vývojovému týmu k prověření a právě na něm pracujeme.',
                    isAdmin: true,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                ),
                title: const Text('Označit: Vyřešeno'),
                subtitle: const Text('Admin odpoví: „Opraveno v aktualizaci.“'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.appState.updateTicketStatus(ticket.id, TicketStatus.resolved);
                  widget.appState.addMessageToTicket(
                    ticket.id,
                    'Zdravíme vás, podnět byl úspěšně vyřešen a oprava bude součástí nejbližší aktualizace aplikace. Děkujeme za pomoc!',
                    isAdmin: true,
                  );
                },
              ),
              if (ticket.status == TicketStatus.resolved || ticket.status == TicketStatus.closed)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.replay, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Znovu otevřít podnět'),
                  subtitle: const Text('Vrátí stav na „V řešení“ a odemkne psaní zpráv.'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.appState.updateTicketStatus(ticket.id, TicketStatus.inProgress);
                    widget.appState.addMessageToTicket(
                      ticket.id,
                      'Podnět byl administrátorem znovu otevřen.',
                      isAdmin: true,
                    );
                  },
                ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_isOnline ? AppColors.error : AppColors.secondary).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isOnline ? Icons.wifi_off : Icons.wifi,
                    color: _isOnline ? AppColors.error : AppColors.secondary,
                    size: 20,
                  ),
                ),
                title: Text(_isOnline ? 'Test: Přepnout do režimu Offline' : 'Test: Obnovit režim Online'),
                subtitle: Text(_isOnline
                    ? 'Nasimuluje stav bez internetu a uzamkne chat.'
                    : 'Znovu zapne internet a odemkne odesílání zpráv.'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _simulatedOffline = !_simulatedOffline;
                    NativeBridgeService.simulatedOnline = _simulatedOffline ? false : null;
                    if (_simulatedOffline) {
                      _isOnline = false;
                    } else {
                      _checkConnectivity();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.isDark = isDark;

    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final tickets = widget.appState.feedbackTickets;
        final ticket = tickets.firstWhere(
          (t) => t.id == widget.ticketId,
          orElse: () => FeedbackTicket(
            id: widget.ticketId,
            title: 'Neznámý podnět',
            category: 'Podnět',
            description: '',
            createdAt: DateTime.now(),
          ),
        );

        final statusColor = ticket.statusColor;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(
              'Podnět #${ticket.id}',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            actions: [
              if (!_isOnline)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: AppTypography.labelBadge(color: AppColors.error)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                tooltip: 'Simulovat odpověď admina / test',
                onPressed: () => _simulateAdminResponse(ticket),
              ),
              const AppLogoAction(),
            ],
          ),
          body: Column(
            children: [
              // Ticket Overview Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border(bottom: BorderSide(color: AppColors.hairlineBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket.category,
                            style: AppTypography.labelBadge(color: AppColors.primary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(ticket.statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                ticket.statusLabel,
                                style: AppTypography.labelBadge(color: statusColor)
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.title,
                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.description,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),

                    // Status progress bar
                    _buildStatusProgressBar(ticket.status),
                  ],
                ),
              ),

              // Conversation Thread
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Podnět vytvořen ${CzechDateFormatter.formatDateTime(ticket.createdAt)}',
                          style: AppTypography.labelBadge(color: AppColors.outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Initial ticket description as first user message
                    _buildMessageBubble(
                      sender: 'user',
                      senderName: 'Vy (autor)',
                      text: ticket.description,
                      timestamp: ticket.createdAt,
                      isInitial: true,
                    ),

                    // Follow-up messages
                    ...ticket.messages.map((m) {
                      return _buildMessageBubble(
                        sender: m.sender,
                        senderName: m.isFromAdmin ? 'Podpora Paragraf v kapse' : 'Vy',
                        text: m.text,
                        timestamp: m.timestamp,
                        isInitial: false,
                      );
                    }),
                  ],
                ),
              ),

              // Bottom Input Bar OR Resolved Notice
              if (ticket.status == TicketStatus.resolved || ticket.status == TicketStatus.closed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(top: BorderSide(color: AppColors.hairlineBorder)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_circle, size: 20, color: AppColors.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Podnět byl vyřešen',
                                  style: AppTypography.labelLaw(color: AppColors.secondary)
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Historie konverzace zůstává uložena pro vaši kontrolu. Další zprávy do tohoto chatu již nelze odesílat.',
                                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Offline Warning Banner
                if (!_isOnline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.error),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zařízení není připojeno k internetu',
                                style: AppTypography.labelLaw(color: AppColors.onErrorContainer)
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Zprávy s administrátorem vyžadují internetové připojení. Jakmile se telefon připojí, chat bude opět aktivní.',
                                style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Zkontrolovat připojení',
                          icon: _isCheckingConnectivity
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          onPressed: _isCheckingConnectivity ? null : _checkConnectivity,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bottom Input Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(top: BorderSide(color: AppColors.hairlineBorder)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            enabled: _isOnline,
                            style: AppTypography.bodyMd(color: _isOnline ? AppColors.onSurface : AppColors.outline),
                            decoration: InputDecoration(
                              hintText: _isOnline
                                  ? 'Napsat zprávu pro administrátora...'
                                  : 'Zprávy nelze odesílat bez připojení k internetu',
                              hintStyle: AppTypography.bodySm(color: AppColors.outline),
                              fillColor: _isOnline ? AppColors.surfaceContainerLow : AppColors.surfaceContainerLowest,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: AppColors.hairlineBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: AppColors.hairlineBorder),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: AppColors.hairlineBorder.withValues(alpha: 0.5)),
                              ),
                            ),
                            onSubmitted: _isOnline ? (_) => _sendReply(ticket) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isOnline ? () => _sendReply(ticket) : null,
                          icon: Icon(_isOnline ? Icons.send : Icons.cloud_off, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: _isOnline ? AppColors.primaryContainer : AppColors.outlineVariant,
                            foregroundColor: _isOnline ? Colors.white : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusProgressBar(TicketStatus status) {
    int currentStep = 0;
    if (status == TicketStatus.submitted) currentStep = 0;
    if (status == TicketStatus.inProgress) currentStep = 1;
    if (status == TicketStatus.resolved || status == TicketStatus.closed) currentStep = 2;

    final steps = ['Předáno', 'V řešení', 'Vyřešeno'];

    return Row(
      children: List.generate(steps.length, (idx) {
        final isCompleted = idx <= currentStep;
        final isCurrent = idx == currentStep;
        Color stepColor = isCompleted
            ? (idx == 2 ? AppColors.secondary : (idx == 1 ? AppColors.warning : AppColors.primary))
            : AppColors.outlineVariant;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isCompleted ? stepColor : AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: stepColor, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                steps[idx],
                style: AppTypography.labelBadge(
                  color: isCurrent ? AppColors.onSurface : AppColors.outline,
                ).copyWith(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
              ),
              if (idx < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: idx < currentStep ? stepColor : AppColors.hairlineBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMessageBubble({
    required String sender,
    required String senderName,
    required String text,
    required DateTime timestamp,
    required bool isInitial,
  }) {
    final isUser = sender == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Icon(Icons.support_agent, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                ],
                Text(
                  senderName,
                  style: AppTypography.labelBadge(
                    color: isUser ? AppColors.primary : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  CzechDateFormatter.formatDateTime(timestamp),
                  style: AppTypography.labelBadge(color: AppColors.outline).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 14),
              ),
              border: isUser ? null : Border.all(color: AppColors.hairlineBorder),
            ),
            child: Text(
              text,
              style: AppTypography.bodySm(
                color: isUser ? Colors.white : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
