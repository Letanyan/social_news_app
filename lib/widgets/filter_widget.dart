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
  Map<int, String>? displaySelector;
  List<SortOrder>? displaySorting;
  int current;
  SortOrder? order;
  DateTime? startDate;
  DateTime? endDate;
  List<String>? location;
  String? search;

  FilterBoxState({
    this.displaySelector,
    this.displaySorting,
    required this.current,
    this.order,
    this.startDate,
    this.endDate,
    this.location,
    this.search,
  });

  factory FilterBoxState.zero() {
    return FilterBoxState(
      displaySelector: null,
      displaySorting: null,
      current: 0,
      order: null,
      startDate: null,
      endDate: null,
      location: null,
      search: null,
    );
  }
}

class FilterBox extends StatefulWidget {
  // final Map<int, String>? selector;
  // List<SortOrder>? sorting;
  // DateTime? startDate;
  // DateTime? endDate;
  // String? location;
  // String? search;
  final FilterBoxState state;
  final void Function(FilterBoxState)? valueChanged;
  final GlobalKey filterKey;
  const FilterBox({
    super.key,
    required this.filterKey,
    required this.valueChanged,
    required this.state,
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
  late final Map<int, String>? selector;
  var sortOrder = <SortOrder?>[];
  var location = <List<String>?>[];
  var startDate = <DateTime?>[];
  var endDate = <DateTime?>[];
  var searchString = <String?>[];
  var controller = TextEditingController();
  var state = FilterBoxState.zero();

  @override
  void initState() {
    super.initState();

    final defaultSelector = widget.state.displaySelector;
    final defaultStart = startOfDay(
        widget.state.startDate ?? DateTime.now().add(const Duration(days: -7)));
    final defaultEnd = endOfDay(widget.state.endDate ?? DateTime.now());
    final defaultLocation = widget.state.location ?? [];
    final defaultSearch = widget.state.search;
    final defaultOrder = widget.state.order ?? SortOrder.upvotes;
    current = widget.state.current;

    if (widget.state.displaySelector == null) {
      selector = defaultSelector;
      sortOrder = [defaultOrder];
      location = [defaultLocation];
      searchString = [defaultSearch];
      startDate = [defaultStart];
      endDate = [defaultEnd];
    } else {
      selector = defaultSelector;
      for (final _ in widget.state.displaySelector!.keys) {
        sortOrder.add(defaultOrder);
        location.add(defaultLocation);
        searchString.add(defaultSearch);
        startDate.add(defaultStart);
        endDate.add(defaultEnd);
      }
    }
  }

  void updateState() {
    state = FilterBoxState(
      displaySelector: selector,
      displaySorting: widget.state.displaySorting,
      current: current,
      order: sortOrder[current],
      startDate: startDate[current],
      endDate: endDate[current],
      location: location[current],
      search: searchString[current],
    );
    setState(() {});
    controller.text = searchString[current] ?? "";
    if (widget.valueChanged != null) {
      widget.valueChanged!(state);
    }
  }

  String getLocationPresentation() {
    if (location[current]?.isEmpty == true) {
      return "Everywhere";
    } else {
      final args = location[current];
      if (args == null) {
        return "Everywhere";
      }
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
      final fallback = DateTime.now();
      final date = await showDatePicker(
          context: context,
          initialDate:
              (isStartDate ? startDate[current] : endDate[current]) ?? fallback,
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: endOfDay(DateTime.now()));
      if (date == null) {
        return;
      }
      if (isStartDate) {
        startDate[current] = startOfDay(date);
      } else {
        endDate[current] = endOfDay(date);
      }
      updateState();
      setState(() {});
    };
  }

  List<Widget> buildSortByTiles(void Function(void Function()) setState) {
    List<Widget> dropMenuItems = [];
    for (final so in widget.state.displaySorting ?? []) {
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

  List<Widget> buildCategoryTiles(void Function(void Function()) setState) {
    List<Widget> dropMenuItems = [];
    final list = widget.state.displaySelector?.keys ?? [];
    for (final cat in list) {
      dropMenuItems.add(
        ListTile(
          trailing: current == cat ? const Icon(Icons.check_rounded) : null,
          title: Text(widget.state.displaySelector?[cat] ?? ""),
          onTap: () {
            current = cat;
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
    final fallbackDate = DateTime.now();
    final dateButton = ActionChip(
      label: Text(
          "${formatDate(startDate[current] ?? fallbackDate)} - ${formatDate(endDate[current] ?? fallbackDate)}"),
      avatar: const Icon(Icons.calendar_month_rounded),
      onPressed: () {
        showPlatformDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              final startTile = ListTile(
                title: Text(
                    "From: ${formatDate(startDate[current] ?? fallbackDate)}"),
                onTap: updateDate(true, setState),
              );
              final endTile = ListTile(
                title:
                    Text("To: ${formatDate(endDate[current] ?? fallbackDate)}"),
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
        final args = location[current];
        if (args == null) {
          return;
        }
        if (args.isNotEmpty) {
          country = args[0];
        }
        if (args.length > 1) {
          region = args[1];
        }
        var loc = await Navigator.push(
            context,
            route(
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
      label:
          Text(sortOrderPresentation(sortOrder[current] ?? SortOrder.upvotes)),
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
    final categoryDropDown = ActionChip(
      label: Text(selector?[current] ?? ""),
      avatar: const Icon(Icons.category_rounded),
      onPressed: () {
        showPlatformDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              final closeCategory = ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              );
              return AlertDialog(
                title: const Text("Sort By"),
                content: SingleChildScrollView(
                  child: Column(
                    children: buildCategoryTiles(setState),
                  ),
                ),
                actions: [closeCategory],
              );
            });
          },
        );
      },
    );

    var operatorItems = <Widget>[];
    if (widget.state.displaySelector != null) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(categoryDropDown);
    }
    if (widget.state.displaySorting != null) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(sortDropDown);
    }
    if (widget.state.startDate != null) {
      operatorItems.add(const SizedBox(width: 8));
      operatorItems.add(dateButton);
    }
    if (widget.state.location != null) {
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
    // final selectorWidgets = widget.state.displaySelector?.map(
    //         (key, value) => MapEntry(key, Text(value, style: textStyle))) ??
    //     <int, Widget>{
    //       0: Text("Posts", style: textStyle),
    //       1: Text("Comments", style: textStyle)
    //     };
    // final selector = CupertinoSlidingSegmentedControl<int>(
    //   children: selectorWidgets,
    //   thumbColor: MyTheme.primary,
    //   onValueChanged: (int? index) {
    //     if (index != null) {
    //       current = index;
    //     }
    //     updateState();
    //   },
    //   groupValue: current,
    // );

    final searchBox = TextField(
      keyboardType: TextInputType.text,
      maxLines: 1,
      controller: controller,
      style: textStyle,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: isDark
                    ? Colors.grey[400] ?? Colors.white
                    : Colors.grey[600] ?? Colors.black),
            borderRadius: const BorderRadius.all(Radius.circular(8))),
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

    // if (widget.state.displaySelector != null) {
    //   filterItems
    //       .add(Padding(padding: const EdgeInsets.all(8), child: selector));
    // }
    if (widget.state.search != null) {
      filterItems
          .add(Padding(padding: const EdgeInsets.all(8), child: searchBox));
    }
    if (operatorItems.isNotEmpty) {
      filterItems.add(operatorRow);
    }

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: filterItems,
    );
    // const rounding = BorderRadius.all(Radius.circular(16));
    // final cont = Container(
    //   decoration: BoxDecoration(
    //     color: Colors.grey[isDark ? 800 : 200]?.withAlpha(192),
    //     borderRadius: rounding,
    //     border: Border.all(color: Colors.grey),
    //   ),
    //   child: Padding(padding: const EdgeInsets.all(8), child: body),
    // );

    final filter = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
      child: body,
    );

    final rect = ClipRect(
      key: widget.key,
      clipBehavior: Clip.antiAlias,
      // borderRadius: rounding,
      child: filter,
    );

    return rect;
    // return Padding(padding: const EdgeInsets.all(8), child: rect);
  }
}
