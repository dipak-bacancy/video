import 'package:flutter/material.dart';
import 'package:video/videoitem.dart';
import 'package:video_player/video_player.dart';

class Video extends StatefulWidget {
  Video({Key key}) : super(key: key);

  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<Video> {
  VideoPlayerController _controller;

  var _playingIndex = -1;
  var _progress = 0.0;
  var _isEndOfClip = false;
  bool _disposed = false;

  var _playing = false;

  bool get _isPlaying {
    return _playing;
  }

  set _isPlaying(bool value) {
    _playing = value;
  }

  List _videos = [
    'assets/butterfly.mp4',
    'assets/giraffe.mp4',
    'assets/small.mp4',
    'assets/butterfly.mp4',
  ];

  @override
  void initState() {
    _initializeAndPlay(0);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeAndPlay(int index) async {
    print("_initializeAndPlay ---------> $index");
    final clip = _videos[index];

    final controller = VideoPlayerController.asset(clip);

    final old = _controller;
    _controller = controller;
    if (old != null) {
      old.removeListener(_onControllerUpdated);
      old.pause();
      debugPrint("---- old contoller paused.");
    }

    debugPrint("---- controller changed.");
    setState(() {});

    controller
      ..initialize().then((_) {
        debugPrint("---- controller initialized");
        old?.dispose();
        _playingIndex = index;
        _duration = null;
        _position = null;
        controller.addListener(_onControllerUpdated);
        controller.play();
        setState(() {});
      });
  }

  Duration _duration;
  Duration _position;

  void _onControllerUpdated() async {
    if (_disposed) return;

    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.initialized) return;
    if (_duration == null) {
      _duration = _controller.value.duration;
    }
    var duration = _duration;
    if (duration == null) return;

    var position = await controller.position;
    _position = position;

    final playing = controller.value.isPlaying;

    final isEndOfClip = position.inMilliseconds > 0 &&
        position.inSeconds + 1 >= duration.inSeconds;

    if (playing) {
      // handle progress indicator
      if (_disposed) return;
      setState(() {
        _progress = position.inMilliseconds.ceilToDouble() /
            duration.inMilliseconds.ceilToDouble();
      });
    }

    // handle clip end
    if (_isPlaying != playing || _isEndOfClip != isEndOfClip) {
      _isPlaying = playing;
      _isEndOfClip = isEndOfClip;
      debugPrint(
          "updated -----> isPlaying=$playing / isEndOfClip=$isEndOfClip");
      if (isEndOfClip && !playing) {
        debugPrint(
            "========================== End of Clip / Handle NEXT ========================== ");
        final isComplete = _playingIndex == _videos.length - 1;
        if (isComplete) {
          print("played all!!");
        } else {
          _initializeAndPlay(_playingIndex + 1);
        }
      }
    }
  }

  void replay() {
    setState(() {
      _playingIndex = 0;
      _progress = 0;
    });

    _initializeAndPlay(0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / _videos.length;

    double progress = _progress * width + _playingIndex * width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: playview(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Stack(children: [
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _videos.length,
                  itemBuilder: (BuildContext context, int _index) {
                    print(_videos.length);
                    return VideoItem(
                      url: _videos.elementAt(_index),
                      active: false,
                      width: width,
                    );
                  },
                ),

                // / _progress * width + _playingIndex * width
                Padding(
                  padding: EdgeInsets.only(left: progress),
                  child: Container(
                    width: 10,
                    color: Colors.white,
                  ),
                )
              ]),
            ),
            Expanded(
              flex: 2,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemBuilder: (BuildContext context, int _index) {
                  final item = _videos[_index];
                  return VideoItem(
                    key: ValueKey('$_index $item'),
                    url: item,
                    active: _playingIndex == _index,
                    width: 80,
                  );
                },
                itemCount: _videos.length,
                onReorder: (int oldIndex, int newIndex) {
                  // _controller.pause();
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final items = _videos.removeAt(oldIndex);
                    _videos.insert(newIndex, items);
                  });
                  replay();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget playview() {
    final controller = _controller;

    if (controller != null && controller.value.initialized) {
      return VideoPlayer(controller);
    } else {
      return Center(
        child: Text(
          "Preparing ...",
          style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 18.0),
        ),
      );
    }
  }
}
