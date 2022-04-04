import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:inject/inject.dart';
import 'package:masterstudy_app/data/models/LessonResponse.dart';
import 'package:masterstudy_app/data/repository/lesson_repository.dart';

import './bloc.dart';

@provide
class LessonVideoBloc extends Bloc<LessonVideoEvent, LessonVideoState> {
  final LessonRepository _lessonRepository;

  LessonVideoState get initialState => InitialLessonVideoState();

  LessonVideoBloc(this._lessonRepository) : super(InitialLessonVideoState()) {
    on<LessonVideoEvent>((event, emit) async {
      await _lessonVideo(event, emit);
    });
  }

  Future<void> _lessonVideo(LessonVideoEvent event, Emitter<LessonVideoState> emit) async {
    if (event is FetchEvent) {
      try {
        LessonResponse response = await _lessonRepository.getLesson(event.courseId, event.lessonId);

        emit(LoadedLessonVideoState(response));
      } on DioError catch(e) {
      }
    } else if (event is CompleteLessonEvent) {
      try {
        var response = await _lessonRepository.completeLesson(event.courseId, event.lessonId);
      } catch (e, s) {
        log(e.toString());
        print(e);
        print(s);
      }
    }
  }
}
