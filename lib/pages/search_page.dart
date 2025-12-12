import 'package:catalog_app_mobile/pages/item_detail_page.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SearchPage extends StatefulWidget {

  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>{
  @override
  void initState() {
    super.initState();
    // автоматически открываем поиск
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openSearch();
    });
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: CustomSearchDelegate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Поиск',
          ),
        ],
      ),
      body: const Center(),
    );
  }
}

// кастомный поиск
class CustomSearchDelegate extends SearchDelegate{

  // кнопки справа в апп бар
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  // кнопка слева в апп бар
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
    throw UnimplementedError();
  }

  // поиск
  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getItems(searchQuery: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return const Center(child: Text('Ничего не найдено'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return ListTile(
              title: Text(item.name),
              subtitle: item.description != null ? Text(item.description!) : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemDetailPage(item: item),),);
              },
            );
          },
        );
      },
    );
  }

  // подсказки во время ввода
  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    return Container();
  }
}