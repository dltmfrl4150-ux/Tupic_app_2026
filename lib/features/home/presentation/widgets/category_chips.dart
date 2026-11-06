import 'package:flutter/material.dart';

import '../../../../app/theme/tupic_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/content_category.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ContentCategory selected;
  final ValueChanged<ContentCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <ContentCategory, String>{
      ContentCategory.all: l10n.categoryAll,
      ContentCategory.english: l10n.categoryEnglish,
      ContentCategory.music: l10n.categoryMusic,
      ContentCategory.science: l10n.categoryScience,
      ContentCategory.art: l10n.categoryArt,
      ContentCategory.animals: l10n.categoryAnimals,
      ContentCategory.other: l10n.categoryOther,
    };

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: ContentCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = ContentCategory.values[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(labels[category]!),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            selectedColor: TupicColors.selected,
            backgroundColor: TupicColors.card,
            labelStyle: TextStyle(
              color: isSelected
                  ? TupicColors.primaryText
                  : TupicColors.mutedText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            side: BorderSide(
              color: isSelected
                  ? TupicColors.accentViolet.withValues(alpha: 0.55)
                  : TupicColors.borderSubtle,
            ),
          );
        },
      ),
    );
  }
}
