import 'package:flutter/foundation.dart';

class MPTopic {
  final String code;
  final String title;
  final bool single;

  MPTopic({
    @required this.code,
    this.title,
    this.single,
  });

  Map<String, dynamic> toApiDictionary() {
    Map<String, dynamic> dictionary = {
      'code': code,
    };
    if (title != null) {
      dictionary['title'] = title;
    } else {
      dictionary['title'] = code;
    }
    if (single != null) {
      dictionary['single'] = single;
    } else {
      dictionary['single'] = false;
    }
    return dictionary;
  }
}
