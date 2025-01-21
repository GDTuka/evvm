import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Publisher that uses [EntityState] to describe concrete state of stored data.
class EntityStateNotifier<T> extends ValueNotifier<EntityState<T>> implements EntityValueListenable<T> {
  /// Creates an instance of [EntityStateNotifier].
  EntityStateNotifier([EntityState<T>? initialData]) : super(initialData ?? EntityState<T>.content());

  /// Creates an instance of [EntityStateNotifier] with initial value.
  EntityStateNotifier.value(T initialData)
      : super(
          EntityState<T>.content(initialData),
        );

  /// Sets current state to content.
  void content(T data) {
    value = EntityState<T>.content(data);
  }

  /// Sets current state to error.
  void error([Exception? exception, T? data]) {
    value = EntityState<T>.error(exception, data);
  }

  /// Sets current state to loading.
  void loading([T? previousData]) {
    value = EntityState<T>.loading(previousData);
  }
}

/// Describes the state of the stored value. It can be helpful when
/// interacting with values over the network or other options involving
/// long asynchronous operations.
///
/// It can be in one of three possible states:
/// ## Loading
/// This state indicates that the value is currently being loaded.
/// This state doesn't exclude the existence of a value while the actual value
/// is being in loading, such as the previous value.
/// Concrete implementation for this state is [LoadingEntityState].
/// ## error
/// This state indicates that there is a problem with the value,
/// such as an exception occurring during the loading process.
/// This state doesn't exclude the existence of a value, for example
/// it can refer to the previous value, but emphasizes the presence of problems.
/// Concrete implementation for this state is [ErrorEntityState].
/// ## content
/// This state means some value is stored, without highlight additional aspects.
/// Concrete implementation for this state is [ContentEntityState].
sealed class EntityState<T> {
  /// Data of entity.
  final T? data;

  /// Create an instance of EntityState.
  const EntityState({
    this.data,
  });

  /// Loading constructor.
  factory EntityState.loading([T? data]) {
    return LoadingEntityState<T>(data: data);
  }

  /// Error constructor.
  factory EntityState.error([Exception? error, T? data]) {
    return ErrorEntityState<T>(error: error, data: data);
  }

  /// Content constructor.
  factory EntityState.content([T? data]) {
    return ContentEntityState<T>(data: data);
  }

  /// Is it error state.
  bool get isErrorState => switch (this) {
        ErrorEntityState<T>() => true,
        _ => false,
      };

  /// Is it error state.
  bool get isLoadingState => switch (this) {
        LoadingEntityState<T>() => true,
        _ => false,
      };

  /// Returns error if exist or null otherwise.
  Exception? get errorOrNull => switch (this) {
        final ErrorEntityState<T> errorState => errorState.error,
        _ => null,
      };
}

/// Entity that describes general state of data storing.
final class ContentEntityState<T> extends EntityState<T> {
  /// Creates an instance of [ContentEntityState].
  const ContentEntityState({super.data});
}

/// Entity that describes state of loading data or long interaction.
final class LoadingEntityState<T> extends ContentEntityState<T> {
  /// Creates an instance of [LoadingEntityState].
  const LoadingEntityState({super.data});
}

/// Entity that describes state with data problems.
final class ErrorEntityState<T> extends ContentEntityState<T> {
  /// Describes exact problems with data
  final Exception? error;

  /// Creates an instance of [ErrorEntityState].
  const ErrorEntityState({this.error, super.data});
}

/// Alias for [EntityStateNotifier] interface.
///
/// Can be useful for simplify description of Widget Model interface.
abstract interface class EntityValueListenable<T> implements ValueListenable<EntityState<T>> {}

/// Double Entity State Notifier Builder for situations when need to listen for 2 entities
///
/// if one of two entities changes, for [loading] of [error] state, whole widget will change
///
/// if one on entities has [loading] of [error] state, whole widget will be [loading] or [error]
class DoubleEntityStateNotifierBuilder<F, S> extends StatefulWidget {
  /// First listenable
  final ValueListenable<EntityState<F>> firstListenable;

  /// Second listenable
  final ValueListenable<EntityState<S>> secondListenable;

  /// Builder that used for the loading state.
  ///
  /// See also:
  /// * [EntityState]
  /// * [LoadingEntityState]
  final DoubleLoadingBuilder<F, S>? multiLoadingBuilder;

  /// Builder that used for the error state.
  ///
  /// See also:
  /// * [EntityState]
  /// * [LoadingEntityState]
  final DoubleErrorWidgetBuilder<F, S>? errorBuilder;

  final DoubleDataWidgetBuilder<F, S> builder;

  const DoubleEntityStateNotifierBuilder({
    super.key,
    required this.firstListenable,
    required this.secondListenable,
    required this.builder,
    this.multiLoadingBuilder,
    this.errorBuilder,
  });

