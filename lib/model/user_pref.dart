import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';

class UserPrefUser {
  final Author author;
  final int upvotes;
  final int downvotes;

  const UserPrefUser({
    required this.author,
    required this.upvotes,
    required this.downvotes,
  });

  factory UserPrefUser.fromJson(Map<String, dynamic> json) {
    return UserPrefUser(
      author: Author.fromJson(json["User"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
    );
  }

  factory UserPrefUser.fromInt(int value) {
    return UserPrefUser(
      author: Author.fromInt(value),
      upvotes: 0,
      downvotes: 0,
    );
  }
}

class UserPrefPost {
  final Post post;
  final int upvotes;
  final int downvotes;

  const UserPrefPost({
    required this.post,
    required this.upvotes,
    required this.downvotes,
  });

  factory UserPrefPost.fromJson(Map<String, dynamic> json) {
    return UserPrefPost(
      post: Post.fromJson(json["Post"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
    );
  }
}

class UserPrefComment {
  final Comment comment;
  final int upvotes;
  final int downvotes;

  const UserPrefComment({
    required this.comment,
    required this.upvotes,
    required this.downvotes,
  });

  factory UserPrefComment.fromJson(Map<String, dynamic> json) {
    return UserPrefComment(
      comment: Comment.fromJson(json["Comment"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
    );
  }
}

class UserPrefTag {
  final Tag tag;
  final int upvotes;
  final int downvotes;

  const UserPrefTag({
    required this.tag,
    required this.upvotes,
    required this.downvotes,
  });

  factory UserPrefTag.fromJson(Map<String, dynamic> json) {
    return UserPrefTag(
      tag: Tag.fromJson(json["Tag"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
    );
  }
}
