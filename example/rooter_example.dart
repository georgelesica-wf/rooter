import 'dart:async';
import 'dart:html';

import 'package:rooter/rooter.dart';

class Experience extends StatefulScope {
  static int _nextId = 0;

  StreamController<Null> _triggerController = new StreamController<Null>.broadcast();

  Map<int, Experience> _children = <int, Experience>{};
  int _id;
  int _selectedChildId;
  int _value = 0;

  Experience() {
    _id = _nextId++;
  }

  @override
  StatefulScope get activeChildScope => _children[_selectedChildId];

  @override
  ScopeState get currentState =>
      new ScopeState('experience', _id.toString())..set('value', _value);

  Stream<Null> get triggerStream => _triggerController.stream;

  void embed(Experience experience) {
    addChild(experience);
    experience.triggerStream.listen((_) {
      trigger();
    });
    _children[experience._id] = experience;
  }

  @override
  Future<Null> onAcceptState(AcceptStateEvent event) async {
    _value = event.proposedState.getInt('value');
  }

  final List<StreamSubscription> _subs = [];

  void cancel() {
    _children.forEach((_, experience) {
      experience.cancel();
    });
    _subs.forEach((sub) {
      sub.cancel();
    });
    _subs.clear();
  }

  void trigger() {
    announceState();
    _triggerController.add(null);
  }

  void render(Element container, [int level = 0]) {
    container.className += ' level-$level';

    if (level == 0) {
      container.className += ' selected';
    }

    _subs.add(container.onClick.listen((event) {
      event.stopPropagation();

      // Child selection
      _selectedChildId = null;

      trigger();
    }));

    _subs.add(container.onMouseWheel.listen((event) {
      event.stopPropagation();
    }));

    var body = new DivElement()..className = 'body';

    _subs.add(body.onMouseWheel.listen((event) {
      event.stopPropagation();

      // Value
      _value = _value + event.deltaY;

      trigger();
    }));

    var content = new DivElement()
      ..className = 'content'
      ..appendText('I am experience $_id and my value is $_value');
    body.append(content);

    _children.forEach((id, experience) {
      var childContainer = new DivElement()
        ..className = 'container embedded';

        _subs.add(childContainer.onClick.listen((event) {
          event.stopPropagation();

          // Child selection
          _selectedChildId = id;

          trigger();
        }));

      if (_selectedChildId == id) {
        childContainer.className += ' selected';
      }

      experience.render(childContainer, level + 1);
      body.append(childContainer);
    });

    container.append(body);
  }
}

void setHash(StateStack stack) {
  var hash = '';

  while (!stack.isEmpty) {
    hash += '/';
    hash += stack.next.getInt('value').toString();
    stack = stack.popped();
  }

  window.location.hash = hash;
}

main() {
  var container = querySelector('#container');

  var parent = new Experience();

  parent.onStateAnnounced.listen((stack) {
    setHash(stack);
  });

  parent.triggerStream.listen((_) {
    parent.cancel();
    container.setInnerHtml('');
    parent.render(container);
  });

  var child0 = new Experience();

  parent..embed(child0);

  var grandchild0 = new Experience();
  var grandchild1 = new Experience();

  child0..embed(grandchild0)..embed(grandchild1);

  parent.render(container);

  setHash(parent.currentStateStack);
}
