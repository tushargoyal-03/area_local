import 'dart:io';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../../domain/repositories/posts_repository.dart';
import 'package:area_connect/src/features/auth/domain/entities/user.dart';

// --- Events ---
abstract class PostsEvent extends Equatable {
  const PostsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNearbyPostsRequested extends PostsEvent {
  final String? type;
  final String? category;

  const LoadNearbyPostsRequested({this.type, this.category});

  @override
  List<Object?> get props => [type, category];
}

class CreatePostRequested extends PostsEvent {
  final AppUser? currentUser;
  final String category;
  final String title;
  final String content;
  final List<double> coordinates;
  final File? image;
  final int? maxParticipants;
  final DateTime? eventTime;
  final void Function(AppPost newPost)? onSuccess;

  const CreatePostRequested({
    this.currentUser,
    required this.category,
    required this.title,
    required this.content,
    required this.coordinates,
    this.image,
    this.maxParticipants,
    this.eventTime,
    this.onSuccess,
  });

  @override
  List<Object?> get props => [
        currentUser,
        category,
        title,
        content,
        coordinates,
        image,
        maxParticipants,
        eventTime
      ];
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
  final VoidCallback? onFailure;
  const AddCommentRequested({
    required this.postId,
    required this.content,
    this.onSuccess,
    this.onFailure,
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

class LoadInterestedUsersRequested extends PostsEvent {
  final String postId;
  const LoadInterestedUsersRequested({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class AcceptInterestRequested extends PostsEvent {
  final String postId;
  final String targetUserId;
  const AcceptInterestRequested({
    required this.postId,
    required this.targetUserId,
  });

  @override
  List<Object?> get props => [postId, targetUserId];
}

class RejectInterestRequested extends PostsEvent {
  final String postId;
  final String targetUserId;
  const RejectInterestRequested({
    required this.postId,
    required this.targetUserId,
  });

  @override
  List<Object?> get props => [postId, targetUserId];
}

class ClosePostRequested extends PostsEvent {
  final String postId;
  const ClosePostRequested({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class SubmitReviewRequested extends PostsEvent {
  final String postId;
  final String targetUserId;
  final int rating;
  final String? comment;
  final VoidCallback? onSuccess;

  const SubmitReviewRequested({
    required this.postId,
    required this.targetUserId,
    required this.rating,
    this.comment,
    this.onSuccess,
  });

  @override
  List<Object?> get props => [postId, targetUserId, rating, comment];
}

// --- States ---
class PostsState extends Equatable {
  final List<AppPost> posts;
  final bool isLoading;
  final String? errorMessage;
  final bool isCreating;
  final bool createSuccess;
  final List<dynamic> interestedUsers;
  final bool isLoadingInterestedUsers;
  final bool isSubmittingAction;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isCreating = false,
    this.createSuccess = false,
    this.interestedUsers = const [],
    this.isLoadingInterestedUsers = false,
    this.isSubmittingAction = false,
  });

  PostsState copyWith({
    List<AppPost>? posts,
    bool? isLoading,
    String? errorMessage,
    bool? isCreating,
    bool? createSuccess,
    List<dynamic>? interestedUsers,
    bool? isLoadingInterestedUsers,
    bool? isSubmittingAction,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCreating: isCreating ?? this.isCreating,
      createSuccess: createSuccess ?? this.createSuccess,
      interestedUsers: interestedUsers ?? this.interestedUsers,
      isLoadingInterestedUsers:
          isLoadingInterestedUsers ?? this.isLoadingInterestedUsers,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        isLoading,
        errorMessage,
        isCreating,
        createSuccess,
        interestedUsers,
        isLoadingInterestedUsers,
        isSubmittingAction,
      ];
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
    on<LoadInterestedUsersRequested>(_onLoadInterestedUsers);
    on<AcceptInterestRequested>(_onAcceptInterest);
    on<RejectInterestRequested>(_onRejectInterest);
    on<ClosePostRequested>(_onClosePost);
    on<SubmitReviewRequested>(_onSubmitReview);
  }

  Future<void> _onLoadNearbyPosts(
    LoadNearbyPostsRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.getNearbyFeed(
      type: event.type,
      category: event.category,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (posts) => emit(state.copyWith(isLoading: false, posts: posts)),
    );
  }

  Future<void> _onCreatePost(
    CreatePostRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, createSuccess: false));

    final List<String> mediaUrls = [];
    if (event.image != null) {
      final uploadRes = await _repository.uploadImage(event.image!);
      bool uploadFailed = false;
      String? errorMsg;

      uploadRes.fold(
        (failure) {
          uploadFailed = true;
          errorMsg = failure.message;
        },
        (url) {
          mediaUrls.add(url);
        },
      );

      if (uploadFailed) {
        emit(state.copyWith(isCreating: false));
        showGlobalToast(
          message: 'Image upload failed: ${errorMsg ?? "Unknown error"}',
          status: 'error',
        );
        return;
      }
    }

    final result = await _repository.createPost(
      category: event.category,
      title: event.title,
      content: event.content,
      coordinates: event.coordinates,
      mediaUrls: mediaUrls,
      maxParticipants: event.maxParticipants,
      eventTime: event.eventTime?.toUtc().toIso8601String(),
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isCreating: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (newPost) {
        final currentUser = event.currentUser;
        final finalPost = newPost.copyWith(
          authorName: currentUser?.name ?? 'You',
          authorAvatar: currentUser?.photoUrl,
          authorRole: currentUser?.role ?? 'User',
        );

        emit(state.copyWith(
          isCreating: false,
          createSuccess: true,
          posts: [finalPost, ...state.posts],
        ));
        showGlobalToast(
            message: event.category.toLowerCase() == 'advertisement'
                ? 'Business advertisement published successfully!'
                : 'Hyperlocal activity published successfully!',
            status: 'success');

        if (event.onSuccess != null) {
          event.onSuccess!(finalPost);
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
        if (post.postType == 'promotion') {
          return post.copyWith(isSaved: !post.isSaved);
        }

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
    try {
      final post = originalPosts.firstWhere((p) => p.id == event.postId);
      if (post.postType == 'promotion') {
        final result =
            await BusinessService.instance.toggleSavePromotion(event.postId);
        result.fold(
          (failure) {
            emit(state.copyWith(posts: originalPosts));
            showGlobalToast(message: failure.message, status: 'error');
          },
          (data) {
            final isSaved = data['isSaved'] as bool? ?? false;
            final finalPosts = state.posts.map((p) {
              if (p.id == event.postId) {
                return p.copyWith(isSaved: isSaved);
              }
              return p;
            }).toList();
            emit(state.copyWith(posts: finalPosts));
          },
        );
      } else {
        final result = await _repository.toggleInterest(
          postId: event.postId,
          currentUserId: event.currentUserId,
        );

        result.fold(
          (failure) {
            emit(state.copyWith(posts: originalPosts));
            showGlobalToast(message: failure.message, status: 'error');
          },
          (updatedPostSkeleton) {
            final finalPosts = state.posts.map((p) {
              if (p.id == event.postId) {
                return p.copyWith(
                    isInterested: updatedPostSkeleton.isInterested);
              }
              return p;
            }).toList();
            emit(state.copyWith(posts: finalPosts));
          },
        );
      }
    } catch (e) {
      emit(state.copyWith(posts: originalPosts));
      showGlobalToast(message: 'Error updating status', status: 'error');
    }
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
      (failure) {
        showGlobalToast(message: failure.message, status: 'error');
        if (event.onFailure != null) {
          event.onFailure!();
        }
      },
      (comment) {
        // Increment comment count locally for that post
        final updatedPosts = state.posts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(commentsCount: post.commentsCount + 1);
          }
          return post;
        }).toList();

        emit(state.copyWith(posts: updatedPosts));
        showGlobalToast(
            message: 'Comment added successfully!', status: 'success');
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
    final updatedPosts =
        state.posts.where((post) => post.id != event.postId).toList();

    emit(state.copyWith(posts: updatedPosts));

    final result = await _repository.deletePost(postId: event.postId);

    result.fold(
      (failure) {
        emit(state.copyWith(posts: originalPosts));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        showGlobalToast(
            message: 'Activity removed successfully.', status: 'success');
      },
    );
  }

  Future<void> _onLoadInterestedUsers(
    LoadInterestedUsersRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isLoadingInterestedUsers: true, interestedUsers: []));
    final result = await PostsService.instance.getInterestedUsers(event.postId);
    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingInterestedUsers: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (users) => emit(state.copyWith(
          isLoadingInterestedUsers: false, interestedUsers: users)),
    );
  }

  Future<void> _onAcceptInterest(
    AcceptInterestRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isSubmittingAction: true));
    final result = await PostsService.instance
        .acceptInterest(event.postId, event.targetUserId);
    result.fold(
      (failure) {
        emit(state.copyWith(isSubmittingAction: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        // Update interested users list locally
        final updated = state.interestedUsers.map((u) {
          final user = u as Map<String, dynamic>;
          if ((user['userId']?.toString() ?? user['_id']?.toString()) ==
              event.targetUserId) {
            return {...user, 'status': 'ACCEPTED'};
          }
          return user;
        }).toList();
        // Increment acceptedParticipantsCount on the post
        final updatedPosts = state.posts.map((p) {
          if (p.id == event.postId) {
            return p.copyWith(
                acceptedParticipantsCount: p.acceptedParticipantsCount + 1);
          }
          return p;
        }).toList();
        emit(state.copyWith(
          isSubmittingAction: false,
          interestedUsers: updated,
          posts: updatedPosts,
        ));
        showGlobalToast(message: 'User accepted!', status: 'success');
      },
    );
  }

  Future<void> _onRejectInterest(
    RejectInterestRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isSubmittingAction: true));
    final result = await PostsService.instance
        .rejectInterest(event.postId, event.targetUserId);
    result.fold(
      (failure) {
        emit(state.copyWith(isSubmittingAction: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        final updated = state.interestedUsers.map((u) {
          final user = u as Map<String, dynamic>;
          if ((user['userId']?.toString() ?? user['_id']?.toString()) ==
              event.targetUserId) {
            return {...user, 'status': 'REJECTED'};
          }
          return user;
        }).toList();
        emit(state.copyWith(
            isSubmittingAction: false, interestedUsers: updated));
        showGlobalToast(message: 'User rejected.', status: 'success');
      },
    );
  }

  Future<void> _onClosePost(
    ClosePostRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isSubmittingAction: true));
    final result = await PostsService.instance.closePost(event.postId);
    result.fold(
      (failure) {
        emit(state.copyWith(isSubmittingAction: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        final updatedPosts = state.posts.map((p) {
          if (p.id == event.postId) return p.copyWith(status: 'CLOSED');
          return p;
        }).toList();
        emit(state.copyWith(isSubmittingAction: false, posts: updatedPosts));
        showGlobalToast(message: 'Activity closed.', status: 'success');
      },
    );
  }

  Future<void> _onSubmitReview(
    SubmitReviewRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(state.copyWith(isSubmittingAction: true));
    final result = await PostsService.instance.submitReview(
      postId: event.postId,
      targetUserId: event.targetUserId,
      rating: event.rating,
      comment: event.comment,
    );
    result.fold(
      (failure) {
        emit(state.copyWith(isSubmittingAction: false));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        emit(state.copyWith(isSubmittingAction: false));
        showGlobalToast(message: 'Review submitted!', status: 'success');
        if (event.onSuccess != null) event.onSuccess!();
      },
    );
  }
}
