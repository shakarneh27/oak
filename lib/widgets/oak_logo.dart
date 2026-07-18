import 'package:flutter/material.dart';

/// The official Digital Oak logo (assets/images/logo.png from the
/// reference design). The mark already contains the tree, book, squirrel,
/// and bilingual wordmark.
class OakLogo extends StatelessWidget {
  final double size;

  const OakLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Logo + wordmark lockup used in top bars and auth screens.
class OakBrand extends StatelessWidget {
  final double logoSize;
  final bool showTagline;

  /// Overrides the wordmark color (e.g. white on the forest backdrop).
  final Color? textColor;

  const OakBrand({
    super.key,
    this.logoSize = 40,
    this.showTagline = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleColor = textColor ?? textTheme.titleMedium?.color;
    final taglineColor = (textColor ?? textTheme.bodySmall?.color)?.withValues(
      alpha: 0.7,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // white chip behind the mark so it reads on dark backgrounds too
        Container(
          padding: EdgeInsets.all(logoSize * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(logoSize * 0.22),
          ),
          child: OakLogo(size: logoSize * 0.88),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'السنديانة الرقمية',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            if (showTagline)
              Text(
                'تعلّم · اكتشف · وانمُ',
                style: textTheme.bodySmall?.copyWith(color: taglineColor),
              ),
          ],
        ),
      ],
    );
  }
}
