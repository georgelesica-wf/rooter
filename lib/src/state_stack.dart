import 'scope_state.dart';

/// A stack of state objects.
class StateStack {
  Iterable<ScopeState> _stack;

  StateStack([ScopeState state]) {
    var stack = <ScopeState>[];
    if (state != null) {
      stack.add(state);
    }
    _stack = stack;
  }

  StateStack._(this._stack);

  bool get isEmpty => _stack.isEmpty;

  /// TODO: Should this throw on an empty stack?
  ScopeState get next => _stack.isEmpty ? null : _stack.first;

  StateStack popped() => new StateStack._(_stack.skip(1).toList());

  StateStack pushed(ScopeState state) => new StateStack._([]
    ..addAll(_stack)
    ..add(state));
}
