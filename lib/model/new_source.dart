import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/news_agent.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user_pref.dart';

import 'user.dart';
import 'tag.dart';

class NewSource {
  static const isDebug = true;
  static var host = isDebug
      ? "http://192.168.0.147:8080/api/v1"
      : "https://new-source-server-mhvly.ondigitalocean.app/api/v1";
  // admin: @@:AbstractServer8080

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
      result += "${args[i]}=${Uri.encodeComponent(args[i + 1])}";
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
      final url = Uri.parse(query);
      final response = await http.get(url);
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
      final url = Uri.parse(query);
      final response = await http.post(url, body: json.encode(body));
      responseJson = json.decode(response.body);
    } catch (e) {
      return null;
    }
    return responseJson;
  }

  static Future<dynamic> delete(List<String> path, List<String> args) async {
    dynamic responseJson;
    try {
      final query = buildURL(path, args);
      final response = await http.post(Uri.parse(query));
      responseJson = json.decode(response.body);
    } catch (e) {
      return null;
    }
    return responseJson;
  }

  static Future<http.Response?> head(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response;
    } catch (e) {
      return null;
    }
  }

  static List<T> handlePayload<T>(
      dynamic obj, T Function(Map<String, dynamic> json) map) {
    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return jsonArrayTo(obj["payload"], map);
    }
  }

  //----------------------------------------------------------------------------
  // Sign In
  //----------------------------------------------------------------------------
  static Future<User> signInUser(String email, String password) async {
    final obj = await post(
        ["auth", "sign-in"], [], {"email": email, "password": password});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return User.fromSecretJson(obj["payload"]);
    }
  }

  static Future<User> signUpUser(
      String user, String email, String password) async {
    final obj = await post(
        ["users"], [], {"email": email, "name": user, "password": password});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return User.fromSecretJson(obj["payload"]);
    }
  }

  static Future<User> signInUserGoogle(String idToken, String access) async {
    final body = {"token": idToken, "access": access};
    final obj = await post(
      ["auth", "sign-in-with-google"],
      [],
      body,
    );
    if (obj == null) {
      throw unknownError;
    }
    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return User.fromSecretJson(obj["payload"]);
    }
  }

  static Future<User> signInUserApple(String code) async {
    final body = {"code": code};
    final obj = await post(
      ["auth", "sign-in-with-apple"],
      [],
      body,
    );
    if (obj == null) {
      throw unknownError;
    }
    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return User.fromSecretJson(obj["payload"]);
    }
  }

  static Future<bool> signOut() async {
    final path = ["auth", "sign-out"];
    var args = <String>[];
    addSecret(args);

    final obj = await post(path, args, {"userId": User.current!.id});
    if (obj == null) {
      User.current = null;
      return false;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      User.current = null;
      return true;
    }
  }

  static Future<int> sendPasswordResetLink(String email) async {
    final obj = await post(["auth", "password-reset"], [], {"email": email});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return obj["payload"];
    }
  }

  static Future<int> sendVerificationLink(
      int uid, String email, int key) async {
    final obj = await post(["auth", "verification", "users", "$uid"], [],
        {"email": email, "key": key});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return obj["payload"];
    }
  }

  static Future<int> authenticateIAP(
      String platform, int userId, String data, String productId) async {
    final List<String> path;
    switch (platform) {
      case "google_play":
        path = ["auth", "google-iap"];
        break;
      case "apple_app_store":
        path = ["auth", "apple-iap"];
        break;
      default:
        return -1;
    }

    var args = <String>[];
    addSecret(args);

    final input = {"data": data, "productId": productId, "userId": userId};
    final obj = await post(path, args, input);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      return -1;
    } else {
      return obj["payload"];
    }
  }

  static Future<bool> isAvailable() async {
    final obj = await get(["available"], []);
    if (obj == null) {
      return false;
    }
    return obj["success"] == true;
  }

  static Future<bool> updateUserDetails(User user) async {
    var args = <String>[];
    addSecret(args);

    final path = ["users", "${user.id}", "details"];
    final body = {
      "name": user.name,
      "PublicViews": user.publicViews,
      "PublicReadLater": user.publicReadLater,
      "PublicFollowing": user.publicFollowing,
      "PublicIgnored": user.publicIgnored,
      "PublicPostVotes": user.publicPostVotes,
      "PublicCommentVotes": user.publicCommentVotes,
      "PublicUserVotes": user.publicUserVotes,
      "PublicTagVotes": user.publicTagVotes,
    };
    final obj = await post(path, args, body);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      return false;
    } else {
      return true;
    }
  }

  //----------------------------------------------------------------------------
  // Create
  //----------------------------------------------------------------------------
  static Future<Comment> createComment(
      int postId, int replyId, String content, bool isReview) async {
    if (User.current == null) {
      throw userNotSignedIn;
    }
    if (isReview && content.length > 10000) {
      throw contentLengthTooLong;
    }
    if (!isReview && content.length > 1000) {
      throw contentLengthTooLong;
    }

    var args = <String>[];
    addSecret(args);

    final obj = await post(
        ["posts", "$postId", "comments"],
        args,
        {
          "userId": User.current!.id,
          "replyId": replyId,
          "content": content,
          "isReview": isReview
        });
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return Comment.fromJson(obj["payload"]);
    }
  }

  static Future<Post> createPost(String content) async {
    if (User.current == null) {
      throw userNotSignedIn;
    }
    if (content.length > 10000) {
      throw contentLengthTooLong;
    }

    var args = <String>[];
    addSecret(args);

    final obj = await post(
        ["posts"],
        args,
        {
          "userId": User.current!.id,
          "content": content,
        });
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return Post.fromJson(obj["payload"]);
    }
  }

  static Future<bool> updateComment(
      int postId, int commentId, String content) async {
    if (User.current == null) {
      throw userNotSignedIn;
    }

    var args = <String>[];
    addSecret(args);
    final obj = await post(
        ["update", "posts", "$postId", "comments", "$commentId"],
        args,
        {
          "userId": User.current!.id,
          "content": content,
        });
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return true;
    }
  }

  static Future<bool> updatePost(int postId, String content) async {
    if (User.current == null) {
      throw userNotSignedIn;
    }

    var args = <String>[];
    addSecret(args);
    final obj = await post(
        ["update", "posts", "$postId"],
        args,
        {
          "userId": User.current!.id,
          "content": content,
        });
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return true;
    }
  }

  //----------------------------------------------------------------------------
  // Delete
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // Get Users
  //----------------------------------------------------------------------------
  static Future<User> getUser(int uid) async {
    var args = <String>[];
    addSecret(args);
    final path = ["users", "$uid"];

    final obj = await get(path, args);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return User.fromSecretJson(obj["payload"]);
    }
  }

  static Future<List<Author>> getUsers(
      {List<String>? popularIn,
      int? upvotes,
      int? downvotes,
      SortOrder? order,
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
    addSO("order", order, args);
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

    return handlePayload(obj, Author.fromJson);
  }

  static Future<List<UserPrefUser>> getUserPrefUsers({
    int? uid,
    int? upvotes,
    int? downvotes,
    DateTime? startVoted,
    DateTime? endVoted,
    SortOrder? order,
    int? limit,
    int? offset,
    bool? isBlacklist,
    String? search,
  }) async {
    var args = <String>[];
    addI("isBlacklist", (isBlacklist ?? false) ? 1 : 0, args);
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addS("search", search, args);
    addD("start", startVoted, args);
    addD("end", endVoted, args);
    addSecret(args);

    final obj = await get(["users", "$uid", "prefs", "users"], args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, UserPrefUser.fromJson);
  }

  static Future<List<UserPrefPost>> getUserPrefPosts({
    int? uid,
    int? upvotes,
    int? downvotes,
    List<String>? location,
    DateTime? startVoted,
    DateTime? endVoted,
    SortOrder? order,
    int? limit,
    int? offset,
    String? search,
  }) async {
    var args = <String>[];
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addS("search", search, args);
    addL("location", location, args);
    addD("start", startVoted, args);
    addD("end", endVoted, args);
    addSecret(args);

    final obj = await get(["users", "$uid", "prefs", "posts"], args);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      final list = obj["payload"];
      var result = <UserPrefPost>[];
      var uncached = <int>[];
      for (final item in list) {
        final p = UserPrefPost.fromJson(item);
        result.add(p);
        uncached.addAll(p.post.tags);
      }
      await Tag.cacheTags(uncached);
      return result;
    }
  }

  static Future<List<UserPrefComment>> getUserPrefComments({
    int? uid,
    int? upvotes,
    int? downvotes,
    DateTime? startVoted,
    DateTime? endVoted,
    SortOrder? order,
    int? limit,
    int? offset,
    String? search,
    bool? isReview,
  }) async {
    var args = <String>[];
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addS("search", search, args);
    addI("isReview", isReview == true ? 1 : 0, args);
    addD("start", startVoted, args);
    addD("end", endVoted, args);
    addSecret(args);

    final obj = await get(["users", "$uid", "prefs", "comments"], args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, UserPrefComment.fromJson);
  }

  static Future<List<UserPrefTag>> getUserPrefTags({
    int? uid,
    int? upvotes,
    int? downvotes,
    DateTime? startVoted,
    DateTime? endVoted,
    SortOrder? order,
    int? limit,
    int? offset,
    String? search,
  }) async {
    var args = <String>[];
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addS("search", search, args);
    addD("start", startVoted, args);
    addD("end", endVoted, args);
    addSecret(args);

    final obj = await get(["users", "$uid", "prefs", "tags"], args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, UserPrefTag.fromJson);
  }

  static Future<List<Post>> getUserContPost({
    required int uid,
    required UserContKind kind,
    int? upvotes,
    int? downvotes,
    List<String>? location,
    DateTime? startCreated,
    DateTime? endCreated,
    SortOrder? order,
    required int limit,
    required int offset,
    String? search,
  }) async {
    var args = <String>[];
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addS("search", search, args);
    addD("start", startCreated, args);
    addD("end", endCreated, args);
    addL("location", location, args);
    addSecret(args);

    var path = ["users", "$uid", "content", "posts"];
    if (kind == UserContKind.viewed) {
      path.add("viewed");
    } else if (kind == UserContKind.readLater) {
      path.add("read-later");
    }

    final obj = await get(path, args);
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
        uncached.addAll(p.tags);
      }
      await Tag.cacheTags(uncached);
      return result;
    }
  }

  static Future<List<Comment>> getUserContComments({
    required int uid,
    int? upvotes,
    int? downvotes,
    DateTime? startCreated,
    DateTime? endCreated,
    SortOrder? order,
    required int limit,
    required int offset,
    String? search,
    bool? isReview,
  }) async {
    var args = <String>[];
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addS("search", search, args);
    addD("start", startCreated, args);
    addD("end", endCreated, args);
    addS("isReview", isReview == true ? "1" : "0", args);

    final obj = await get(["users", "$uid", "content", "comments"], args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, Comment.fromJson);
  }

  static Future<List<Author>> getUserContUsers(
    int uid,
    UserContKind kind,
    int limit,
    int offset, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    late List<String> path;
    if (kind == UserContKind.userFollow) {
      path = ["users", "$uid", "content", "user-follows"];
    } else {
      path = ["users", "$uid", "content", "ignored"];
    }
    var args = <String>[];
    addD("start", startDate, args);
    addD("end", endDate, args);
    addI("limit", limit, args);
    addI("offset", offset, args);
    addSecret(args);
    final obj = await get(path, args);
    if (obj == null) {
      throw unknownError;
    }
    return handlePayload(obj, Author.fromJson);
  }

  static Future<List<Tag>> getUserContTag(
    int uid,
    UserContKind kind,
    int limit,
    int offset, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    late List<String> path;
    if (kind == UserContKind.tagFollow) {
      path = ["users", "$uid", "content", "tag-follows"];
    }
    var args = <String>[];
    addD("start", startDate, args);
    addD("end", endDate, args);
    addI("limit", limit, args);
    addI("offset", offset, args);
    addSecret(args);
    final obj = await get(path, args);
    if (obj == null) {
      throw unknownError;
    }
    return handlePayload(obj, Tag.fromJson);
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
      SortOrder? order,
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
    addSO("order", order, args);
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
        uncached.addAll(p.tags);
      }
      await Tag.cacheTags(uncached);
      return result;
    }
  }

  static Future<List<Post>> getSimilarPost(
    int uid, {
    int? postId,
    DateTime? start,
    DateTime? end,
    SortOrder? order,
    int? offset,
    int? limit,
  }) async {
    var args = <String>[];
    addD("start", start, args);
    addD("end", end, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addI("pid", postId, args);

    final obj = await get(["users", "$uid", "recommend"], args);
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
        uncached.addAll(p.tags);
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
      SortOrder? order,
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
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addD("start", start, args);
    addD("end", end, args);
    addS("search", search, args);

    final obj = await get(["tags"], args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, Tag.fromJson);
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
      SortOrder? order,
      int? limit,
      int? offset,
      DateTime? start,
      DateTime? end,
      int? forUser,
      int? isReview,
      String? search}) async {
    var args = <String>[];
    addI("uid", userId, args);
    addI("pid", postId, args);
    addI("reply", replyId, args);
    addL("popularIn", popularIn, args);
    addI("upvotes", upvotes, args);
    addI("downvotes", downvotes, args);
    addSO("order", order, args);
    addI("offset", offset, args);
    addI("limit", limit, args);
    addD("start", start, args);
    addD("end", end, args);
    addD("startCreated", startCreated, args);
    addD("endCreated", endCreated, args);
    addI("for", forUser, args);
    addI("isReview", isReview, args);
    addS("search", search, args);

    final obj = await get(["posts", "comments"], args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, Comment.fromJson);
  }

  //----------------------------------------------------------------------------
  // Vote
  //----------------------------------------------------------------------------
  static Future<List<String>> getCurrentLocation() async {
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        return [];
      }
      var enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return [];
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return [];
        }
      }
      final loc = await Geolocator.getCurrentPosition();
      final places =
          await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (places.isNotEmpty) {
        final place = places[0];
        var result = <String>[];
        if (place.isoCountryCode != null) {
          result.add(place.isoCountryCode!);
          if (place.administrativeArea != null) {
            result.add(place.administrativeArea!);
          }
        }
        return result;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<int> voteForPost({
    required int postId,
    required int userId,
    required int amount,
  }) async {
    var args = <String>[];
    addSecret(args);
    final location = await getCurrentLocation();
    final body = {
      "uid": userId,
      "amount": amount,
      "location": location,
    };
    final obj = await post(["posts", "$postId"], args, body);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return obj["payload"];
    }
  }

  static Future<int> voteForComment({
    required int postId,
    required int commentId,
    required int userId,
    required int amount,
  }) async {
    var args = <String>[];
    addSecret(args);
    final path = ["posts", "$postId", "comments", "$commentId"];
    final location = await getCurrentLocation();
    final body = {
      "uid": userId,
      "amount": amount,
      "location": location,
    };
    final obj = await post(path, args, body);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return obj["payload"];
    }
  }

  static Future<bool> watchPost(int uid, int pid, int amount) async {
    var args = <String>[];
    addSecret(args);
    final obj =
        await post(["users", "$uid", "watch", "$pid"], args, {"time": amount});
    print("watch $pid");
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == false) {
      throw err(obj["reason"]);
    } else {
      return true;
    }
  }

  static Future<bool> addUserCont({
    required int uid,
    required UserContKind kind,
    required int pid,
  }) async {
    if (uid == pid) {
      return Future(() => false);
    }
    final List<String> path;
    switch (kind) {
      case UserContKind.created:
        return Future(() => false);
      case UserContKind.viewed:
        path = ["users", "$uid", "content", "posts", "viewed"];
        break;
      case UserContKind.readLater:
        path = ["users", "$uid", "content", "posts", "read-later"];
        break;
      case UserContKind.userFollow:
        path = ["users", "$uid", "content", "user-follows"];
        break;
      case UserContKind.ignored:
        path = ["users", "$uid", "content", "ignored"];
        break;
      case UserContKind.userRecommend:
        return false;
      case UserContKind.tagFollow:
        path = ["users", "$uid", "content", "tag-follows"];
        break;
    }

    var args = <String>[];
    addSecret(args);

    final obj = await post(path, args, {"pid": pid});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == true) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> onboardCurrentUser(
    List<int> tags,
    List<int> users,
  ) async {
    if (User.current == null) {
      return false;
    }
    final path = ["users", "${User.current!.id}", "content", "onboard"];
    final obj = await post(path, [], {"tags": tags, "users": users});
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == true) {
      final json = obj["payload"];
      final t = jsonArrayTo(json["tags"], Tag.fromJson);
      final u = jsonArrayTo(json["following"], Author.fromJson);
      User.current?.following = u;
      User.current?.favourites = t;
      return true;
    } else {
      return false;
    }
  }

  static Future<Map<String, int>> onboardAgents() async {
    final path = ["onboard", "agents"];
    final obj = await get(path, []);
    if (obj == null) {
      throw unknownError;
    }
    if (obj["success"] == true) {
      return (obj["payload"] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int));
    } else {
      return {};
    }
  }

  static Future<Map<String, int>> onboardTags() async {
    final path = ["onboard", "tags"];
    final obj = await get(path, []);
    if (obj == null) {
      throw unknownError;
    }
    if (obj["success"] == true) {
      return (obj["payload"] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int));
    } else {
      return {};
    }
  }

  static Future<bool> refreshUserContRecommendations(
      int uid, List<int> pids) async {
    final path = ["users", "$uid", "content", "recommendations"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {"pid": pids});
    if (obj["success"] == true) {
      return true;
    } else {
      return false;
    }
  }

  static Future<int?> purchaseCredit(int uid, int amount) async {
    final path = ["credits", "$uid"];
    var args = <String>[];
    addSecret(args);

    final obj = await post(path, args, {"amount": amount});
    if (obj["success"] == true) {
      return obj["payload"];
    } else {
      return null;
    }
  }

  static Future<bool> deleteUserCont(
      int uid, int pid, UserContKind kind) async {
    late List<String> path;
    switch (kind) {
      case UserContKind.viewed:
        path = ["trash", "users", "$uid", "content", "posts", "viewed", "$pid"];
        break;
      case UserContKind.readLater:
        path = [
          "trash",
          "users",
          "$uid",
          "content",
          "posts",
          "read-later",
          "$pid"
        ];
        break;
      case UserContKind.userFollow:
        path = ["trash", "users", "$uid", "content", "user-follows", "$pid"];
        break;
      case UserContKind.ignored:
        path = ["trash", "users", "$uid", "content", "ignored", "$pid"];
        break;
      case UserContKind.created:
        return Future(() => false);
      case UserContKind.userRecommend:
        return Future(() => false);
      case UserContKind.tagFollow:
        path = ["trash", "users", "$uid", "content", "tag-follows", "$pid"];
        break;
    }

    var args = <String>[];
    addSecret(args);

    final obj = await delete(path, args);
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == true) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> deletePost(int pid) async {
    final path = ["trash", "posts", "$pid"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {});
    if (obj == null) {
      throw unknownError;
    }
    return obj["success"];
  }

  static Future<bool> deleteComment(int pid, int sid) async {
    final path = ["trash", "posts", "$pid", "comments", "$sid"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {});
    if (obj == null) {
      throw unknownError;
    }
    return obj["success"];
  }

  //----------------------------------------------------------------------------
  // Flags
  //----------------------------------------------------------------------------
  static Future<bool> createFlag(
    int uid,
    int pid,
    int sid,
    FlagReason kind,
    String reason,
  ) async {
    var path = ["flags"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {
      "uid": uid,
      "pid": pid,
      "sid": sid,
      "kind": kind.index,
      "reason": reason
    });
    if (obj == null) {
      throw unknownError;
    }

    if (obj["success"] == true) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<FlaggedPost>> getFlaggedPosts(
      FlagReason kind, int limit, int offset) async {
    var path = ["flags", "posts"];
    var args = <String>[];
    addI("kind", kind.index, args);
    addI("limit", limit, args);
    addI("offset", offset, args);
    addSecret(args);

    final obj = await get(path, args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, FlaggedPost.fromJson);
  }

  static Future<List<FlaggedComment>> getFlaggedComments(
      FlagReason kind, int limit, int offset) async {
    var path = ["flags", "comments"];
    var args = <String>[];
    addI("kind", kind.index, args);
    addI("limit", limit, args);
    addI("offset", offset, args);
    addSecret(args);

    final obj = await get(path, args);
    if (obj == null) {
      throw unknownError;
    }

    return handlePayload(obj, FlaggedComment.fromJson);
  }

  static Future<bool> handleFlag(
      int id, int pid, int sid, FlagHandle action) async {
    var path = ["trash", "flags", "$id"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(
        path, [], {"pid": pid, "sid": sid, "action": flagHandleKind(action)});
    if (obj == null) {
      throw unknownError;
    }

    return obj["success"];
  }

  //----------------------------------------------------------------------------
  // News Agent
  //----------------------------------------------------------------------------
  static Future<List<NewsAgent>> getAgents() async {
    final path = ["agents"];
    var args = <String>[];
    addSecret(args);
    final obj = await get(path, args);
    if (obj == null) {
      throw unknownError;
    }
    return handlePayload(obj, NewsAgent.fromJson);
  }

  static Future<bool> updateAgents() async {
    final path = ["all-agents"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {});
    if (obj == null) {
      throw unknownError;
    }
    return true;
  }

  static Future<bool> updateAgent(int aid) async {
    final path = ["agents", "$aid"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {});
    if (obj == null) {
      throw unknownError;
    }
    return true;
  }

  static Future<bool> deleteAgent(int aid) async {
    final path = ["trash", "agents", "$aid"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {});
    if (obj == null) {
      throw unknownError;
    }
    return true;
  }

  static Future<NewsAgent> editAgent(
      int aid, String name, String origin) async {
    final path = ["update", "agents", "$aid"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {"name": name, "origin": origin});
    if (obj == null) {
      throw unknownError;
    }
    if (obj["success"] == false) {
      throw unknownError;
    } else {
      return NewsAgent.fromJson(obj["payload"]);
    }
  }

  static Future<NewsAgent> createAgent(String name, String origin) async {
    final path = ["agents"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {"name": name, "origin": origin});
    if (obj == null) {
      throw unknownError;
    }
    if (obj["success"] == false) {
      throw unknownError;
    } else {
      return NewsAgent.fromJson(obj["payload"]);
    }
  }

  static Future<NewsAgent> editSubAgent(int aid, String sub,
      {required bool add}) async {
    final path = ["agents", "$aid", "sub"];
    var args = <String>[];
    addSecret(args);
    final obj = await post(path, args, {"sub": (add ? "+" : "-") + sub});
    if (obj == null) {
      throw unknownError;
    }
    if (obj["success"] == false) {
      throw unknownError;
    } else {
      return NewsAgent.fromJson(obj["payload"]);
    }
  }
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
final contentLengthTooLong = err("Message length too long");

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

void addSO(String name, SortOrder? value, List<String> args) {
  if (value != null) {
    args.add(name);
    args.add(sortOrderToString(value));
  }
}

void addSecret(List<String> args) {
  if (User.current?.secret != null) {
    args.add("secret");
    args.add(User.current!.secret);
  }
}

enum UserContKind {
  created,
  viewed,
  readLater,
  userFollow,
  ignored,
  userRecommend,
  tagFollow,
}

enum UserPrefKind {
  user,
  comment,
  post,
  tag,
}

enum FlagReason {
  sexual,
  violent,
  hateful,
  harassment,
  harmful,
  abuse,
  spam,
  other,
}

enum FlagHandle {
  ignore,
  ignoreAll,
  remove,
  report,
  block1,
  block2,
  block7,
  block14,
  block21,
  block28,
  perm,
}

enum SortOrder {
  score,
  cred,
  upvotes,
  downvotes,
  controversial,
  createdAt,
  updatedAt,
  updatedOn,
  addedOn,
  rank,
}

enum UserVoteKind {
  post,
  review,
  comment,
}

List<SortOrder> sortOrdersExcluding(List<SortOrder> exclude) {
  var result = SortOrder.values;
  result.removeWhere((element) => exclude.contains(element));
  return result;
}

List<SortOrder> sortOrdersIncluding(List<SortOrder> include) {
  return [
    SortOrder.score,
    SortOrder.cred,
    SortOrder.controversial,
    SortOrder.upvotes,
    SortOrder.downvotes,
    ...include,
  ];
}

String sortOrderToString(SortOrder so) {
  switch (so) {
    case SortOrder.score:
      return "score";
    case SortOrder.cred:
      return "cred";
    case SortOrder.upvotes:
      return "upvotes";
    case SortOrder.downvotes:
      return "downvotes";
    case SortOrder.controversial:
      return "controversial";
    case SortOrder.createdAt:
      return "createdat";
    case SortOrder.updatedAt:
      return "updatedat";
    case SortOrder.updatedOn:
      return "updatedon";
    case SortOrder.addedOn:
      return "addedon";
    case SortOrder.rank:
      return "rank";
  }
}

String sortOrderPresentation(SortOrder so) {
  switch (so) {
    case SortOrder.score:
      return "Score";
    case SortOrder.cred:
      return "Credibility";
    case SortOrder.upvotes:
      return "Upvotes";
    case SortOrder.downvotes:
      return "Downvotes";
    case SortOrder.controversial:
      return "Controversial";
    case SortOrder.createdAt:
      return "Newly Created";
    case SortOrder.updatedAt:
      return "Recently Updated";
    case SortOrder.updatedOn:
      return "Recently Updated";
    case SortOrder.addedOn:
      return "Recently Added";
    case SortOrder.rank:
      return "Relevance";
  }
}

String flagReasonToString(FlagReason fr) {
  switch (fr) {
    case FlagReason.sexual:
      return "Sexual Content";
    case FlagReason.violent:
      return "Violent Content";
    case FlagReason.hateful:
      return "Hateful Content";
    case FlagReason.harassment:
      return "Harassing Content";
    case FlagReason.harmful:
      return "Harmful Content";
    case FlagReason.abuse:
      return "Abusive Content";
    case FlagReason.spam:
      return "Spam";
    case FlagReason.other:
      return "Other";
  }
}

Map<int, String> flagSet() {
  var result = <int, String>{};
  for (final fr in FlagReason.values) {
    result[fr.index] = flagReasonToString(fr);
  }
  return result;
}

String flagHandleKind(FlagHandle handle) {
  switch (handle) {
    case FlagHandle.ignore:
      return "ignore";
    case FlagHandle.ignoreAll:
      return "ignore_all";
    case FlagHandle.report:
      return "report";
    case FlagHandle.remove:
      return "remove";
    case FlagHandle.block1:
      return "block1";
    case FlagHandle.block2:
      return "block2";
    case FlagHandle.block7:
      return "block7";
    case FlagHandle.block14:
      return "block14";
    case FlagHandle.block21:
      return "block21";
    case FlagHandle.block28:
      return "block28";
    case FlagHandle.perm:
      return "perm";
  }
}

String userVoteKindToString(UserVoteKind uvk) {
  switch (uvk) {
    case UserVoteKind.post:
      return "Post";
    case UserVoteKind.review:
      return "Review";
    case UserVoteKind.comment:
      return "Comment";
  }
}

num controversial(num cred) {
  var diff = cred - 0.5;
  if (diff < 0) {
    diff = -diff;
  }
  if (diff == 0) {
    return 9e90;
  }
  return 1 / diff;
}
