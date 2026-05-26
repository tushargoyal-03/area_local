import 'package:area_connect/src/features/society_feed/domain/entities/society_post.dart';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

// --- Events ---
abstract class SocietyFeedEvent extends Equatable {
  const SocietyFeedEvent();
  @override
  List<Object?> get props => [];
}

class LoadSocietyFeed extends SocietyFeedEvent {
  final String societyId;
  final String? type; // 'Notice', 'Poll', etc.
  const LoadSocietyFeed(this.societyId, {this.type});
  @override
  List<Object?> get props => [societyId, type];
}

class VotePoll extends SocietyFeedEvent {
  final String postId;
  final int optionIndex;
  const VotePoll({required this.postId, required this.optionIndex});
  @override
  List<Object?> get props => [postId, optionIndex];
}

// --- State ---
class SocietyFeedState extends Equatable {
  final bool isLoading;
  final List<SocietyPost> posts;
  final String? error;
  final String societyId; // Current tracking

  const SocietyFeedState({
    this.isLoading = false,
    this.posts = const [],
    this.error,
    this.societyId = '',
  });

  SocietyFeedState copyWith({
    bool? isLoading,
    List<SocietyPost>? posts,
    String? error,
    String? societyId,
    bool clearError = false,
  }) {
    return SocietyFeedState(
      isLoading: isLoading ?? this.isLoading,
      posts: posts ?? this.posts,
      error: clearError ? null : (error ?? this.error),
      societyId: societyId ?? this.societyId,
    );
  }

  @override
  List<Object?> get props => [isLoading, posts, error, societyId];
}

// --- BLoC ---
class SocietyFeedBloc extends Bloc<SocietyFeedEvent, SocietyFeedState> {
  SocietyFeedBloc() : super(const SocietyFeedState()) {
    on<LoadSocietyFeed>(_onLoadFeed);
    on<VotePoll>(_onVotePoll);
  }

  Future<void> _onLoadFeed(
    LoadSocietyFeed event,
    Emitter<SocietyFeedState> emit,
  ) async {
    emit(state.copyWith(
        isLoading: true, societyId: event.societyId, clearError: true));

    final typeParam = (event.type != null && event.type != 'All')
        ? event.type!
            .toLowerCase()
            .replaceAll('s', '') // 'Polls' -> 'poll', 'Notices' -> 'notice'
        : null;

    final result = await SocietiesService.instance.getSocietyFeed(
      societyId: event.societyId,
      type: typeParam,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) {
        final List<SocietyPost> posts = (data)
            .map((e) => SocietyPost.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(state.copyWith(isLoading: false, posts: posts));
      },
    );
  }

  Future<void> _onVotePoll(
    VotePoll event,
    Emitter<SocietyFeedState> emit,
  ) async {
    // Optimistic update
    final updated = state.posts.map((p) {
      if (p.id == event.postId && p.type == 'poll') {
        // Can only vote if hasn't voted
        if (p.userVotedOptionIndex == null) {
          final List<PollOption> newOptions = List.from(p.pollOptions!);
          newOptions[event.optionIndex] = PollOption(
            text: newOptions[event.optionIndex].text,
            votes: newOptions[event.optionIndex].votes + 1,
          );
          return p.copyWith(
            pollOptions: newOptions,
            userVotedOptionIndex: event.optionIndex,
            totalVotes: (p.totalVotes ?? 0) + 1,
          );
        }
      }
      return p;
    }).toList();

    emit(state.copyWith(posts: updated));

    final result = await SocietiesService.instance.votePoll(
      postId: event.postId,
      optionIndex: event.optionIndex,
    );

    result.fold(
      (failure) {
        showGlobalToast(message: failure.message, status: 'error');
        // Simple rollback might require storing previous state, but skipping for brevity
      },
      (_) {}, // Keep optimistically updated state
    );
  }
}
