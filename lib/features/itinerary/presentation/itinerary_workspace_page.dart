import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/itinerary_providers.dart';
import 'itinerary_design_tab.dart';
import 'itinerary_editor_tab.dart';
import 'itinerary_form_page.dart';
import 'itinerary_view_tab.dart';

/// しおり1件のワークスペース。
/// エディター（データ入力）／デザイン（表紙・ページ構成）／しおり（閲覧）の3タブで構成する。
class ItineraryWorkspacePage extends ConsumerStatefulWidget {
  const ItineraryWorkspacePage({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  ConsumerState<ItineraryWorkspacePage> createState() =>
      _ItineraryWorkspacePageState();
}

class _ItineraryWorkspacePageState extends ConsumerState<ItineraryWorkspacePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itineraryAsync = ref.watch(itineraryProvider(widget.itineraryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(itineraryAsync.value?.title ?? 'しおり'),
        actions: [
          itineraryAsync.maybeWhen(
            data: (itinerary) => IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '編集',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItineraryFormPage(itinerary: itinerary),
                  ),
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'エディター', icon: Icon(Icons.edit_note)),
            Tab(text: 'デザイン', icon: Icon(Icons.palette_outlined)),
            Tab(text: 'しおり', icon: Icon(Icons.menu_book_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ItineraryEditorTab(itineraryId: widget.itineraryId),
          ItineraryDesignTab(itineraryId: widget.itineraryId),
          ItineraryViewTab(itineraryId: widget.itineraryId),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton(
          onPressed: () => openAddSpotPage(context, ref, widget.itineraryId),
          tooltip: 'スポットを追加',
          child: const Icon(Icons.add_location_alt),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () {
            ref.read(itineraryRepositoryProvider).addPage(widget.itineraryId);
          },
          tooltip: 'ページを追加',
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }
}
