/// A container for scope state.
class ScopeState {
  Map<String, String> _parameters = <String, String>{};

  /// Scope type, used as a top-level identifier.
  final String type;

  /// Scope ID, used as a second-level identifier.
  final String id;

  ScopeState(this.type, this.id);

  /// Fetch a parameter value.
  String get(String key) => _parameters[key];

  /// Fetch a parameter value converted to an int.
  int getInt(String key) {
    var strValue = _parameters[key];
    if (strValue == null) {
      return null;
    }
    return int.parse(strValue);
  }

  /// Set a parameter value.
  void set(String key, Object value) => _parameters[key] = value.toString();
}