  @override
  State<DoubleEntityStateNotifierBuilder<F, S>> createState() => DoubleEntityStateNotifierBuilderState<F, S>();
}

class DoubleEntityStateNotifierBuilderState<F, S> extends State<DoubleEntityStateNotifierBuilder<F, S>> {
  late EntityState<F> _firstValue;
  late EntityState<S> _secondValue;

  @override
  void initState() {
    super.initState();

    _firstValue = widget.firstListenable.value;
    widget.firstListenable.addListener(_firstValueListenableChange);

    _secondValue = widget.secondListenable.value;
    widget.secondListenable.addListener(_secondValueListenableChange);
  }

  void _firstValueListenableChange() {
    setState(() {
      _firstValue = widget.firstListenable.value;
    });
  }

  void _secondValueListenableChange() {
    setState(() {
      _secondValue = widget.secondListenable.value;
    });
  }

  @override
  void didUpdateWidget(covariant DoubleEntityStateNotifierBuilder<F, S> oldWidget) {
    if (oldWidget.firstListenable != widget.firstListenable) {
      oldWidget.firstListenable.removeListener(_firstValueListenableChange);
      _firstValue = widget.firstListenable.value;
    }
    if (oldWidget.secondListenable != widget.secondListenable) {
      oldWidget.secondListenable.removeListener(_secondValueListenableChange);
      _secondValue = widget.secondListenable.value;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.firstListenable.removeListener(_firstValueListenableChange);
    widget.secondListenable.removeListener(_secondValueListenableChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ((_firstValue.isErrorState || _secondValue.isErrorState) && widget.errorBuilder != null) {
      return widget.errorBuilder!(
        context,
        _firstValue.data,
        _secondValue.data,
        _firstValue.errorOrNull,
        _secondValue.errorOrNull,
      );
    }
    if ((_firstValue.isLoadingState || _secondValue.isLoadingState) && widget.multiLoadingBuilder != null) {
      return widget.multiLoadingBuilder!(
        context,
        _firstValue.data,
        _secondValue.data,
      );
    }
    return widget.builder(context, _firstValue.data, _secondValue.data);
  }
}

typedef DoubleDataWidgetBuilder<F, S> = Widget Function(
  BuildContext context,
  F? firstData,
  S? secondData,
);

typedef DoubleLoadingBuilder<F, S> = Widget Function(
  BuildContext context,
  F? firstData,
  S? secondData,
);

typedef DoubleErrorWidgetBuilder<F, S> = Widget Function(
  BuildContext context,
  F? firstData,
  S? secondData,
  Exception? firstE,
  Exception? secondE,
);

/// Tripl Entity State Notifier Builder is for situation when u need to listen for 3 entities
///
/// if one of 3 entities changes, for [loading] of [error] state, whole widget will change
///
/// if one of 3 entities has [loading] of [error] state, whole widget will be [loading] or [error]
///
/// if one of entities accept new [content] whole widget will rebuild
class TripleEntityStateNotifierBuilder<F, S, T> extends StatefulWidget {
  const TripleEntityStateNotifierBuilder({
    super.key,
    required this.firstListenable,
    required this.secondListenable,
    required this.thirdListenable,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final ValueListenable<EntityState<F>> firstListenable;

  final ValueListenable<EntityState<S>> secondListenable;

  final ValueListenable<EntityState<T>> thirdListenable;

  final TriplDataWidgetBuilder<F, S, T> builder;

  final TriplLoadingBuilder<F, S, T>? loadingBuilder;

  final TriplErrorWidgetBuilder<F, S, T>? errorBuilder;

  @override
  State<TripleEntityStateNotifierBuilder<F, S, T>> createState() => _TripleEntityStateNotifierBuilderState<F, S, T>();
}

class _TripleEntityStateNotifierBuilderState<F, S, T> extends State<TripleEntityStateNotifierBuilder<F, S, T>> {
  late EntityState<F> _firstValue;
  late EntityState<S> _secondValue;
  late EntityState<T> _thirdValue;

  void _firstValueListenableChange() {
    setState(() {
      _firstValue = widget.firstListenable.value;
    });
  }

  void _secondValueListenableChange() {
    setState(() {
      _secondValue = widget.secondListenable.value;
    });
  }

  void _thirdValueListenableChange() {
    setState(() {
      _thirdValue = widget.thirdListenable.value;
    });
  }

  @override
  void initState() {
    super.initState();
    _firstValue = widget.firstListenable.value;
    widget.firstListenable.addListener(_firstValueListenableChange);
    _secondValue = widget.secondListenable.value;
    widget.secondListenable.addListener(_secondValueListenableChange);
    _thirdValue = widget.thirdListenable.value;
    widget.thirdListenable.addListener(_thirdValueListenableChange);
  }

  @override
  void dispose() {
    widget.firstListenable.removeListener(_firstValueListenableChange);
    widget.secondListenable.removeListener(_secondValueListenableChange);
    widget.thirdListenable.removeListener(_thirdValueListenableChange);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TripleEntityStateNotifierBuilder<F, S, T> oldWidget) {
    if (oldWidget.firstListenable != widget.firstListenable) {
      oldWidget.firstListenable.removeListener(_firstValueListenableChange);
      _firstValue = widget.firstListenable.value;
    }
    if (oldWidget.secondListenable != widget.secondListenable) {
      oldWidget.secondListenable.removeListener(_secondValueListenableChange);
      _secondValue = widget.secondListenable.value;
    }
    if (oldWidget.thirdListenable != widget.thirdListenable) {
      oldWidget.thirdListenable.removeListener(_thirdValueListenableChange);
      _thirdValue = widget.thirdListenable.value;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if ((_firstValue.isErrorState || _secondValue.isErrorState || _thirdValue.isErrorState) &&
        widget.errorBuilder != null) {
      return widget.errorBuilder!(
        context,
        _firstValue.data,
        _secondValue.data,
        _thirdValue.data,
        _firstValue.errorOrNull,
        _secondValue.errorOrNull,
        _thirdValue.errorOrNull,
      );
    }
    if ((_firstValue.isLoadingState || _secondValue.isLoadingState || _thirdValue.isLoadingState) &&
        widget.loadingBuilder != null) {
      return widget.loadingBuilder!(
        context,
        _firstValue.data,
        _secondValue.data,
        _thirdValue.data,
      );
    }
    return widget.builder(
      context,
      _firstValue.data,
      _secondValue.data,
      _thirdValue.data,
    );
  }
}

typedef TriplDataWidgetBuilder<F, S, T> = Widget Function(
  BuildContext context,
  F? firstData,
  S? secondData,
  T? thirdData,
);

typedef TriplLoadingBuilder<F, S, T> = Widget Function(
  BuildContext context,
  F? firstData,
  S? secondData,
  T? thirdData,
);

typedef TriplErrorWidgetBuilder<F, S, T> = Widget Function(
  BuildContext context,
  F? firstData,
  S? secondData,
  T? thirdData,
  Exception? firstE,
  Exception? secondE,
  Exception? thirdE,
);

/// A builder that uses [ValueListenable] parameterized by [EntityState] as
/// a source of data.
/// This builder is usually helpful with the [EntityStateNotifier].
///
/// This builder supports three possible builder functions:
///
/// * [errorBuilder] - used when [listenableEntityState] value
/// represents an error state of [EntityState.error].
/// * [loadingBuilder] - used when [listenableEntityState] value represents
/// a loading state of [EntityState.loading].
/// * [builder] - the default builder that encompasses the previous two
/// cases when [errorBuilder] and [loadingBuilder] are not set,
/// and is used for the content state of [EntityState].
class EntityStateNotifierBuilder<T> extends StatelessWidget {
  /// Source that used to detect change and rebuild.
  final ValueListenable<EntityState<T>> listenableEntityState;

  /// Default builder that is used for the content state and all other states if
  /// no special builders are specified.
  final DataWidgetBuilder<T> builder;

  /// Builder that used for the loading state.
  ///
  /// See also:
  /// * [EntityState]
  /// * [LoadingEntityState]
  final LoadingWidgetBuilder<T>? loadingBuilder;

  /// Builder that used for the error state.
  ///
  /// See also:
  /// * [EntityState]
  /// * [LoadingEntityState]
  final ErrorWidgetBuilder<T>? errorBuilder;

  /// Creates an instance of [EntityStateNotifierBuilder].
  const EntityStateNotifierBuilder({
    super.key,
    required this.listenableEntityState,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EntityState<T>>(
      valueListenable: listenableEntityState,
      builder: (ctx, entity, _) {
        final eBuilder = errorBuilder;
        if (entity.isErrorState && eBuilder != null) {
          return eBuilder(ctx, entity.errorOrNull, entity.data);
        }

        final lBuilder = loadingBuilder;
        if (entity.isLoadingState && lBuilder != null) {
          return lBuilder(ctx, entity.data);
        }

        return builder(ctx, entity.data);
      },
    );
  }
}

/// Builder function for loading state.
///
/// See also:
/// * [EntityState] - State of some logical entity.
typedef LoadingWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T? data,
);

/// Builder function for content state.
///
/// See also:
/// * [EntityState] - State of some logical entity.
typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T? data);

/// Builder function for error state.
///
/// See also:
/// * [EntityState] - State of some logical entity.
typedef ErrorWidgetBuilder<T> = Widget Function(
  BuildContext context,
  Exception? e,
  T? data,
);
