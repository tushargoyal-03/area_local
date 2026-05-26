import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../../domain/repositories/posts_repository.dart';

// --- Events ---
abstract class PostsEvent extends Equatable {
  const PostsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNearbyPostsRequested extends PostsEvent {
  final double lng;
  final double lat;
  final double radiusInKm;
  const LoadNearbyPostsRequested({
    required this.lng,
    required this.lat,
    this.radiusInKm = 5,
  });

  @override
  List<Object?> get props => [lng, lat, radiusInKm];
}

class CreatePostRequested extends PostsEvent {
  final BuildContext context;
  final String category;
  final String title;
  final String content;
  final List<double> coordinates;
  const CreatePostRequested({
    required this.context,
    required this.category,
    required this.title,
    required this.content,
    required this.coordinates,
  });

  @override
  List<Object?> get props => [category, title, content, coordinates];
}

class ToggleInterestRequested extends PostsEvent {
  final String postId;
  final String currentUserId;
  const ToggleInterestRequested({
    required this.postId,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [postId, currentUserId];
}

class AddCommentRequested extends PostsEvent {
  final String postId;
  final String content;
  final VoidCallback? onSuccess;
  const AddCommentRequested({
    required this.postId,
    required this.content,
    this.onSuccess,
  });

  @override
  List<Object?> get props => [postId, content];
}

class DeletePostRequested extends PostsEvent {
  final String postId;
  const DeletePostRequested({required this.postId});

  @override
  List<Object?> get props => [postId];
}

// --- States ---
class PostsState extends Equatable {
  final List<AppPost> posts;
  final bool isLoading;
  final String? errorMessage;
  final bool isCreating;
  final bool createSuccess;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isCreating = false,
    this.createSuccess = false,
  });

  PostsState copyWith({
    List<AppPost>? posts,
    bool? isLoading,
    String? errorMessage,
    bool? isCreating,
    bool? createSuccess,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset if not explicitly passed
      isCreating: isCreating ?? this.isCreating,
      createSuccess: createSuccess ?? this.createSuccess,
    );
  }

  @override
  List<Object?> get props => [posts, isLoading, errorMessage, isCreating, createSuccess];
}

// --- Bloc ---
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsRepository _repository;

  PostsBloc({required PostsRepository repository})
      : _repository = repository,
        super(const PostsState()) {
    on<LoadNearbyPostsRequested>(_onLoadNearbyPosts);
    on<CreatePostRequested>(_onCreatePost);
    on<ToggleInterestRequested>(_onToggleInterest);
    on<AddCommentRequested>(_onAddComment);
    on<DeletePostRequested>(_onDeletePost);
  }

  Future<void> _onLoadNearbyPosts(
    LoadNearbyPostsRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.getNearbyFeed(
      lng: event.lng,
      lat: event.lat,
      radiusInKm: event.radiusInKm,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (posts) => emit(state.copyWith(isLoading: false, posts: posts)),
    );
  }

  Future<void> _onCreatePost(
    CreatePostRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, createSuccess: false));

    final result = await _repository.createPost(
      category: event.category,
      title: event.title,
      content: event.content,
      coordinates: event.coordinates,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isCreating: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (newPost) {
        emit(state.copyWith(
          isCreating: false,
          createSuccess: true,
          posts: [newPost, ...state.posts],
        ));
        showGlobalToast(message: 'Hyperlocal activity published successfully!', status: 'success');
        if (event.context.mounted) {
          Navigator.pop(event.context);
        }
      },
    );
  }

  Future<void> _onToggleInterest(
    ToggleInterestRequested event,
    Emitter<PostsState> emit,
  ) async {
    // Optimistically update the UI interest state
    final originalPosts = List<AppPost>.from(state.posts);
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId) {
        final currentInterested = List<String>.from(post.interestedUsers);
        final isNowInterested = !post.isInterested;
        
        if (isNowInterested) {
          currentInterested.add(event.currentUserId);
        } else {
          currentInterested.remove(event.currentUserId);
        }

        return post.copyWith(
          isInterested: isNowInterested,
          interestedUsers: currentInterested,
        );
      }
      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    // Make the API request
    final result = await _repository.toggleInterest(
      postId: event.postId,
      currentUserId: event.currentUserId,
    );

    result.fold(
      (failure) {
        // Revert optimistical update on error
        emit(state.copyWith(posts: originalPosts));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (updatedPostSkeleton) {
        // Make sure list count is exactly synchronized with server state
        final finalPosts = state.posts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(
              isInterested: updatedPostSkeleton.isInterested,
            );
          }
          return post;
        }).toList();
        emit(state.copyWith(posts: finalPosts));
      },
    );
  }

  Future<void> _onAddComment(
    AddCommentRequested event,
    Emitter<PostsState> emit,
  ) async {
    final result = await _repository.addComment(
      postId: event.postId,
      content: event.content,
    );

    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (comment) {
        // Increment comment count locally for that post
        final updatedPosts = state.posts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(commentsCount: post.commentsCount + 1);
          }
          return post;
        }).toList();

        emit(state.copyWith(posts: updatedPosts));
        showGlobalToast(message: 'Comment added successfully!', status: 'success');
        if (event.onSuccess != null) {
          event.onSuccess!();
        }
      },
    );
  }

  Future<void> _onDeletePost(
    DeletePostRequested event,
    Emitter<PostsState> emit,
  ) async {
    final originalPosts = List<AppPost>.from(state.posts);
    final updatedPosts = state.posts.where((post) => post.id != event.postId).toList();

    emit(state.copyWith(posts: updatedPosts));

    final result = await _repository.deletePost(postId: event.postId);

    result.fold(
      (failure) {
        emit(state.copyWith(posts: originalPosts));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        showGlobalToast(message: 'Activity removed successfully.', status: 'success');
      },
    );
  }
}
