import 'package:flutter_loadmore_search/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'http_client.dart';
import 'post_state.dart';

part 'post_riverpod.g.dart';

@Riverpod(keepAlive: true)
class PostRiverpod extends _$PostRiverpod {
  @override
  Future<PostState> build() async {
    return _initPost();
  }

  Future<PostState> _initPost() async {
    final posts = await getPosts(1);
    if (posts == null) {
      return const PostState(posts: []);
    }
    final key = ref.watch(keyProvider);
    final searchedPosts = posts
        .where((element) =>
            element.body.contains(key) || element.title.contains(key))
        .toList();

    return PostState(posts: searchedPosts);
  }

  Future<void> loadMorePost() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadMoreError) {
      print('Loading failed or already loading.');
      return;
    }

    print('try to request loading at ${currentState.page + 1}');

    state = AsyncValue.data(
        currentState.copyWith(isLoadMoreDone: false, isLoadMoreError: false));

    final posts = await getPosts(currentState.page + 1);

    if (posts == null) {
      state = AsyncValue.data(currentState.copyWith(isLoadMoreError: true));
    }

    print('load more  posts at page ${currentState.page + 1}');

    if (posts!.isNotEmpty) {
      final key = ref.watch(keyProvider);
      final searchedPosts = posts
          .where((element) =>
              element.body.contains(key) || element.title.contains(key))
          .toList();

      state = AsyncValue.data(currentState.copyWith(
          page: currentState.page + 1,
          isLoadMoreDone: posts.isEmpty,
          posts: [...?currentState.posts, ...searchedPosts]));
    } else {
      state = AsyncValue.data(currentState.copyWith(
        isLoadMoreDone: posts.isEmpty,
      ));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _initPost();
    });
  }
}
