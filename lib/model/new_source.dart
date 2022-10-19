import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/post.dart';

import 'user.dart';
import 'tag.dart';

class NewSource {
  static const host = "http://localhost:8080/api/v1";

  static String buildURL(List<String> path, List<String> args) {
    var result = host;
    for (final p in path) {
      result += "/$p";
    }
    if (args.isNotEmpty) {
      result += "?";
    }
    if (!args.length.isEven) {
      throw Exception("args must be even key-value pairs");
    }
    for (int i = 0; i < args.length; i += 2) {
      // FIXME: escape values
      result += "${args[i]}=${args[i + 1]}";
      if (i != args.length - 2) {
        result += "&";
      }
    }
    return result;
  }

  static Future<dynamic> get(List<String> path, List<String> args) async {
    dynamic responseJson;
    try {
      final query = buildURL(path, args);
      print(query);
      final response = await http.get(Uri.parse(query));
      responseJson = json.decode(response.body);
    } catch (e) {
      return null;
    }
    return responseJson;
  }

  static Future<dynamic> post(
      List<String> path, List<String> args, Object? body) async {
    dynamic responseJson;
    try {
      final query = buildURL(path, args);
      final response =
          await http.post(Uri.parse(query), body: json.encode(body));
      responseJson = json.decode(response.body);
    } catch (e) {
      return null;
    }
    return responseJson;
  }

  //----------------------------------------------------------------------------
  // Sign In
  //----------------------------------------------------------------------------
  static Future<User> signInUser(String email, String password) async {
    final obj = await post(["auth", "callbacks", "sign-in"], [],
        {"email": email, "password": password});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return User.fromJson(obj["payload"]["user"]);
    }
  }

  //----------------------------------------------------------------------------
  // Create
  //----------------------------------------------------------------------------
  static Future<Comment> createComment(
      int postId, int replyId, String content) async {
    if (User.current == null) {
      throw userNotSignedIn;
    }

    final obj = await post(["posts", "$postId", "comments"], [],
        {"userId": User.current!.ID, "replyId": replyId, "content": content});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return Comment.fromJson(obj["payload"]);
    }
  }

  //----------------------------------------------------------------------------
  // Delete
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // Get Users
  //----------------------------------------------------------------------------
  static Future<List<Author>> getUsers(
      {List<String>? popularIn,
      int? upvotes,
      int? downvotes,
      String? order,
      int? limit,
      int? offset,
      DateTime? start,
      DateTime? end,
      int? forUser,
      String? search}) async {
    var args = <String>[];
    addL("popularIn", popularIn, args);
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addS("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addD("start", start, args);
    addD("end", end, args);
    addI("for", forUser, args);
    addS("search", search, args);

    final obj = await get(["users"], args);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      final list = obj["payload"];
      var result = <Author>[];
      for (final item in list) {
        final p = Author.fromJson(item);
        result.add(p);
      }
      return result;
    }
  }

  //----------------------------------------------------------------------------
  // Get Posts
  //----------------------------------------------------------------------------
  static Future<Post> getPost(int id) async {
    final obj = await get(["posts", "$id"], []);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      final item = obj["payload"];
      final result = Post.fromJson(item);
      return result;
    }
  }

  static Future<List<Post>> getPosts(
      {int? userId,
      List<String>? origin,
      List<int>? tags,
      List<String>? popularIn,
      int? upvotes,
      int? downvotes,
      String? order,
      int? offset,
      int? limit,
      DateTime? start,
      DateTime? end,
      DateTime? startCreated,
      DateTime? endCreated,
      int? forUser,
      String? search}) async {
    var args = <String>[];
    addI("uid", userId, args);
    addL("origin", origin, args);
    addIL("tags", tags, args);
    addL("popularIn", popularIn, args);
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addS("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addD("start", start, args);
    addD("end", end, args);
    addD("startCreated", startCreated, args);
    addD("endCreated", endCreated, args);
    addI("for", forUser, args);
    addS("search", search, args);

    final obj = await get(["posts"], args);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      final list = obj["payload"];
      var result = <Post>[];
      var uncached = <int>[];
      for (final item in list) {
        final p = Post.fromJson(item);
        result.add(p);
        uncached.addAll(p.Tags);
      }
      await Tag.cacheTags(uncached);
      return result;
    }
  }

  //----------------------------------------------------------------------------
  // Get Tags
  //----------------------------------------------------------------------------
  static Future<Tag> getTag(int id) async {
    final obj = await get(["tags"], ["id", "$id"]);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return Tag.fromJson(obj["payload"]);
    }
  }

  static Future<List<Tag>> getTagsFromIds(List<int> ids) async {
    final obj = await post(["tags"], [], {"ids": ids});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return Tag.listFromJson(obj["payload"]);
    }
  }

  static Future<List<Tag>> getTags(
      {List<String>? location,
      List<String>? tags,
      int? upvotes,
      int? downvotes,
      String? order,
      int? offset,
      int? limit,
      DateTime? start,
      DateTime? end,
      String? search}) async {
    var args = <String>[];
    addL("location", location, args);
    addL("tags", tags, args);
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addS("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addD("start", start, args);
    addD("end", end, args);
    addS("search", search, args);

    final obj = await get(["tags"], args);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      final list = obj["payload"];
      var result = <Tag>[];
      for (final item in list) {
        result.add(Tag.fromJson(item));
      }
      return result;
    }
  }

  //----------------------------------------------------------------------------
  // Get Comments
  //----------------------------------------------------------------------------
  static Future<List<Comment>> getComments(
      {int? postId,
      int? userId,
      int? replyId,
      DateTime? startCreated,
      DateTime? endCreated,
      List<String>? popularIn,
      int? upvotes,
      int? downvotes,
      String? order,
      int? limit,
      int? offset,
      DateTime? start,
      DateTime? end,
      int? forUser,
      String? search}) async {
    var args = <String>[];
    addI("uid", userId, args);
    addI("pid", postId, args);
    addI("reply", replyId, args);
    addL("popularIn", popularIn, args);
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addS("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addD("start", start, args);
    addD("end", end, args);
    addD("startCreated", startCreated, args);
    addD("endCreated", endCreated, args);
    addI("for", forUser, args);
    addS("search", search, args);

    final obj = await get(["posts", "comments"], args);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      final list = obj["payload"];
      var result = <Comment>[];
      for (final item in list) {
        result.add(Comment.fromJson(item));
      }
      return result;
    }
  }

  //----------------------------------------------------------------------------
  // Vote
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // Flags
  //----------------------------------------------------------------------------

}

class NSError implements Exception {
  final String message;

  const NSError({required this.message});

  @override
  String toString() {
    return message;
  }
}

NSError err(String message) {
  return NSError(message: message);
}

final unknownError = err("An unknown error has occurred");
final userNotSignedIn = err("No user appears to be signed in");

void addS(String name, String? value, List<String> args) {
  if (value != null) {
    args.add(name);
    args.add(value);
  }
}

void addI(String name, int? value, List<String> args) {
  if (value != null) {
    args.add(name);
    args.add("$value");
  }
}

void addL(String name, List<String>? value, List<String> args) {
  if (value != null) {
    args.add(name);
    args.add(value.join(","));
  }
}

void addIL(String name, List<int>? value, List<String> args) {
  if (value != null) {
    args.add(name);
    args.add(value.map((v) => "$v").join(","));
  }
}

void addD(String name, DateTime? value, List<String> args) {
  if (value != null) {
    args.add(name);
    final formatter = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
    final result = formatter.format(value.toUtc());
    args.add(result);
  }
}
