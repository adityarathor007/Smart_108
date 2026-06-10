import 'package:logger/logger.dart';

/// Global logger instance
/// Use this instead of 'print' for better debugging and production safety.
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // Set to 2 if you want to see which function called the log
    errorMethodCount: 5, // Number of calls if a stacktrace is provided
    lineLength: 80, // Width of the output border
    colors: true, // Colorful log messages (works in most IDE consoles)
    printEmojis: true, // Addsto your logs
  ),
);
