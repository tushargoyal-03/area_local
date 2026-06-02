import 'package:area_connect/src/features/society_feed/domain/entities/society_post.dart';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

// --- Events ---
abstract class SocietyFeedEvent extends Equatable {
  const SocietyFeedEvent();
  @override
  List<Object?> get props => [];
}

/// Fetches the user's societies from the API, then loads the first society's feed.
class InitSocietyFeed extends SocietyFeedEvent {
  const InitSocietyFeed();
}

/// Creates a brand-new society. The current SocietyAdmin becomes its admin.
class CreateSocietyRequested extends SocietyFeedEvent {
  final String name;
  final String address;
  final String city;
  final List<double> coordinates; // [lng, lat]
  final String? description;
  final VoidCallback? onSuccess;

  const CreateSocietyRequested({
    required this.name,
    required this.address,
    required this.city,
    required this.coordinates,
    this.description,
    this.onSuccess,
  });

  @override
  List<Object?> get props => [name, address, city, coordinates, description];
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

class LikePost extends SocietyFeedEvent {
  final String postId;
  const LikePost({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class UpvoteComplaint extends SocietyFeedEvent {
  final String postId;
  const UpvoteComplaint({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class CreateSocietyPostRequested extends SocietyFeedEvent {
  final String societyId;
  final String type;
  final String title;
  final String content;
  final String? eventDate;
  final VoidCallback? onSuccess;

  const CreateSocietyPostRequested({
    required this.societyId,
    required this.type,
    required this.title,
    required this.content,
    this.eventDate,
    this.onSuccess,
  });

  @override
  List<Object?> get props => [societyId, type, title, content, eventDate];
}

class CreatePollRequested extends SocietyFeedEvent {
  final String societyId;
  final String title;
  final String content;
  final List<String> options;
  final VoidCallback? onSuccess;

  const CreatePollRequested({
    required this.societyId,
    required this.title,
    required this.content,
    required this.options,
    this.onSuccess,
  });

  @override
  List<Object?> get props => [societyId, title, content, options];
}

// --- State ---
class SocietyFeedState extends Equatable {
  final bool isLoading;
  final List<SocietyPost> posts;
  final String? error;
  final String societyId;
  final String societyName;
  final bool isCreating;
  final bool hasNoSociety;
  final bool isCreatingSociety;

  const SocietyFeedState({
    this.isLoading = false,
    this.posts = const [],
    this.error,
    this.societyId = '',
    this.societyName = '',
    this.isCreating = false,
    this.hasNoSociety = false,
    this.isCreatingSociety = false,
  });

  SocietyFeedState copyWith({
    bool? isLoading,
    List<SocietyPost>? posts,
    String? error,
    String? societyId,
    String? societyName,
    bool? isCreating,
    bool? hasNoSociety,
    bool? isCreatingSociety,
    bool clearError = false,
  }) {
    return SocietyFeedState(
      isLoading: isLoading ?? this.isLoading,
      posts: posts ?? this.posts,
      error: clearError ? null : (error ?? this.error),
      societyId: societyId ?? this.societyId,
      societyName: societyName ?? this.societyName,
      isCreating: isCreating ?? this.isCreating,
      hasNoSociety: hasNoSociety ?? this.hasNoSociety,
      isCreatingSociety: isCreatingSociety ?? this.isCreatingSociety,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        posts,
        error,
        societyId,
        societyName,
        isCreating,
        hasNoSociety,
        isCreatingSociety,
      ];
}

// --- BLoC ---
class SocietyFeedBloc extends Bloc<SocietyFeedEvent, SocietyFeedState> {
  SocietyFeedBloc() : super(const SocietyFeedState()) {
    on<InitSocietyFeed>(_onInitFeed);
    on<CreateSocietyRequested>(_onCreateSociety);
    on<LoadSocietyFeed>(_onLoadFeed);
    on<VotePoll>(_onVotePoll);
    on<LikePost>(_onLikePost);
    on<UpvoteComplaint>(_onUpvoteComplaint);
    on<CreateSocietyPostRequested>(_onCreatePost);
    on<CreatePollRequested>(_onCreatePoll);
  }

  Future<void> _onInitFeed(
    InitSocietyFeed event,
    Emitter<SocietyFeedState> emit,
  ) async {
    emit(
        state.copyWith(isLoading: true, clearError: true, hasNoSociety: false));

    final result = await SocietiesService.instance.getMySocieties();
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (societies) {
        if (societies.isEmpty) {
          emit(state.copyWith(
            isLoading: false,
            hasNoSociety: true,
          ));
          return;
        }
        final first = societies[0] as Map<String, dynamic>;
        final id = (first['_id'] ?? first['id'] ?? '').toString();
        final name = (first['name'] ?? 'My Society').toString();
        emit(state.copyWith(
            societyId: id, societyName: name, hasNoSociety: false));
        // Now load the feed for this society
        add(LoadSocietyFeed(id, type: 'All'));
      },
    );
  }

  Future<void> _onCreateSociety(
    CreateSocietyRequested event,
    Emitter<SocietyFeedState> emit,
  ) async {
    emit(state.copyWith(isCreatingSociety: true, clearError: true));

    final result = await SocietiesService.instance.createSociety(
      name: event.name,
      address: event.address,
      city: event.city,
      coordinates: event.coordinates,
      description: event.description,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isCreatingSociety: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (society) {
        final id = (society['_id'] ?? society['id'] ?? '').toString();
        final name = (society['name'] ?? event.name).toString();
        emit(state.copyWith(
          isCreatingSociety: false,
          hasNoSociety: false,
          societyId: id,
          societyName: name,
        ));
        showGlobalToast(
            message: 'Society "$name" created successfully!',
            status: 'success');
        if (event.onSuccess != null) event.onSuccess!();
        if (id.isNotEmpty) {
          add(LoadSocietyFeed(id, type: 'All'));
        } else {
          // Fallback: refresh membership list if the API didn't echo an id.
          add(const InitSocietyFeed());
        }
      },
    );
  }

  Future<void> _onLoadFeed(
    LoadSocietyFeed event,
    Emitter<SocietyFeedState> emit,
  ) async {
    emit(state.copyWith(
        isLoading: true, societyId: event.societyId, clearError: true));

    // API expects capitalized singular type: Notice, Alert, Complaint, Event, Poll
    const typeMapping = {
      'Notices': 'Notice',
      'Alerts': 'Alert',
      'Complaints': 'Complaint',
      'Events': 'Event',
      'Polls': 'Poll',
    };
    final typeParam = (event.type != null && event.type != 'All')
        ? typeMapping[event.type!] ?? event.type!
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
      if (p.id == event.postId && p.type.toLowerCase() == 'poll') {
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

  Future<void> _onLikePost(
    LikePost event,
    Emitter<SocietyFeedState> emit,
  ) async {
    // Optimistic update
    final updated = state.posts.map((p) {
      if (p.id == event.postId) {
        return p.copyWith(likesCount: p.likesCount + 1);
      }
      return p;
    }).toList();
    emit(state.copyWith(posts: updated));

    final result = await SocietiesService.instance.likePost(event.postId);
    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (_) {},
    );
  }

  Future<void> _onUpvoteComplaint(
    UpvoteComplaint event,
    Emitter<SocietyFeedState> emit,
  ) async {
    final updated = state.posts.map((p) {
      if (p.id == event.postId && p.type.toLowerCase() == 'complaint') {
        return p.copyWith(likesCount: p.likesCount + 1);
      }
      return p;
    }).toList();
    emit(state.copyWith(posts: updated));

    final result =
        await SocietiesService.instance.upvoteComplaint(event.postId);
    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (_) {},
    );
  }

  Future<void> _onCreatePost(
    CreateSocietyPostRequested event,
    Emitter<SocietyFeedState> emit,
  ) async {
    emit(state.copyWith(isCreating: true));
    final result = await SocietiesService.instance.createSocietyPost(
      societyId: event.societyId,
      type: event.type,
      title: event.title,
      content: event.content,
      eventDate: event.eventDate,
    );
    result.fold(
      (failure) {
        emit(state.copyWith(isCreating: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (newPost) {
        emit(state.copyWith(isCreating: false));
        showGlobalToast(message: 'Post created!', status: 'success');
        if (event.onSuccess != null) event.onSuccess!();
        // Reload feed
        add(LoadSocietyFeed(event.societyId));
      },
    );
  }

  Future<void> _onCreatePoll(
    CreatePollRequested event,
    Emitter<SocietyFeedState> emit,
  ) async {
    emit(state.copyWith(isCreating: true));
    final result = await SocietiesService.instance.createPoll(
      societyId: event.societyId,
      title: event.title,
      content: event.content,
      options: event.options,
    );
    result.fold(
      (failure) {
        emit(state.copyWith(isCreating: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        emit(state.copyWith(isCreating: false));
        showGlobalToast(message: 'Poll created!', status: 'success');
        if (event.onSuccess != null) event.onSuccess!();
        add(LoadSocietyFeed(event.societyId));
      },
    );
  }
}
