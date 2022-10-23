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
    final startChip = ActionChip(
      label: Text("From: ${formatDate(startDate[current])}"),
      onPressed: () async {
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
    final endChip = ActionChip(
        label: Text("To: ${formatDate(endDate[current])}"),
        onPressed: () async {
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
    final dateRange = Row(
      children: [
        Expanded(
            child: Align(alignment: Alignment.centerRight, child: startChip)),
        const SizedBox(width: 8),
        Expanded(child: Align(alignment: Alignment.centerLeft, child: endChip)),
      ],
    );

    final area = ActionChip(
      label: Text("Location: ${getLocationPresentation()}"),
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

    final selector = CupertinoSlidingSegmentedControl<int>(
      // padding: const EdgeInsets.all(15),
      children: const {
        0: Text("Tags"),
        1: Text("Posts"),
        2: Text("Users"),
        3: Text("Comments"),
      },
      onValueChanged: (int? index) {
        current = index ?? 0;
        updateState();
      },
      groupValue: current,
    );

    List<DropdownMenuItem<SortOrder>> dropMenuItems = [];
    for (final so in widget.sorting ?? []) {
      dropMenuItems.add(
        DropdownMenuItem(
          value: so,
          child: Text(sortOrderPresentation(so)),
        ),
      );
    }
    final sortDropDown = DropdownButton<SortOrder>(
        value: sortOrder[current],
        onChanged: (value) {
          sortOrder[current] = value ?? SortOrder.upvotes;
          updateState();
        },
        items: dropMenuItems);

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
    if (widget.date) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(dateRange);
    }
    if (widget.location) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(area);
    }
    if (widget.sorting != null) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(sortDropDown);
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
