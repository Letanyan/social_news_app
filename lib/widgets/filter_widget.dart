import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/widgets/location_picker.dart';
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
  final GlobalKey filterKey = GlobalKey();
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

  Size getWidgetSize() {
    final size = filterKey.currentContext?.findRenderObject() as RenderBox?;
    return size?.size ?? const Size(0, 0);
  }

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
  final GlobalKey filterKey = GlobalKey();

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

  void Function() updateDate(bool isStartDate) {
    return () async {
      final date = await showDatePicker(
          context: context,
          initialDate: isStartDate ? startDate[current] : endDate[current],
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: DateTime.now());
      if (date == null) {
        return;
      }
      if (isStartDate) {
        startDate[current] = date;
      } else {
        endDate[current] = date;
      }
      updateState();
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateButton = ActionChip(
      label: Text(
          "${formatDate(startDate[current])} - ${formatDate(endDate[current])}"),
      avatar: const Icon(Icons.calendar_month_rounded),
      onPressed: () {
        showPlatformDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              final startTile = ListTile(
                title: Text("From: ${formatDate(startDate[current])}"),
                onTap: updateDate(true),
              );
              final endTile = ListTile(
                title: Text("To: ${formatDate(endDate[current])}"),
                onTap: updateDate(false),
              );
              final closeDate = ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              );
              return AlertDialog(
                title: const Text("Select Date Range"),
                content: SingleChildScrollView(
                  child: Column(
                    children: [startTile, endTile],
                  ),
                ),
                actions: [closeDate],
              );
            });
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle =
        TextStyle(color: isDark ? Colors.white : Colors.grey[800]);
    final selectorWidgets = widget.selector?.map(
            (key, value) => MapEntry(key, Text(value, style: textStyle))) ??
        <int, Widget>{
          0: Text("Posts", style: textStyle),
          1: Text("Comments", style: textStyle)
        };
    final selector = CupertinoSlidingSegmentedControl<int>(
      // padding: const EdgeInsets.all(15),
      children: selectorWidgets,
      thumbColor: Colors.pink,
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
      style: textStyle,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: isDark
                    ? Colors.grey[400] ?? Colors.white
                    : Colors.grey[600] ?? Colors.black),
            borderRadius: BorderRadius.all(Radius.circular(16))),
        hintStyle: textStyle,
        hintText: 'Search',
      ),
      onSubmitted: (value) async {
        searchString[current] = value;
        controller.text = value;
        updateState();
      },
    );

    var filterItems = <Widget>[];

    var size = 0;
    if (widget.selector != null) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(selector);
      size += 48;
    }
    if (widget.search) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(searchBox);
      size += 48;
    }
    if (operatorItems.isNotEmpty) {
      filterItems.add(const SizedBox(height: 8));
      filterItems.add(operatorRow);
      size += 48;
    }

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: filterItems,
    );
    const rounding = BorderRadius.all(Radius.circular(16));
    final cont = Container(
      decoration: BoxDecoration(
          color: Colors.grey[isDark ? 800 : 200]?.withAlpha(192),
          borderRadius: rounding),
      child: Padding(padding: const EdgeInsets.all(8), child: body),
    );

    final filter = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
      child: cont,
    );

    final rect = ClipRRect(
        key: widget.filterKey,
        clipBehavior: Clip.antiAlias,
        borderRadius: rounding,
        child: filter);

    return Padding(padding: EdgeInsets.all(8), child: rect);
  }
}
