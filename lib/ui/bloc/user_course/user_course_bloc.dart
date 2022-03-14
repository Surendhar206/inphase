import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:inject/inject.dart';
import 'package:masterstudy_app/data/cache/cache_manager.dart';
import 'package:masterstudy_app/data/models/CachedCourse.dart';
import 'package:masterstudy_app/data/repository/lesson_repository.dart';
import 'package:masterstudy_app/data/repository/user_course_repository.dart';
import './bloc.dart';

@provide
class UserCourseBloc extends Bloc<UserCourseEvent, UserCourseState> {
  final UserCourseRepository _repository;
  final LessonRepository _lessonsRepository;
  final CacheManager cacheManager;

  UserCourseState get initialState => InitialUserCourseState();

  UserCourseBloc(this._repository, this.cacheManager, this._lessonsRepository) : super(InitialUserCourseState()) {
    on<UserCourseEvent>((event, emit) async => await _userCourse(event, emit));
  }

  Future<void> _userCourse(UserCourseEvent event, Emitter<UserCourseState> emit) async {
    if (event is FetchEvent) {
      int courseId = int.parse(event.userCourseScreenArgs.course_id!);

      var isCached = await cacheManager.isCached(courseId);
      if (state is ErrorUserCourseState) emit(InitialUserCourseState());
      try {
        var response = await _repository.getCourseCurriculum(courseId);

        emit(LoadedUserCourseState(response.sections, response.progress_percent, response.current_lesson_id, response.lesson_type, response = response, await cacheManager.isCached(courseId), false));
        if (isCached) {
          print(event.userCourseScreenArgs.postsBean?.hash);
          var currentHash = (await cacheManager.getFromCache())?.courses.firstWhere((element) => courseId == element?.id)?.hash;
          print(currentHash);
          if (event.userCourseScreenArgs.postsBean?.hash != (await cacheManager.getFromCache())?.courses.firstWhere((element) => courseId == element?.id)?.hash) {
            mapCacheCourseEventToState(CacheCourseEvent(event.userCourseScreenArgs));
          }
        }
      } catch (e, s) {
        if (isCached) {
          var cache = await cacheManager.getFromCache();

          if (cache?.courses.firstWhere((element) => courseId == element?.id) != null) {
            var response = cache?.courses.firstWhere((element) => courseId == element?.id)?.curriculumResponse;

            emit(LoadedUserCourseState(
              response?.sections,
              response?.progress_percent,
              response?.current_lesson_id,
              response?.lesson_type,
              response = response,
              true,
              false,
            ));
          } else {
            emit(ErrorUserCourseState());
          }
        } else {
          emit(ErrorUserCourseState());
        }

        print(e);
        print(s);
      }
    }
    if (event is CacheCourseEvent) {
      mapCacheCourseEventToState(event);
    }
  }

  Future<UserCourseState> mapCacheCourseEventToState(CacheCourseEvent event) async {
    if (state is LoadedUserCourseState) {
      var state = this.state as LoadedUserCourseState;
      emit(LoadedUserCourseState(state.sections, state.progress, state.current_lesson_id, state.lesson_type, state.response, false, true));
      try {
        CachedCourse course = CachedCourse(
            id: int.parse(event.userCourseScreenArgs.course_id!),
            postsBean: event.userCourseScreenArgs.postsBean?..fromCache = true,
            curriculumResponse: (state as LoadedUserCourseState).response,
            hash: event.userCourseScreenArgs.hash!,
            lessons: []);

        var sections = (state as LoadedUserCourseState).response?.sections.map((e) => e?.section_items);
        List<int?> iDs = [];
        sections?.forEach((element) {
          element?.forEach((element) {
            iDs.add(element?.item_id);
          });
        });
        print(iDs.length);
        course.lessons = await _lessonsRepository.getAllLessons(int.parse(event.userCourseScreenArgs.course_id!), iDs);
        await cacheManager.writeToCache(course);
        emit(LoadedUserCourseState(state.sections, state.progress, state.current_lesson_id, state.lesson_type, state.response, true, false));
      } catch (e, s) {
        print(e);
        print(s);
        emit(LoadedUserCourseState(state.sections, state.progress, state.current_lesson_id, state.lesson_type, state.response, false, false));
      }
    }
    return mapCacheCourseEventToState(event);
  }
}
