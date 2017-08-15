/// A container for scope state.
abstract class ScopeState {
  Map<String, String> _parameters = {};

  /// Scope type, used as a top-level identifier.
  String get type;

  /// Scope ID, used as a second-level identifier.
  String get id;

  /// Fetch a parameter value.
  String get(String name) => _parameters[name];
}
