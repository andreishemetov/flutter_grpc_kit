import 'dart:math' as math;

/// Box-style debug logger similar to PrettyDioLogger output.
final class PrettyBoxLogPrinter {
  PrettyBoxLogPrinter({this.maxWidth = 90, this.compact = true, this.logPrint = _defaultLogPrint});

  static const int kInitialTab = 1;
  static const String tabStep = '    ';

  final int maxWidth;
  final bool compact;
  final void Function(String message) logPrint;

  void printBoxed({String? header, String? text}) {
    logPrint('');
    logPrint('╔╣ $header');
    logPrint('║  $text');
    _printLine('╚');
  }

  void printMapAsTable(Map? map, {required String header}) {
    if (map == null || map.isEmpty) {
      return;
    }

    logPrint('╔ $header ');
    for (final entry in map.entries) {
      _printKV(entry.key.toString(), entry.value);
    }
    _printLine('╚');
  }

  void printBody(dynamic data) {
    logPrint('╔ Body');
    logPrint('║');
    _printResponse(data);
    logPrint('║');
    _printLine('╚');
  }

  void _printResponse(dynamic data) {
    if (data == null) {
      _printBlock('null');
      return;
    }

    if (data is Map) {
      _printPrettyMap(data);
    } else if (data is List) {
      logPrint('║${_indent()}[');
      _printList(data);
      logPrint('║${_indent()}]');
    } else {
      _printBlock(data.toString());
    }
  }

  void _printLine([String pre = '', String suf = '╝']) {
    logPrint('$pre${'═' * maxWidth}$suf');
  }

  void _printKV(String? key, Object? value) {
    final pre = '╟ $key: ';
    final msg = value.toString();

    if (pre.length + msg.length > maxWidth) {
      logPrint(pre);
      _printBlock(msg);
    } else {
      logPrint('$pre$msg');
    }
  }

  void _printBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      logPrint(
        (i >= 0 ? '║ ' : '') +
            msg.substring(i * maxWidth, math.min<int>(i * maxWidth + maxWidth, msg.length)),
      );
    }
  }

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  void _printPrettyMap(
    Map data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    var tabs = initialTab;
    final isRoot = tabs == kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) {
      logPrint('║$initialIndent{');
    }

    for (var index = 0; index < data.length; index++) {
      final isLastEntry = index == data.length - 1;
      final key = '"${data.keys.elementAt(index)}"';
      dynamic value = data[data.keys.elementAt(index)];
      if (value is String) {
        value = '"${value.replaceAll(RegExp(r'([\r\n])+'), ' ')}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint('║${_indent(tabs)} $key: $value${!isLastEntry ? ',' : ''}');
        } else {
          logPrint('║${_indent(tabs)} $key: {');
          _printPrettyMap(value, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint('║${_indent(tabs)} $key: $value');
        } else {
          logPrint('║${_indent(tabs)} $key: [');
          _printList(value, tabs: tabs);
          logPrint('║${_indent(tabs)} ]${isLastEntry ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final lineWidth = maxWidth - indent.length;
        if (msg.length + indent.length > lineWidth) {
          final lines = (msg.length / lineWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            final multilineKey = i == 0 ? '$key:' : '';
            logPrint(
              '║${_indent(tabs)} $multilineKey ${msg.substring(i * lineWidth, math.min<int>(i * lineWidth + lineWidth, msg.length))}',
            );
          }
        } else {
          logPrint('║${_indent(tabs)} $key: $msg${!isLastEntry ? ',' : ''}');
        }
      }
    }

    logPrint('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printList(List list, {int tabs = kInitialTab}) {
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      final isLast = i == list.length - 1;
      if (element is Map) {
        if (compact && _canFlattenMap(element)) {
          logPrint('║${_indent(tabs)}  $element${!isLast ? ',' : ''}');
        } else {
          _printPrettyMap(element, initialTab: tabs + 1, isListItem: true, isLast: isLast);
        }
      } else {
        logPrint('║${_indent(tabs + 2)} $element${isLast ? '' : ','}');
      }
    }
  }

  bool _canFlattenMap(Map map) {
    return map.values.where((dynamic val) => val is Map || val is List).isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }
}

void _defaultLogPrint(String message) {
  // ignore: avoid_print
  print(message);
}
