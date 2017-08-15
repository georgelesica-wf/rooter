/// A container for scope state.
abstract class ScopeState {
  String get type;
  String get id;

  Map<String, String> _parameters = {};

  int getInt(String name) => int.parse(_parameters[name]);

  String getString(String name) => _parameters[name];
}
