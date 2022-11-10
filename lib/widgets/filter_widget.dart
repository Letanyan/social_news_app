import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/model/geo.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/theme.dart';
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
  List<SortOrder>? sorting;
  DateTime? startDate;
  DateTime? endDate;
  String? location;
  String? search;
  FilterBoxState? currentState;
  void Function(FilterBoxState)? valueChanged;
  final GlobalKey filterKey = GlobalKey();
  FilterBox({
    super.key,
    this.selector,
    this.sorting,
    this.startDate,
    this.endDate,
    this.location,
    this.search,
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

    final defaultStart =
        widget.startDate ?? DateTime.now().add(const Duration(days: -7));
    final defaultEnd = widget.endDate ?? DateTime.now();
    final defaultLocation = widget.location ?? "";
    final defaultSearch = widget.search ?? "";

    if (widget.selector == null) {
      sortOrder = [SortOrder.upvotes];
      location = [defaultLocation];
      searchString = [defaultSearch];
      startDate = [defaultStart];
      endDate = [defaultEnd];
    } else {
      for (final key in widget.selector!.keys) {
        sortOrder.add(SortOrder.upvotes);
        location.add(defaultLocation);
        searchString.add(defaultSearch);
        startDate.add(defaultStart);
        endDate.add(defaultEnd);
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
      var result = "";
      if (args.isNotEmpty) {
        result += Geo.current.country(args[0]);
      }
      if (args.length > 1) {
        result += ", ${Geo.current.region(args[0], args[1])}";
      }
      return result;
    }
  }

  void Function() updateDate(
    bool isStartDate,
    void Function(void Function()) setState,
  ) {
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
      setState(() {});
    };
  }

  List<Widget> buildSortByTiles(void Function(void Function()) setState) {
    List<Widget> dropMenuItems = [];
    for (final so in widget.sorting ?? []) {
      dropMenuItems.add(
        ListTile(
          trailing:
              sortOrder[current] == so ? const Icon(Icons.check_rounded) : null,
          title: Text(sortOrderPresentation(so)),
          onTap: () {
            sortOrder[current] = so;
            updateState();
            setState(() {});
          },
        ),
      );
    }
    return dropMenuItems;
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
                onTap: updateDate(true, setState),
              );
              final endTile = ListTile(
                title: Text("To: ${formatDate(endDate[current])}"),
                onTap: updateDate(false, setState),
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
        String country = "";
        String region = "";
        final args = location[current].split(",");
        if (args.isNotEmpty) {
          country = args[0];
        }
        if (args.length > 1) {
          region = args[1];
        }
        var loc = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LocationCountryPickerPage(country: country, region: region),
            ));
        if (loc == null) {
          return;
        }
        location[current] = loc;
        updateState();
      },
    );
    final sortDropDown = ActionChip(
      label: Text(sortOrderPresentation(sortOrder[current])),
      avatar: const Icon(Icons.sort_rounded),
      onPressed: () {
        showPlatformDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              final closeSort = ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              );
              return AlertDialog(
                title: const Text("Sort By"),
                content: SingleChildScrollView(
                  child: Column(
                    children: buildSortByTiles(setState),
                  ),
                ),
                actions: [closeSort],
              );
            });
          },
        );
      },
    );

    var operatorItems = <Widget>[];
    if (widget.sorting != null) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(sortDropDown);
    }
    if (widget.startDate != null) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(dateButton);
      // operatorItems.add(startChip);
      // operatorItems.add(endChip);
    }
    if (widget.location != null) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(area);
    }
    final operatorRow = SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: operatorItems,
      ),
    );

    final isDark = MyTheme.isDark;
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
      thumbColor: MyTheme.primary,
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
            borderRadius: const BorderRadius.all(Radius.circular(16))),
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
    if (widget.search != null) {
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
        borderRadius: rounding,
        border: Border.all(color: Colors.grey),
      ),
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
      child: filter,
    );

    return Padding(padding: const EdgeInsets.all(8), child: rect);
  }
}
