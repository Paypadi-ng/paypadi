import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';

class SettingTile extends StatelessWidget {
  const SettingTile({
    required this.name,
    this.icon,
    this.onTap,
    this.padding,
    this.showTrailing = true,
    super.key,
  }) : switchValue = null,
       onChanged = null;

  const SettingTile.switchTile({
    required this.name,
    required this.switchValue,
    required this.onChanged,
    this.icon,
    this.padding,
    super.key,
  }) : onTap = null,
       showTrailing = false;

  final String name;
  final Widget? icon;
  final VoidCallback? onTap;
  final bool showTrailing;
  final bool? switchValue;
  final EdgeInsets? padding;
  final ValueChanged<bool>? onChanged;

  bool get _isSwitch => switchValue != null && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: kVeryTightLetterSpacing,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSwitch ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Values.v16,
            vertical: Values.v20,
          ),
          child: Row(
            children: [
              if (icon != null) ...[icon!, Values.v16.horizontalSpace],
              Expanded(child: Text(name, style: textStyle)),
              if (_isSwitch)
                SizedBox.square(
                  dimension: Values.v36,
                  child: Switch.adaptive(
                    value: switchValue!,
                    onChanged: onChanged,
                  ),
                )
              else if (showTrailing)
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
