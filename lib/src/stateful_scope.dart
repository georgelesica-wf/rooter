import 'dart:async';

import 'package:meta/meta.dart';

import 'accept_state_event.dart';
import 'scope_state.dart';
import 'state_stack.dart';

/// An object that has some kind of state and can transition from one
/// version of this state to another either on its own or in response
/// to outside requests.
///
/// Scopes can be nested within one another. When state is passed in
/// it is passed as a collection of state objects which are consumed
/// one per nesting level until none remain.
abstract class StatefulScope {
  Set<StatefulScope> _childScopes = new Set<StatefulScope>();

  StreamController<StateStack> _onStateAnnouncedController =
      new StreamController<StateStack>.broadcast();

  StatefulScope get activeChildScope;

  ScopeState get currentState;

  StateStack get currentStateStack {
    if (activeChildScope == null) {
      return new StateStack(currentState);
    }
    return activeChildScope.currentStateStack.pushed(currentState);
  }

  /// Stream that fires when the object changes its own internal state.
  Stream<StateStack> get onStateAnnounced =>
      _onStateAnnouncedController.stream;

  /// Requests that the object accept new state from outside.
  Future<Null> acceptState(AcceptStateEvent event) async {
    if (event.proposedStateStack.isEmpty) {
      return;
    }

    await onAcceptState(event);

    if (event.wasRejected) {
      return;
    }

    var childEvent = new AcceptStateEvent(event.proposedStateStack.popped());
    await activeChildScope.acceptState(childEvent);
    if (childEvent.wasRejected) {
      event.reject();
    }
  }

  /// Announces the current state to listeners.
  @protected
  void announceState() {
    _onStateAnnouncedController.add(currentStateStack);
  }

  /// Add a child scope.
  void addChild(StatefulScope scope) {
    _childScopes.add(scope);

    scope.onStateAnnounced.listen((stateStack) {
      if (scope == activeChildScope) {
        announceState();
      }
    });
  }

  /// Called when the object is asked to accept new state. The object may
  /// effectively reject the new state by firing [onStateChange] from
  /// within this callback.
  ///
  /// If the object chooses to accept the state, it should store whatever
  /// information it requires from the state and arrange for any views
  /// that depend on it to be updated, etc.
  ///
  /// It is the responsibility of the consumer to announce a new state if
  /// creation of a child scope fails and state propagation must be stopped
  /// early.
  @protected
  Future<Null> onAcceptState(AcceptStateEvent event);
}