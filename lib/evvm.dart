library evvm;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract interface class IViewModel {}

typedef ViewModelFactory<T extends ViewModel> = T Function(
  BuildContext context,
);

abstract class WidgetView<I extends IViewModel> extends Widget {
  final ViewModelFactory vmFactory;

  const WidgetView(
    this.vmFactory, {
    super.key,
  });

  @override
  Elementary createElement() {
    return Elementary(this);
  }

  Widget build(I vm, BuildContext context);
}

abstract class ViewModel<W extends WidgetView> with Diagnosticable implements IViewModel {
  @protected
  @visibleForTesting
  W get widget => _widget!;

  @protected
  @visibleForTesting
  BuildContext get context {
    assert(() {
      if (_element == null) {
        throw FlutterError('This widget has been unmounted');
      }
      return true;
    }());
    return _element!;
  }

  @protected
  @visibleForTesting
  bool get isMounted => _element != null;

  BuildContext? _element;
  W? _widget;

  ViewModel();

  @protected
  @mustCallSuper
  @visibleForTesting
  void init() {}

  @protected
  @visibleForTesting
  void didUpdateWidget(W oldWidget) {}

  @protected
  @visibleForTesting
  void didChangeDependencies() {}

  @protected
  @visibleForTesting
  void onErrorHandle(Object error) {}

  @protected
  @mustCallSuper
  @visibleForTesting
  void deactivate() {}

  @protected
  @mustCallSuper
  @visibleForTesting
  void activate() {}

  @protected
  @mustCallSuper
  @visibleForTesting
  void dispose() {}

  @protected
  @mustCallSuper
  @visibleForTesting
  void reassemble() {}

  @visibleForTesting
  void setupTestWidget(W? testWidget) {
    _widget = testWidget;
  }

  @visibleForTesting
  void setupTestElement(BuildContext? testElement) {
    _element = testElement;
  }

  @visibleForTesting
  void handleTestError(Object error) {
    onErrorHandle(error);
  }
}

final class Elementary extends ComponentElement {
  @override
  WidgetView get widget => super.widget as WidgetView;

  late ViewModel _vm;

  bool _isInitialized = false;

  Elementary(WidgetView super.widget);

  @override
  Widget build() {
    return widget.build(_vm, _vm.context);
  }

  @override
  void update(WidgetView newWidget) {
    super.update(newWidget);

    final oldWidget = _vm.widget;
    _vm
      .._widget = newWidget
      ..didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _vm.didChangeDependencies();
  }

  @override
  void activate() {
    super.activate();
    _vm.activate();

    markNeedsBuild();
  }

  @override
  void deactivate() {
    _vm.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();

    _vm
      ..dispose()
      .._element = null
      .._widget = null;
  }

  @override
  void performRebuild() {
    if (!_isInitialized) {
      _vm = widget.vmFactory(this);
      _vm
        .._element = this
        .._widget = widget
        ..init()
        ..didChangeDependencies();

      _isInitialized = true;
    }

    super.performRebuild();
  }

  @override
  void reassemble() {
    super.reassemble();

    _vm.reassemble();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(
      DiagnosticsProperty<ViewModel>(
        'widget model',
        _vm,
        defaultValue: null,
      ),
    );
  }
}

@visibleForTesting
mixin MockWidgetModelMixin<W extends WidgetView> implements ViewModel<W> {
  @override
  set _element(BuildContext? _) {}

  @override
  set _widget(W? _) {}
}
