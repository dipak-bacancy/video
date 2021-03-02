import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

main() {
  runApp(MaterialApp(
    home: VideoPlayerDemo(),
    theme: ThemeData(
      backgroundColor: Colors.black,
    ),
  ));
}

class VideoPlayerDemo extends StatefulWidget {
  @override
  _VideoPlayerDemoState createState() => _VideoPlayerDemoState();
}

class _VideoPlayerDemoState extends State<VideoPlayerDemo> {
  int index = 0;
  double _position = 0;
  double _buffer = 0;
  bool _lock = true;
  Map<String, VideoPlayerController> _controllers = {};
  Map<int, VoidCallback> _listeners = {};
  Set<String> _urls = {
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4#1',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4#2',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4#3',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4#4',
    // 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4#5',
    // 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4#6',
    // 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4#7',
  };

  @override
  void initState() {
    super.initState();

    if (_urls.length > 0) {
      _initController(0).then((_) {
        _playController(0);
      });
    }

    if (_urls.length > 1) {
      _initController(1).whenComplete(() => _lock = false);
    }
  }

  VoidCallback _listenerSpawner(index) {
    return () {
      int dur = _controller(index).value.duration.inMilliseconds;
      int pos = _controller(index).value.position.inMilliseconds;
      int buf = _controller(index).value.buffered.last.end.inMilliseconds;

      setState(() {
        if (dur <= pos) {
          _position = 0;
          return;
        }
        _position = pos / dur;
        _buffer = buf / dur;
      });
      if (dur - pos < 1) {
        if (index < _urls.length - 1) {
          _nextVideo();
        }
      }
    };
  }

  VideoPlayerController _controller(int index) {
    return _controllers[_urls.elementAt(index)];
  }

  Future<void> _initController(int index) async {
    var controller = VideoPlayerController.network(_urls.elementAt(index));
    _controllers[_urls.elementAt(index)] = controller;
    await controller.initialize();
  }

  void _removeController(int index) {
    _controller(index).dispose();
    _controllers.remove(_urls.elementAt(index));
    _listeners.remove(index);
  }

  void _stopController(int index) {
    _controller(index).removeListener(_listeners[index]);
    _controller(index).pause();
    _controller(index).seekTo(Duration(milliseconds: 0));
  }

  void _playController(int index) async {
    if (!_listeners.keys.contains(index)) {
      _listeners[index] = _listenerSpawner(index);
    }
    _controller(index).addListener(_listeners[index]);
    await _controller(index).play();
    setState(() {});
  }

  void _previousVideo() {
    if (_lock || index == 0) {
      return;
    }
    _lock = true;

    _stopController(index);

    if (index + 1 < _urls.length) {
      _removeController(index + 1);
    }

    _playController(--index);

    if (index == 0) {
      _lock = false;
    } else {
      _initController(index - 1).whenComplete(() => _lock = false);
    }
  }

  void _nextVideo() async {
    if (_lock || index == _urls.length - 1) {
      return;
    }
    _lock = true;

    _stopController(index);

    if (index - 1 >= 0) {
      _removeController(index - 1);
    }

    _playController(++index);

    if (index == _urls.length - 1) {
      _lock = false;
    } else {
      _initController(index + 1).whenComplete(() => _lock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(children: [
                    GestureDetector(
                      onLongPressStart: (_) => _controller(index).pause(),
                      onLongPressEnd: (_) => _controller(index).play(),
                      child: VideoPlayer(_controller(index)),
                    ),
                    // Positioned(
                    //   child: Container(
                    //     height: 10,
                    //     width: MediaQuery.of(context).size.width * _buffer,
                    //     color: Colors.grey,
                    //   ),
                    // ),
                    // Positioned(
                    //   child: Container(
                    //     height: 10,
                    //     width: MediaQuery.of(context).size.width * _position,
                    //     color: Colors.greenAccent,
                    //   ),
                    // ),
                  ]),
                ),
              ),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 1,
                  itemBuilder: (BuildContext context, int index) {
                    return;
                  },
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _urls.length,
                  itemBuilder: (BuildContext context, int _index) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: VideoItem(
                        url: _urls.elementAt(_index),
                        active: index == _index,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Text('Done'),
        ));
  }
}

class VideoItem extends StatefulWidget {
  VideoItem({Key key, this.url, this.active}) : super(key: key);

  final String url;

  final bool active;

  @override
  _VideoItemState createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
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
    return Container(
      height: 50,
      width: 50,
      decoration: widget.active
          ? BoxDecoration(
              border: Border.all(width: 5, color: Colors.pink),
              borderRadius: BorderRadius.all(Radius.circular(10)))
          : null,
      child: VideoPlayer(
        _controller,
      ),
    );
  }
}
