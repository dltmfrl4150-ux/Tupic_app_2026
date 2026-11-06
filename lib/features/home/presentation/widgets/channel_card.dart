import 'package:flutter/material.dart';

import '../../../../app/theme/tupic_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/space_motif_painter.dart';
import '../../../../shared/models/tupic_channel.dart';

class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.width,
    required this.onOpen,
    required this.onPlay,
  });

  final TupicChannel channel;
  final double width;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = Color(channel.accentColor.value);
    final motifSeed = channel.id.hashCode;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TupicColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TupicColors.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpen,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.92),
                            TupicColors.selected.withValues(alpha: 0.95),
                            const Color(0xFF17121F),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SpaceMotifPainter(
                                seed: motifSeed,
                                accent: TupicColors.accentViolet,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AudienceChip(isKids: channel.isKidsChannel),
                                const Spacer(),
                                Text(
                                  channel.coverLabel ?? 'TUPICK',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onOpen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: TupicColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.videoCount(channel.videoCount),
                            style: const TextStyle(
                              color: TupicColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: Key('channel_card_play_${channel.id}'),
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(l10n.playChannel),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateChannelCard extends StatelessWidget {
  const CreateChannelCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: TupicColors.secondary,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: TupicColors.accentViolet.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: TupicColors.selected,
                    shape: BoxShape.circle,
                    border: Border.all(color: TupicColors.borderSubtle),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: TupicColors.accentViolet,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.createChannelCard,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TupicColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({required this.isKids});

  final bool isKids;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isKids ? l10n.kidsBadge : l10n.generalBadge,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
