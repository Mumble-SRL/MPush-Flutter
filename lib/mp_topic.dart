/// An MPush topic
class MPTopic {
  /// The code/id of the topic.
  final String code;

  /// The title of the topic
  final String? title;

  /// If this topic represents a single device or a group of devices
  final bool single;

  /// Initializes an MPTopic
  ///
  /// @param code The code/id of the topic.
  /// @param title The readable title of the topic that will be displayed in the dashboard,
  /// if this is not set it will be equal to code.
  /// @param single If this topic represents a single device or a group of devices, defaults to `false`.
  MPTopic({
    required this.code,
    this.title,
    this.single = false,
  });

  /// Converts a topic to map that can be sent to the APIs.
  Map<String, dynamic> toApiDictionary() {
    Map<String, dynamic> dictionary = {
      'code': code,
    };
    if (title != null) {
      dictionary['title'] = title;
    } else {
      dictionary['title'] = code;
    }
    dictionary['single'] = single;
    return dictionary;
  }
}
