library global_configs;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:gato/gato.dart' as gato;
import 'package:path_provider/path_provider.dart';

/// A singleton class to set and get global configs.
///
/// Use GlobalConfigs() to access the singleton.
class GlobalConfigs {
  static GlobalConfigs _singleton = GlobalConfigs._internal();

  /// The current configs
  Map<String, dynamic> configs = Map<String, dynamic>();

  /// Returns the singleton object
  factory GlobalConfigs() => _singleton;

  GlobalConfigs._internal();

  /// Load your [GlobalConfigs] from a [map] into the current configs
  ///
  /// Load your configs into a specific path by [path]
  /// It will create new path if the [path] doesn't exist
  ///
  /// ```dart
  /// Map<String, dynamic> map = { 'a': 1, 'b': {'c': 2}};
  /// GlobalConfigs.loadFromMap(map, path: 'b.c');
  /// ```
  GlobalConfigs loadFromMap(Map<String, dynamic> map, {String? path}) {
    path == null ? configs.addAll(map) : set(path, map);

    return _singleton;
  }

  /// Load your [GlobalConfigs] from a `JSON` file into the current configs
  ///
  /// Load your configs into a specific path by [path]
  /// It will create new key if the [path] doesn't exist
  ///
  /// ```dart
  /// await GlobalConfigs().loadJsonFromDir(dir, 'assets/cofig.json');
  /// ```
  Future<GlobalConfigs> loadJsonFromdir(String dir, {String? path}) async {
    // Load default configuration from assets folder first.
    String content = await rootBundle.loadString(dir);
    Map<String, dynamic> res = json.decode(content);
    // debugPrint("$res");
    path == null ? configs.addAll(res) : set(path, res);
    set("syncWithDrive.due", DateTime.now().add(Duration(days: 7)).toString());
    set("syncWithDrive.frequency", 7);
    set("syncWithDrive.lastSync", DateTime.now().toString());

    var appSupportDir = await getApplicationSupportDirectory();
    final File configFile = File(appSupportDir.path + "/config.json");
    debugPrint("support dir path ====${appSupportDir.path}");
    // Now reads existing support directory configuration, overrides default
    // values.
    if (await configFile.exists()) {
      String content = await configFile.readAsString();
      Map<String, dynamic> res = json.decode(content);
      // debugPrint("$res");
      configs.addAll(res);
    }
    // Write full json configuration back, this takes extra dist write
    // every time app opens up
    await configFile.writeAsString(json.encode(res));
    return _singleton;
  }

  /// Reads from the configs
  ///
  /// Use [path] to access to a specific key
  ///
  /// Use [convertor] to cast the valeu to your custom type
  ///
  /// ```dart
  /// Map<String, dynamic> map = { 'a': 1, 'b': {'c': 2}};
  /// GlobalConfigs.loadFromMap(map);
  ///
  /// GlobalConfigs().get('a'); // 1
  /// GlobalConfigs().get('b.c'); // 2
  /// ```dart
  T? get<T>(String path, {T Function(dynamic)? converter}) =>
      gato.get(configs, path, converter: converter);

  /// Sets new data to the configs
  ///
  /// Use [path] to access to a specific key
  /// and pass your new value to [value].
  /// It will create new key if the [path] doesn't exist.
  ///
  /// ```dart
  /// Map<String, dynamic> map = { 'a': 1, 'b': {'c': 2}};
  /// GlobalConfigs.loadFromMap(map);
  ///
  /// GlobalConfigs().set('a', 3); // { 'a': 3, 'b': {'c': 2}}
  /// GlobalConfigs().set('b.d', 4); // { 'a': 3, 'b': {'c': 2, 'd': 4}}
  /// ```dart
  Future<void> set<T>(String path, T value) async {
    configs = gato.set<T>(configs, path, value);

    var appSupportDir = await getApplicationSupportDirectory();

    final File configFile = File(appSupportDir.path + "/config.json");

    await configFile.writeAsString(jsonEncode(configs));

    debugPrint("$configs");
  }

  /// Removes data to the configs
  ///
  /// Use [path] to access to a specific key
  ///
  /// ```dart
  /// Map<String, dynamic> map = { 'a': 1, 'b': {'c': 2}};
  /// GlobalConfigs.loadFromMap(map);
  ///
  /// GlobalConfigs().unset('b'); // { 'a': 3}
  /// ```dart
  void unset(String path) => configs = gato.unset(configs, path);

  /// Clear the current configs
  void clear() => configs.clear();
}
