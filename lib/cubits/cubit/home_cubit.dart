import 'package:bloc/bloc.dart';
import 'package:ABRAR/services/data_usage_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  final TextEditingController limitController = TextEditingController();

  Future<void> getCurrentDataUsage() async {
    emit(GetCurrentDataUsageLoading());
    try {
      final dataUsage = await DataUsageService.getCurrentDataUsage();
      emit(GetCurrentDataUsageLoaded(dataUsage));
    } catch (e) {
      emit(GetCurrentDataUsageError(e.toString()));
    }
  }

  Future<void> getTodayDataUsage() async {
    emit(GetTodayDataUsageLoading());
    try {
      final dataUsage = await DataUsageService.getTodayDataUsage();
      emit(GetTodayDataUsageLoaded(dataUsage));
    } catch (e) {
      emit(GetTodayDataUsageError(e.toString()));
    }
  }

  Future<void> updateDataManually() async {
    emit(UpdateDataManuallyLoading());
    try {
      await DataUsageService.getCurrentDataUsage();
      await DataUsageService.getTodayDataUsage();
      emit(UpdateDataManuallyLoaded());
    } catch (e) {
      emit(UpdateDataManuallyError(e.toString()));
    }
  }

  Future<void> setDailyLimit() async {
    emit(SetDailyLimitLoading());
    try {
      final limitText = limitController.text.trim();
      final limit = double.tryParse(limitText);
      if (limit != null && limit > 0) {
        await DataUsageService.setDailyDataLimit(limit);
        emit(SetDailyLimitLoaded());
      }
    } catch (e) {
      emit(SetDailyLimitError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    limitController.dispose();
    return super.close();
  }
}
