import 'package:flutter/material.dart';

class EmojiPickerWidget extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  const EmojiPickerWidget({super.key, required this.onEmojiSelected});

  static const List<String> _emojis = [
    // Smileys & Emotion
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', 
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', 
    '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩', 
    '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', 
    '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', 
    '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', 
    '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯', 
    '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐', 
    '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '😈', '👿', '👹', 
    '👺', '💀', '☠️', '👻', '👽', '👾', '🤖', '💩', '😺', '😸',
    // Hands & Gestures
    '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞', 
    '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍', 
    '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', 
    '🙏', '✍️', '💅', '🤳', '💪', '🦾', '🦿', '🦵', '🦶', '👂', 
    // Hearts & Love
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', 
    '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', 
    '💟', '💌', '💋', '👥', '👤', '👫', '👭', '👬', '💏', '💑',
    // Animals & Nature
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', 
    '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', 
    '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', 
    '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // Category header or simple drag indicator
          Container(
            width: 30,
            height: 3,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onEmojiSelected(emoji),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
