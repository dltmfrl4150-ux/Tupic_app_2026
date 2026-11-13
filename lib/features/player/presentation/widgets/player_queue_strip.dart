import 'package:flutter/material.dart';

import '../../../../app/theme/tupic_colors.dart';
import '../../../../shared/models/channel_video.dart';

class PlayerQueueStrip extends StatelessWidget {
  const PlayerQueueStrip({
    super.key,
    required this.videos,
    required this.currentIndex,
    required this.enabled,
    required this.onSelect,
  });

  final List<ChannelVideo> videos;
  final int currentIndex;
  final bool enabled;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TupicColors.secondary,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: videos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final video = videos[index];
          final selected = index == currentIndex;
          final thumb =
              video.thumbnailUrl ??
              ChannelVideo.defaultThumbnailUrl(video.youtubeVideoId);
          return Opacity(
            opacity: enabled ? 1 : 0.45,
            child: InkWell(
              onTap: enabled ? () => onSelect(index) : null,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 148,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? TupicColors.accentViolet
                                : TupicColors.borderSubtle,
                            width: selected ? 2 : 1,
                          ),
                          color: TupicColors.card,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: TupicColors.card,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: TupicColors.mutedText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? TupicColors.accentViolet
                            : TupicColors.primaryText,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
