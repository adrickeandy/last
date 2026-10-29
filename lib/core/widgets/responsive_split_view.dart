// lib/core/widgets/responsive_split_view.dart
import 'package:flutter/material.dart';

/// Messenger-style master/detail layout.
///
/// * Wide screens (PC / tablet landscape): list on the left, chat on the right.
/// * Narrow screens (phones): list fills the screen. Tapping an item opens the
///   chat full screen with a back arrow; the system back button also returns
///   to the list.
///
/// T is whatever identifies a conversation (a Conversation object, an id, ...).
class ResponsiveSplitView<T> extends StatefulWidget {
  const ResponsiveSplitView({
    super.key,
    required this.listBuilder,
    required this.chatBuilder,
    this.emptyChat,
    this.breakpoint = 720,
    this.listWidth = 320,
  });

  /// Builds the contact / conversation list.
  /// Call [onSelect] when the user taps a conversation.
  final Widget Function(
    BuildContext context,
    T? selected,
    ValueChanged<T> onSelect,
  ) listBuilder;

  /// Builds the chat. [onBack] is null on wide screens (no back arrow needed)
  /// and non-null on phones: put it on your chat header's back button.
  final Widget Function(
    BuildContext context,
    T selected,
    VoidCallback? onBack,
  ) chatBuilder;

  /// Shown on wide screens when no conversation is selected yet.
  final Widget? emptyChat;

  /// Width (logical px) at which the layout switches to side-by-side.
  final double breakpoint;

  /// Width of the list pane in side-by-side mode.
  final double listWidth;

  @override
  State<ResponsiveSplitView<T>> createState() => _ResponsiveSplitViewState<T>();
}

class _ResponsiveSplitViewState<T> extends State<ResponsiveSplitView<T>> {
  T? _selected;

  void _select(T item) => setState(() => _selected = item);
  void _clear() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= widget.breakpoint;
        return wide ? _buildWide(context) : _buildNarrow(context);
      },
    );
  }

  // ---------------- PC / tablet ----------------
  Widget _buildWide(BuildContext context) {
    final selected = _selected;
    return Row(
      children: [
        SizedBox(
          width: widget.listWidth,
          child: widget.listBuilder(context, selected, _select),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: selected == null
              ? (widget.emptyChat ??
                  const Center(child: Text('Select a conversation')))
              : widget.chatBuilder(context, selected, null),
        ),
      ],
    );
  }

  // ---------------- Phone ----------------
  Widget _buildNarrow(BuildContext context) {
    final selected = _selected;

    // PopScope: system back closes the chat instead of leaving the screen.
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selected != null) _clear();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected == null
            ? KeyedSubtree(
                key: const ValueKey('list'),
                child: widget.listBuilder(context, null, _select),
              )
            : KeyedSubtree(
                key: ValueKey('chat-$selected'),
                child: widget.chatBuilder(context, selected, _clear),
              ),
      ),
    );
  }
}// lib/core/widgets/responsive_split_view.dart
import 'package:flutter/material.dart';

/// Messenger-style master/detail layout.
///
/// * Wide screens (PC / tablet landscape): list on the left, chat on the right.
/// * Narrow screens (phones): list fills the screen. Tapping an item opens the
///   chat full screen with a back arrow; the system back button also returns
///   to the list.
///
/// T is whatever identifies a conversation (a Conversation object, an id, ...).
class ResponsiveSplitView<T> extends StatefulWidget {
  const ResponsiveSplitView({
    super.key,
    required this.listBuilder,
    required this.chatBuilder,
    this.emptyChat,
    this.breakpoint = 720,
    this.listWidth = 320,
  });

  /// Builds the contact / conversation list.
  /// Call [onSelect] when the user taps a conversation.
  final Widget Function(
    BuildContext context,
    T? selected,
    ValueChanged<T> onSelect,
  ) listBuilder;

  /// Builds the chat. [onBack] is null on wide screens (no back arrow needed)
  /// and non-null on phones: put it on your chat header's back button.
  final Widget Function(
    BuildContext context,
    T selected,
    VoidCallback? onBack,
  ) chatBuilder;

  /// Shown on wide screens when no conversation is selected yet.
  final Widget? emptyChat;

  /// Width (logical px) at which the layout switches to side-by-side.
  final double breakpoint;

  /// Width of the list pane in side-by-side mode.
  final double listWidth;

  @override
  State<ResponsiveSplitView<T>> createState() => _ResponsiveSplitViewState<T>();
}

class _ResponsiveSplitViewState<T> extends State<ResponsiveSplitView<T>> {
  T? _selected;

  void _select(T item) => setState(() => _selected = item);
  void _clear() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= widget.breakpoint;
        return wide ? _buildWide(context) : _buildNarrow(context);
      },
    );
  }

  // ---------------- PC / tablet ----------------
  Widget _buildWide(BuildContext context) {
    final selected = _selected;
    return Row(
      children: [
        SizedBox(
          width: widget.listWidth,
          child: widget.listBuilder(context, selected, _select),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: selected == null
              ? (widget.emptyChat ??
                  const Center(child: Text('Select a conversation')))
              : widget.chatBuilder(context, selected, null),
        ),
      ],
    );
  }

  // ---------------- Phone ----------------
  Widget _buildNarrow(BuildContext context) {
    final selected = _selected;

    // PopScope: system back closes the chat instead of leaving the screen.
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selected != null) _clear();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected == null
            ? KeyedSubtree(
                key: const ValueKey('list'),
                child: widget.listBuilder(context, null, _select),
              )
            : KeyedSubtree(
                key: ValueKey('chat-$selected'),
                child: widget.chatBuilder(context, selected, _clear),
              ),
      ),
    );
  }
}
