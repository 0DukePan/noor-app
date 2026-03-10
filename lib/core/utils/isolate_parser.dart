import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility to parse JSON in background Isolates using [compute].
/// This prevents UI jank when loading large files like Bukhari.json (12MB+).
class IsolateParser {
  /// Loads a string asset and parses it using the provided [parser] function in a background Isolate.
  static Future<T> parseInBackground<T, R>({
    required String assetPath,
    required T Function(String json) parser,
  }) async {
    // We can't pass rootBundle to the isolate directly, so we load the string on the main thread.
    // However, for VERY large files, even loading string on main thread might glitch.
    // Standard Flutter practice is usually loadString -> compute(jsonDecode).
    // Here we wrap user's parser logic.
    
    final jsonString = await rootBundle.loadString(assetPath);
    
    return await compute(_parseWrapper, _ParseArgs(jsonString, parser));
  }

  static T _parseWrapper<T, R>(_ParseArgs<T> args) {
    return args.parser(args.jsonString);
  }
}

class _ParseArgs<T> {
  final String jsonString;
  final T Function(String) parser;

  _ParseArgs(this.jsonString, this.parser);
}
