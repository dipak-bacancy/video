import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoItem extends StatefulWidget {
  VideoItem({Key key, this.url, this.active, this.width = 50})
      : super(key: key);

  final String url;
  final bool active;

  final double width;

  @override
  _VideoItemState createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.url)
      ..initialize().then((_) {
        setState(() {}); //when your thumbnail will show.
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Container(
      height: 50,
      width: widget.width,
      decoration: widget.active
          ? BoxDecoration(
              border: Border.all(width: 5, color: Colors.pink),
              borderRadius: BorderRadius.all(Radius.circular(10)))
          : BoxDecoration(),
      child: VideoPlayer(controller),
    );
  }
}
