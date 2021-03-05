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

  VideoPlayerController _controller;

  VoidCallback _listener;

  List _videos = [
    'assets/butterfly.mp4',
    'assets/butterfly.mp4',
    'assets/butterfly.mp4',
    'assets/butterfly.mp4',
  ];

  @override
  void initState() {
    super.initState();

    initapp();
  }

  void initapp() {
    if (_videos.length > 0) {
      _initController(0).whenComplete(() => print('initaized'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  VoidCallback _listenerSpawner() {
    return () {
      int dur = _controller.value.duration.inMilliseconds;
      int pos = _controller.value.position.inMilliseconds;
      int buf = _controller.value.buffered.last.end.inMilliseconds;

      setState(() {
        if (dur <= pos) {
          _position = 0;
          return;
        }
        _position = pos / dur;
        _buffer = buf / dur;
      });
      if (dur - pos < 1) {
        if (index < _videos.length - 1) {
          _nextVideo();
        }
      }
    };
  }

  Future<void> _initController(int index) async {
    debugPrint("---- controller changed.");
    setState(() {});

    _controller = VideoPlayerController.asset(_videos[index]);
    await _controller.initialize();

    _playController(index);
  }

  void _stopController() {
    _controller.pause();
  }

  void _playController(int index) async {
    _listener = _listenerSpawner();

    _controller.addListener(_listener);
    await _controller.play();
    setState(() {});
  }

  void _nextVideo() async {
    if (index == _videos.length - 1) {
      return;
    }

    final oldController = _controller;

    // Registering a callback for the end of next frame
    // to dispose of an old controller
    // (which won't be used anymore after calling setState)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await oldController.dispose();

      Future.delayed(Duration(seconds: 3));
      _initController(index++);
    });

    // Making sure that controller is not used by setting it to null
    setState(() {
      _controller = null;
    });

    // _playController(++index);
  }

  void replay() {
    index = 0;
    _position = 0;
    _buffer = 0;

    setState(() {});
    initapp();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / _videos.length;
    return Scaffold(
        body: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    child: _controller == null
                        ? VideoItem(
                            url: _videos[index],
                            active: false,
                          )
                        : VideoPlayer(_controller),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Stack(children: [
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _videos.length,
                    itemBuilder: (BuildContext context, int _index) {
                      return VideoItem(
                        url: _videos.elementAt(_index),
                        active: false,
                        width: width,
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: _position * width + width * index),
                    child: Container(
                      width: 10,
                      color: Colors.white,
                    ),
                  )
                ]),
              ),
              SizedBox(height: 20),
              Expanded(
                  flex: 2,
                  child: ReorderableListView(
                    scrollDirection: Axis.horizontal,
                    onReorder: (int oldIndex, int newIndex) {
                      _controller.pause();
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final items = _videos.removeAt(oldIndex);
                        _videos.insert(newIndex, items);
                      });
                      replay();
                    },
                    children: _videos
                        .asMap()
                        .entries
                        .map((item) => Padding(
                              key: ValueKey(item.key),
                              padding: const EdgeInsets.all(12.0),
                              child: VideoItem(
                                url: item.value,
                                active: index == item.key,
                                width: 50,
                              ),
                            ))
                        .toList(),
                  )),
              SizedBox(height: 20),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: replay,
          child: Text('Done'),
        ));
  }
}

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
    return Container(
      height: 50,
      width: widget.width,
      decoration: widget.active
          ? BoxDecoration(
              border: Border.all(width: 5, color: Colors.pink),
              borderRadius: BorderRadius.all(Radius.circular(10)))
          : null,
      child: Stack(children: [
        VideoPlayer(
          _controller,
        ),
      ]),
    );
  }
}
