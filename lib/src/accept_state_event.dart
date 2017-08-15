import 'scope_state.dart';
import 'state_stack.dart';

/// An object used to propagate new state into a hierarchy of nested
/// scopes.
class AcceptStateEvent {
  StateStack _proposedStateStack;

  bool _wasRejected = false;

  AcceptStateEvent(this._proposedStateStack);

  ScopeState get proposedState => _proposedStateStack.next;

  StateStack get proposedStateStack => _proposedStateStack;

  bool get wasRejected => _wasRejected;

  void reject() {
    _wasRejected = true;
  }
}
