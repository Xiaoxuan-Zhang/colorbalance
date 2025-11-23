// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BridgeEvent {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgeEvent&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'BridgeEvent(field0: $field0)';
}


}

/// @nodoc
class $BridgeEventCopyWith<$Res>  {
$BridgeEventCopyWith(BridgeEvent _, $Res Function(BridgeEvent) __);
}


/// Adds pattern-matching-related methods to [BridgeEvent].
extension BridgeEventPatterns on BridgeEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BridgeEvent_Status value)?  status,TResult Function( BridgeEvent_DebugImage value)?  debugImage,TResult Function( BridgeEvent_Result value)?  result,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BridgeEvent_Status() when status != null:
return status(_that);case BridgeEvent_DebugImage() when debugImage != null:
return debugImage(_that);case BridgeEvent_Result() when result != null:
return result(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BridgeEvent_Status value)  status,required TResult Function( BridgeEvent_DebugImage value)  debugImage,required TResult Function( BridgeEvent_Result value)  result,}){
final _that = this;
switch (_that) {
case BridgeEvent_Status():
return status(_that);case BridgeEvent_DebugImage():
return debugImage(_that);case BridgeEvent_Result():
return result(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BridgeEvent_Status value)?  status,TResult? Function( BridgeEvent_DebugImage value)?  debugImage,TResult? Function( BridgeEvent_Result value)?  result,}){
final _that = this;
switch (_that) {
case BridgeEvent_Status() when status != null:
return status(_that);case BridgeEvent_DebugImage() when debugImage != null:
return debugImage(_that);case BridgeEvent_Result() when result != null:
return result(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  status,TResult Function( Uint8List field0)?  debugImage,TResult Function( MobileResult field0)?  result,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BridgeEvent_Status() when status != null:
return status(_that.field0);case BridgeEvent_DebugImage() when debugImage != null:
return debugImage(_that.field0);case BridgeEvent_Result() when result != null:
return result(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  status,required TResult Function( Uint8List field0)  debugImage,required TResult Function( MobileResult field0)  result,}) {final _that = this;
switch (_that) {
case BridgeEvent_Status():
return status(_that.field0);case BridgeEvent_DebugImage():
return debugImage(_that.field0);case BridgeEvent_Result():
return result(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  status,TResult? Function( Uint8List field0)?  debugImage,TResult? Function( MobileResult field0)?  result,}) {final _that = this;
switch (_that) {
case BridgeEvent_Status() when status != null:
return status(_that.field0);case BridgeEvent_DebugImage() when debugImage != null:
return debugImage(_that.field0);case BridgeEvent_Result() when result != null:
return result(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class BridgeEvent_Status extends BridgeEvent {
  const BridgeEvent_Status(this.field0): super._();
  

@override final  String field0;

/// Create a copy of BridgeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgeEvent_StatusCopyWith<BridgeEvent_Status> get copyWith => _$BridgeEvent_StatusCopyWithImpl<BridgeEvent_Status>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgeEvent_Status&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'BridgeEvent.status(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $BridgeEvent_StatusCopyWith<$Res> implements $BridgeEventCopyWith<$Res> {
  factory $BridgeEvent_StatusCopyWith(BridgeEvent_Status value, $Res Function(BridgeEvent_Status) _then) = _$BridgeEvent_StatusCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$BridgeEvent_StatusCopyWithImpl<$Res>
    implements $BridgeEvent_StatusCopyWith<$Res> {
  _$BridgeEvent_StatusCopyWithImpl(this._self, this._then);

  final BridgeEvent_Status _self;
  final $Res Function(BridgeEvent_Status) _then;

/// Create a copy of BridgeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(BridgeEvent_Status(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BridgeEvent_DebugImage extends BridgeEvent {
  const BridgeEvent_DebugImage(this.field0): super._();
  

@override final  Uint8List field0;

/// Create a copy of BridgeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgeEvent_DebugImageCopyWith<BridgeEvent_DebugImage> get copyWith => _$BridgeEvent_DebugImageCopyWithImpl<BridgeEvent_DebugImage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgeEvent_DebugImage&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'BridgeEvent.debugImage(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $BridgeEvent_DebugImageCopyWith<$Res> implements $BridgeEventCopyWith<$Res> {
  factory $BridgeEvent_DebugImageCopyWith(BridgeEvent_DebugImage value, $Res Function(BridgeEvent_DebugImage) _then) = _$BridgeEvent_DebugImageCopyWithImpl;
@useResult
$Res call({
 Uint8List field0
});




}
/// @nodoc
class _$BridgeEvent_DebugImageCopyWithImpl<$Res>
    implements $BridgeEvent_DebugImageCopyWith<$Res> {
  _$BridgeEvent_DebugImageCopyWithImpl(this._self, this._then);

  final BridgeEvent_DebugImage _self;
  final $Res Function(BridgeEvent_DebugImage) _then;

/// Create a copy of BridgeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(BridgeEvent_DebugImage(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc


class BridgeEvent_Result extends BridgeEvent {
  const BridgeEvent_Result(this.field0): super._();
  

@override final  MobileResult field0;

/// Create a copy of BridgeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BridgeEvent_ResultCopyWith<BridgeEvent_Result> get copyWith => _$BridgeEvent_ResultCopyWithImpl<BridgeEvent_Result>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BridgeEvent_Result&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'BridgeEvent.result(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $BridgeEvent_ResultCopyWith<$Res> implements $BridgeEventCopyWith<$Res> {
  factory $BridgeEvent_ResultCopyWith(BridgeEvent_Result value, $Res Function(BridgeEvent_Result) _then) = _$BridgeEvent_ResultCopyWithImpl;
@useResult
$Res call({
 MobileResult field0
});




}
/// @nodoc
class _$BridgeEvent_ResultCopyWithImpl<$Res>
    implements $BridgeEvent_ResultCopyWith<$Res> {
  _$BridgeEvent_ResultCopyWithImpl(this._self, this._then);

  final BridgeEvent_Result _self;
  final $Res Function(BridgeEvent_Result) _then;

/// Create a copy of BridgeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(BridgeEvent_Result(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as MobileResult,
  ));
}


}

// dart format on
