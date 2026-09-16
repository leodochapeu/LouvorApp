import 'dart:async';

import 'package:flutter/material.dart';

/// Height of the compact cut/copy/paste bar shown above the keyboard on
/// phones. Kept in one place so [MediaQuery] padding and tests stay in sync.
const double kAppTextEditBarHeight = 52;

const ValueKey<String> appTextEditBarKey = ValueKey('app-text-edit-bar');

/// Whether this surface should show the persistent text-edit actions.
///
/// Flutter's floating selection menu is unreliable on mobile web: it is
/// often covered by the virtual keyboard or dismissed when the viewport
/// resizes. iOS and Android (including those platforms in a mobile browser)
/// get a bar that stays above the keyboard instead.
bool appShowsTextEditBar(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return true;
    default:
      return MediaQuery.sizeOf(context).shortestSide < 600;
  }
}

/// Builds the floating selection menu, keeping it on-screen and always
/// offering paste even when the browser has not granted clipboard access yet.
Widget appTextContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: _visibleAnchors(context, editableTextState.contextMenuAnchors),
    buttonItems: appTextContextMenuItems(editableTextState),
  );
}

/// Cut / copy / paste / select-all in a stable order. Paste is included for
/// any writable field so the action is not hidden on web.
List<ContextMenuButtonItem> appTextContextMenuItems(EditableTextState state) {
  final value = state.textEditingValue;
  final selection = value.selection;
  final hasSelection = selection.isValid && !selection.isCollapsed;
  final readOnly = state.widget.readOnly;
  final obscure = state.widget.obscureText;
  final text = value.text;

  return [
    if (!readOnly && !obscure && hasSelection)
      ContextMenuButtonItem(
        type: ContextMenuButtonType.cut,
        onPressed: () => state.cutSelection(SelectionChangedCause.toolbar),
      ),
    if (!obscure && hasSelection)
      ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: () => state.copySelection(SelectionChangedCause.toolbar),
      ),
    if (!readOnly)
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          unawaited(state.pasteText(SelectionChangedCause.toolbar));
        },
      ),
    if (text.isNotEmpty &&
        !(selection.isValid &&
            selection.start == 0 &&
            selection.end == text.length))
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () => state.selectAll(SelectionChangedCause.toolbar),
      ),
  ];
}

TextSelectionToolbarAnchors _visibleAnchors(
  BuildContext context,
  TextSelectionToolbarAnchors anchors,
) {
  final mq = MediaQuery.of(context);
  final minY = mq.padding.top + 8;
  final maxY = mq.size.height - mq.viewInsets.bottom - 72;
  final minX = 16.0;
  final maxX = mq.size.width - 16;

  Offset clamp(Offset offset) {
    final dy = maxY >= minY ? offset.dy.clamp(minY, maxY) : minY;
    return Offset(offset.dx.clamp(minX, maxX), dy);
  }

  return TextSelectionToolbarAnchors(
    primaryAnchor: clamp(anchors.primaryAnchor),
    secondaryAnchor:
        anchors.secondaryAnchor == null ? null : clamp(anchors.secondaryAnchor!),
  );
}

EditableTextState? focusedEditableText() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return null;
  final context = focus.context;
  if (context == null) return null;

  if (context case StatefulElement(:final state) when state is EditableTextState) {
    return state;
  }
  return context.findAncestorStateOfType<EditableTextState>();
}

/// Wraps the app so that, on phones, focusing a text field shows Recortar /
/// Copiar / Colar / Selecionar tudo above the keyboard.
class AppTextEditBar extends StatefulWidget {
  const AppTextEditBar({super.key, required this.child});

  final Widget child;

  @override
  State<AppTextEditBar> createState() => _AppTextEditBarState();
}

class _AppTextEditBarState extends State<AppTextEditBar> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChange);
    _controller?.removeListener(_handleSelectionChange);
    super.dispose();
  }

  void _handleFocusChange() {
    final next = focusedEditableText()?.widget.controller;
    if (!identical(next, _controller)) {
      _controller?.removeListener(_handleSelectionChange);
      _controller = next;
      _controller?.addListener(_handleSelectionChange);
    }
    if (mounted) setState(() {});
  }

  void _handleSelectionChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final editable = focusedEditableText();
    final showBar = appShowsTextEditBar(context) &&
        editable != null &&
        editable.mounted;
    final barExtent = showBar
        ? kAppTextEditBarHeight +
            (mq.viewInsets.bottom == 0 ? mq.padding.bottom : 0)
        : 0.0;

    return Stack(
      children: [
        MediaQuery(
          data: mq.copyWith(
            viewInsets: mq.viewInsets.copyWith(
              bottom: mq.viewInsets.bottom + barExtent,
            ),
          ),
          child: widget.child,
        ),
        if (showBar && editable != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: mq.viewInsets.bottom,
            child: _EditBar(editable: editable),
          ),
      ],
    );
  }
}

class _EditBar extends StatelessWidget {
  const _EditBar({required this.editable});

  final EditableTextState editable;

  @override
  Widget build(BuildContext context) {
    if (!editable.mounted) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = MaterialLocalizations.of(context);
    final items = appTextContextMenuItems(editable);
    final mq = MediaQuery.of(context);

    Widget button(ContextMenuButtonItem item) {
      final (icon, label) = switch (item.type) {
        ContextMenuButtonType.cut => (Icons.content_cut, l10n.cutButtonLabel),
        ContextMenuButtonType.copy => (Icons.content_copy, l10n.copyButtonLabel),
        ContextMenuButtonType.paste => (Icons.content_paste, l10n.pasteButtonLabel),
        ContextMenuButtonType.selectAll => (
            Icons.select_all,
            l10n.selectAllButtonLabel,
          ),
        _ => (Icons.edit_outlined, l10n.pasteButtonLabel),
      };

      return Expanded(
        child: TextButton(
          onPressed: item.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: FittedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 2),
                Text(label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      );
    }

    // [TextFieldTapRegion] keeps the field focused when these buttons are
    // tapped; otherwise the keyboard closes and the actions never run.
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: Material(
          key: appTextEditBarKey,
          color: theme.colorScheme.surfaceContainer,
          elevation: 3,
          child: SafeArea(
            top: false,
            bottom: mq.viewInsets.bottom == 0,
            child: SizedBox(
              height: kAppTextEditBarHeight,
              child: items.isEmpty
                  ? const SizedBox.shrink()
                  : Row(children: [for (final item in items) button(item)]),
            ),
          ),
        ),
      ),
    );
  }
}
