import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class VolumeWatcher extends StatefulWidget {
  final Function(double) onVolumeChangeListener;
  final Widget child;

  VolumeWatcher({
    Key key,
    @required this.onVolumeChangeListener,
    this.child,
  }) : super(key: key) {
    assert(this.onVolumeChangeListener != null);
  }

   static const MethodChannel methodChannel = const MethodChannel('volume_watcher_method');
   static const EventChannel eventChannel = const EventChannel('volume_watcher_event');
   static StreamSubscription _subscription;
   static Map<int, Function> _events = {};

  /*
   * event channel回调
   */
  void _onEvent(Object event) {
    _events.values.forEach((item) {
      if (item != null) {
        item(event);
      }
    });
  }

  /*
   * event channel回调失败
   */
  void _onError(Object error) {
    print('Volume status: unknown.' + error.toString());
  }

  /// 添加监听器
  /// 返回id, 用于删除监听器使用
  int addListener(Function onEvent) {
    if (_subscription == null) {
      //event channel 注册
      _subscription = eventChannel.receiveBroadcastStream('init').listen(_onEvent, onError: _onError);
    }

    if (onEvent != null) {
      _events[onEvent.hashCode] = onEvent;
      getCurrentVolume.then((value) {
        onEvent(value);
      });
      return onEvent.hashCode;
    }
    return null;
  }

  /// 删除监听器
  void removeListener(int id) {
    if (id != null) {
      _events.remove(id);
    }
  }

  @override
  State<StatefulWidget> createState() {
    return VolumeState();
  }

   static Future<String> get platformVersion async {
    final String version = await methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  /*
   * 获取当前系统最大音量
   */
  Future<double> get getMaxVolume async {
    final double maxVolume = await methodChannel.invokeMethod('getMaxVolume', {});
    return maxVolume;
  }

  /*
   * 获取当前系统音量
   */
  Future<double> get getCurrentVolume async {
    final double currentVolume = await methodChannel.invokeMethod('getCurrentVolume', {});
    return currentVolume;
  }

  /*
   * 设置系统音量
   */
  Future<bool> setVolume(double volume) async {
    final bool success = await methodChannel.invokeMethod('setVolume', {'volume': volume});
    return success;
  }

  /// 隐藏音量面板
  /// 仅ios有效
  set hideVolumeView(bool value) {
    if (!Platform.isIOS) return;
    if (value == true) {
      methodChannel.invokeMethod('hideUI');
    } else {
      methodChannel.invokeMethod('showUI');
    }
  }

}

class VolumeState extends State<VolumeWatcher> {
  int _listenerId;
  VolumeWatcher _volumeWatcher;

  @override
  void initState() {
    super.initState();
    _volumeWatcher = VolumeWatcher(onVolumeChangeListener: (double volume) {});
    _listenerId = _volumeWatcher.addListener(widget.onVolumeChangeListener);
  }

  @override
  void dispose() {
    _volumeWatcher.removeListener(_listenerId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? SizedBox();
  }
}
