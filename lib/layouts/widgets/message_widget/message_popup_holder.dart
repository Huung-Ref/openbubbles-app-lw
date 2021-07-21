import 'package:bluebubbles/action_handler.dart';
import 'package:bluebubbles/layouts/widgets/message_widget/message_details_popup.dart';
import 'package:bluebubbles/managers/current_chat.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/repository/models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessagePopupHolder extends StatefulWidget {
  final Widget child;
  final Message message;

  MessagePopupHolder({
    Key? key,
    required this.child,
    required this.message,
  }) : super(key: key);

  @override
  _MessagePopupHolderState createState() => _MessagePopupHolderState();
}

class _MessagePopupHolderState extends State<MessagePopupHolder> {
  GlobalKey containerKey = GlobalKey();
  Offset childOffset = Offset(0, 0);
  Size? childSize;
  bool visible = true;

  void getOffset() {
    RenderBox renderBox = containerKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    setState(() {
      this.childOffset = Offset(offset.dx, offset.dy);
      childSize = size;
    });
  }

  void openMessageDetails() async {
    HapticFeedback.lightImpact();
    getOffset();

    CurrentChat? currentChat = CurrentChat.of(context);
    if (this.mounted) {
      setState(() {
        visible = false;
      });
    }

    await Navigator.push(
      context,
      PageRouteBuilder(
        settings: RouteSettings(arguments: {"hideTail": true}),
        transitionDuration: Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
              opacity: animation,
              child: MessageDetailsPopup(
                currentChat: currentChat,
                child: widget.child,
                childOffset: childOffset,
                childSize: childSize,
                message: widget.message,
              ));
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    );

    if (this.mounted) {
      setState(() {
        visible = true;
      });
    }
  }

  void sendReaction(String type) {
    debugPrint("Sending reaction type: " + type);
    ActionHandler.sendReaction(CurrentChat.of(context)!.chat, widget.message, type);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: containerKey,
      onDoubleTap: SettingsManager().settings.doubleTapForDetails.value && !widget.message.guid!.startsWith('temp')
          ? this.openMessageDetails
          : SettingsManager().settings.enableQuickTapback.value
              ? () {
                  HapticFeedback.lightImpact();
                  this.sendReaction(SettingsManager().settings.quickTapbackType.value);
                }
              : null,
      onLongPress: this.openMessageDetails,
      child: Opacity(
        child: widget.child,
        opacity: visible ? 1 : 0,
      ),
    );
  }
}
