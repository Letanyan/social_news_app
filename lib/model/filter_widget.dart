import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/location_picker.dart';
import 'package:social_news_app/model/new_source.dart';

class FilterBoxState {
  int current;
  SortOrder order;
  DateTime start;
  DateTime end;
  List<String>? location;
  String? search;

  FilterBoxState({
    required this.current,
    required this.order,
    required this.start,
    required this.end,
    required this.location,
    required this.search,
  });
}

class FilterBox extends StatefulWidget {
  final Map<int, String>? selector;
  final List<SortOrder>? sorting;
  final bool date;
  final bool location;
  final bool search;
  FilterBoxState? currentState;
  void Function(FilterBoxState)? valueChanged;
  FilterBox({
    super.key,
    this.selector,
    this.sorting,
    this.date = false,
    this.location = false,
    this.search = false,
    this.valueChanged,
    this.currentState,
  });

  @override
  State<FilterBox> createState() => _FilterBoxState();
}

class _FilterBoxState extends State<FilterBox> {
  var current = 0;
  var sortOrder = <SortOrder>[];
  var location = <String>[];
  var startDate = <DateTime>[];
  var endDate = <DateTime>[];
  var searchString = <String>[];
  var controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.selector == null) {
      sortOrder = [SortOrder.upvotes];
      location = [""];
      searchString = [""];
      startDate = [DateTime.now().add(const Duration(days: -7))];
      endDate = [DateTime.now()];
    } else {
      for (final key in widget.selector!.keys) {
        sortOrder.add(SortOrder.upvotes);
        location.add("");
        searchString.add("");
        startDate.add(DateTime.now().add(const Duration(days: -7)));
        endDate.add(DateTime.now());
      }
    }
    widget.currentState = FilterBoxState(
      current: current,
      order: sortOrder[current],
      start: startDate[current],
      end: endDate[current],
      location: getLocationArg(),
      search: getSearchString(),
    );
  }

  void updateState() {
    widget.currentState = FilterBoxState(
      current: current,
      order: sortOrder[current],
      start: startDate[current],
      end: endDate[current],
      location: getLocationArg(),
      search: getSearchString(),
    );
    setState(() {});
    controller.text = searchString[current];
    if (widget.valueChanged != null) {
      widget.valueChanged!(widget.currentState!);
    }
  }

  List<String>? getLocationArg() {
    if (location[current] == "") {
      return null;
    } else {
      return location[current].split(",");
    }
  }

  String? getSearchString() {
    if (searchString[current] == "") {
      return null;
    } else {
      return searchString[current];
    }
  }

  String getLocationPresentation() {
    if (location[current] == "") {
      return "Everywhere";
    } else {
      final args = location[current].split(",");
      return args.join(", ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final startTile = ListTile(
      title: Text("From: ${formatDate(startDate[current])}"),
      onTap: () async {
        final date = await showDatePicker(
            context: context,
            initialDate: startDate[current],
            firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
            lastDate: DateTime.now());
        if (date == null) {
          return;
        }
        startDate[current] = date;
        updateState();
      },
    );
    final endTile = ListTile(
        title: Text("To: ${formatDate(endDate[current])}"),
        onTap: () async {
          final date = await showDatePicker(
              context: context,
              initialDate: endDate[current],
              firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
              lastDate: DateTime.now());
          if (date == null) {
            return;
          }
          endDate[current] = date;
          updateState();
        });
    final closeDate = ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text("Close"),
    );
    final dateButton = ActionChip(
      label: Text(
          "${formatDate(startDate[current])} - ${formatDate(endDate[current])}"),
      avatar: const Icon(Icons.calendar_month_rounded),
      onPressed: () {
        showBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              height: 200,
              child: Column(children: [
                startTile,
                endTile,
                closeDate,
              ]),
            );
          },
        );
      },
    );

    final area = ActionChip(
      label: Text(getLocationPresentation()),
      avatar: const Icon(Icons.map_rounded),
      onPressed: () async {
        var loc = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LocationPickerPage(),
            ));
        if (loc == null) {
          return;
        }
        location[current] = loc;
        updateState();
      },
    );
    List<Widget> dropMenuItems = [];
    for (final so in widget.sorting ?? []) {
      dropMenuItems.add(
        ListTile(
          title: Text(sortOrderPresentation(so)),
          onTap: () {
            sortOrder[current] = so;
            updateState();
          },
        ),
      );
    }
    final closeSort = ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text("Close"),
    );
    final sortDropDown = ActionChip(
      label: Text(sortOrderPresentation(sortOrder[current])),
      avatar: const Icon(Icons.sort_rounded),
      onPressed: () {
        showBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          builder: (context) {
            return Container(
              height: 200,
              child: Column(children: [
                Expanded(child: ListView(children: dropMenuItems)),
                Padding(padding: EdgeInsets.all(8), child: closeSort),
              ]),
            );
          },
        );
      },
    );

    var operatorItems = <Widget>[];
    if (widget.sorting != null) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(sortDropDown);
    }
    if (widget.date) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(dateButton);
      // operatorItems.add(startChip);
      // operatorItems.add(endChip);
    }
    if (widget.location) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(area);
    }
    final operatorRow = Container(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: operatorItems,
      ),
    );

    final selectorWidgets =
        widget.selector?.map((key, value) => MapEntry(key, Text(value))) ??
            <int, Widget>{0: const Text("Posts"), 1: const Text("Comments")};
    final selector = CupertinoSlidingSegmentedControl<int>(
      // padding: const EdgeInsets.all(15),
      children: selectorWidgets,
      onValueChanged: (int? index) {
        current = index ?? 0;
        updateState();
      },
      groupValue: current,
    );

    final searchBox = TextField(
      keyboardType: TextInputType.text,
      maxLines: 1,
      controller: controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Search',
      ),
      onSubmitted: (value) async {
        searchString[current] = value;
        controller.text = value;
        updateState();
      },
    );

    var filterItems = <Widget>[];

    if (widget.selector != null) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(selector);
    }
    if (widget.search) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(searchBox);
    }
    if (operatorItems.isNotEmpty) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(operatorRow);
    }
    filterItems.add(const SizedBox(height: 8));

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: filterItems,
    );
    final cont = Container(
      color: Colors.white.withAlpha(192),
      child: Padding(padding: const EdgeInsets.all(8), child: body),
    );

    final filter = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: cont,
    );

    return ClipRect(child: filter);
  }
}
