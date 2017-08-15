import 'scope_state.dart';
import 'state_stack.dart';

/// An object used to propagate new state into a hierarchy of nested
/// scopes.
class AcceptStateEvent {
  StateStack _proposedStateStack;

  bool _wasRejected = false;

  AcceptStateEvent(this._proposedStateStack);

  /// The state proposed for the scope to adopt.
  ScopeState get proposedState => _proposedStateStack.next;

  /// The entire stack of states proposed to be applied to the current
  /// hierarchy.
  StateStack get proposedStateStack => _proposedStateStack;

  /// Whether or not the event was rejected by one or more scopes.
  bool get wasRejected => _wasRejected;

  /// Should be called by a scope if it cannot accept the proposed state.
  void reject() {
    _wasRejected = true;
  }
}
