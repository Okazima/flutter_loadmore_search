import 'package:flutter/material.dart';
import 'package:flutter_loadmore_search/post_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final keyProvider = StateProvider<String>((ref) {
  return '';
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final ScrollController _controller = ScrollController();
  int oldLength = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() async {
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent -
              MediaQuery.of(context).size.height) {
        if (oldLength == ref.read(postRiverpodProvider).value!.posts!.length) {
          ref.read(postRiverpodProvider.notifier).loadMorePost();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(postRiverpodProvider);
    final notifier = ref.read(postRiverpodProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: const InputDecoration(
              hintText: 'Enter to search!',
              hintStyle: TextStyle(color: Colors.yellow)),
          onChanged: (newValue) {
            ref.read(keyProvider.notifier).state = newValue;
          },
        ),
      ),
      body: asyncValue.when(
        data: (asyncValue) => Consumer(
          builder: (ctx, watch, child) {
            oldLength = asyncValue.posts?.length ?? 0;

            if (asyncValue.posts == null) {
              return const Center(
                child: Text('error'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  controller: _controller,
                  itemCount: asyncValue.posts!.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == asyncValue.posts!.length) {
                      if (asyncValue.isLoadMoreError) {
                        return const Center(
                          child: Text('Error'),
                        );
                      }

                      if (asyncValue.isLoadMoreDone) {
                        return const Center(
                          child: Text(
                            'Done!',
                            style: TextStyle(color: Colors.green, fontSize: 20),
                          ),
                        );
                      }

                      return TextButton(
                        onPressed: () {
                          notifier.loadMorePost();
                        },
                        child: const Text('Load More'),
                      );
                    }
                    return ListTile(
                      title: Text(asyncValue.posts![index].title),
                      subtitle: Text(asyncValue.posts![index].body),
                      trailing: Text(asyncValue.posts![index].id.toString()),
                    );
                  }),
            );
          },
        ),
        error: (err, stack) => const Text('error'),
        loading: () => const _Loading(),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
