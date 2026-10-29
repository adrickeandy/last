import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../theme/app_colors.dart';

class GlassTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  // Set true for password fields instead of obscureText. Adds a built-in
  // eye icon that toggles visibility and manages the obscure state
  // internally. Password fields never show the emoji picker, regardless
  // of showEmojiPicker below.
  final bool isPassword;
  // Adds a built-in emoji-picker button that inserts the picked emoji at
  // the current cursor position. Defaults to on for every field; set to
  // false to opt a specific field out (e.g. numeric-only inputs). Has no
  // effect if `controller` is null, since insertion needs a controller to
  // read/write cursor position, or if `isPassword` is true.
  final bool showEmojiPicker;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.showEmojiPicker = true,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  // Password fields start obscured. Plain obscureText fields (isPassword
  // false) just use whatever the caller passed and can't be toggled, same
  // as before.
  late bool _obscure = widget.isPassword ? true : widget.obscureText;

  bool get _emojiEnabled =>
      widget.showEmojiPicker && !widget.isPassword && widget.controller != null;

  void _openEmojiPicker() {
    final controller = widget.controller;
    if (controller == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg800 : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: EmojiPicker(
              textEditingController: controller,
              onEmojiSelected: (category, emoji) {
                // textEditingController above already handles inserting the
                // emoji at the cursor position for us; just propagate the
                // change to the caller's onChanged like normal typing would.
                widget.onChanged?.call(controller.text);
              },
              config: Config(
                height: 320,
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: isDark ? AppColors.darkBg800 : Colors.white,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: isDark ? AppColors.darkBg800 : Colors.white,
                  iconColorSelected: AppColors.violet500,
                  indicatorColor: AppColors.violet500,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  backgroundColor: Colors.transparent,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: isDark ? AppColors.darkBg800 : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? effectiveSuffixIcon;
    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 19,
          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
        ),
        splashRadius: 18,
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    } else if (_emojiEnabled || widget.suffixIcon != null) {
      effectiveSuffixIcon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.suffixIcon != null) widget.suffixIcon!,
          if (_emojiEnabled)
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                size: 19,
                color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
              ),
              splashRadius: 18,
              tooltip: 'Insert emoji',
              onPressed: _openEmojiPicker,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkInk300 : AppColors.lightInk300,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          maxLines: _obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          style: TextStyle(
            color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
              fontSize: 14,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: effectiveSuffixIcon,
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.lightGlassBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.lightGlassBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.violet500,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.coral500,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.coral500,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
