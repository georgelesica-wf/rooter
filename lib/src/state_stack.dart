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

  /// Whether the stack contains zero items.
  bool get isEmpty => _stack.isEmpty;

  /// The next state object in the hierarchy.
  ScopeState get next => _stack.isEmpty ? null : _stack.first;

  /// Return a new stack with the first state object popped.
  StateStack popped() => new StateStack._(_stack.skip(1).toList());

  /// Return a new stack with the given state object pushed.
  StateStack pushed(ScopeState state) => new StateStack._([]
    ..addAll(_stack)
    ..add(state));
}
