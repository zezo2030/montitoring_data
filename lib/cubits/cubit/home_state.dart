part of 'home_cubit.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeInitial extends HomeState {}

//=======================
// get current data usage
final class GetCurrentDataUsageLoading extends HomeState {}

final class GetCurrentDataUsageLoaded extends HomeState {
  final double dataUsage;
  const GetCurrentDataUsageLoaded(this.dataUsage);
}

final class GetCurrentDataUsageError extends HomeState {
  final String message;
  const GetCurrentDataUsageError(this.message);
}
//=======================

// get today data usage
final class GetTodayDataUsageLoading extends HomeState {}

final class GetTodayDataUsageLoaded extends HomeState {
  final double dataUsage;
  const GetTodayDataUsageLoaded(this.dataUsage);
}

final class GetTodayDataUsageError extends HomeState {
  final String message;
  const GetTodayDataUsageError(this.message);
}
//=======================

// update data manualy
final class UpdateDataManuallyLoading extends HomeState {}

final class UpdateDataManuallyLoaded extends HomeState {}

final class UpdateDataManuallyError extends HomeState {
  final String message;
  const UpdateDataManuallyError(this.message);
}
//=======================

// set daily limit
final class SetDailyLimitLoading extends HomeState {}

final class SetDailyLimitLoaded extends HomeState {}

final class SetDailyLimitError extends HomeState {
  final String message;
  const SetDailyLimitError(this.message);
}
//=======================
