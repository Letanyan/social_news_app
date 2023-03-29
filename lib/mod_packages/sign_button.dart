import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/locale.dart';

// ignore: must_be_immutable
class SignInButton extends StatelessWidget {
  //required
  /// [buttonType] sets the style and icons of the button.
  ButtonType buttonType;

  //required
  /// [onPressed] Send a function to trigger the button.
  VoidCallback? onPressed;

  //not required, default left
  /// [imagePosition] set the position of the icon.(left or right)
  ImagePosition? imagePosition;

  //not required, default 5.0
  /// [elevation] set the button's elevation value.
  double elevation;

  //not required, default small
  /// [buttonSize] set the size of the button. (small medium large)
  ButtonSize buttonSize;

  //not required, Gets value according to buttonType.
  /// [btnColor] Set the background color of the button.
  Color? btnColor;

  //not required, Gets value according to buttonType.
  /// [btnDisabledColor] Set the background color of the disabled button.
  Color? btnDisabledColor;

  //not required, Gets value according to buttonType.
  /// [btnTextColor] set the button's text color.
  Color? btnTextColor;

  //not required, Gets value according to buttonType.
  /// [btnDisabledTextColor] set the disabled button's text color.
  Color? btnDisabledTextColor;

  //not required, Gets value according to buttonType.
  /// [btnText] set the button's text.
  String? btnText;

  //not required, Gets value according to buttonSize.
  /// You can change the value of [width] when the text size becomes too small.
  double? width;

  //not required, Gets value according to buttonSize.
  /// [padding] set the button's padding value.
  double? padding;

  /// [_image] value cannot be assigned.Gets value according to [buttonType].
  Widget? _image;

  /// [_fontSize] value cannot be assigned.Gets value according to [buttonSize].
  double? _fontSize;

  /// [_imageSize] value cannot be assigned.Gets value according to [buttonSize].
  double? _imageSize;

  //not required, button shape.
  /// [shape] set the button's shape.
  ShapeBorder? shape;

  //not required, button model.
  /// [mini] It automatically takes value according to the selected constructor.
  bool mini;

  SignInButton({
    super.key,
    required this.buttonType,
    required this.onPressed,
    this.imagePosition = ImagePosition.left,
    this.buttonSize = ButtonSize.small,
    this.btnColor,
    this.btnDisabledColor,
    this.btnTextColor,
    this.btnDisabledTextColor,
    this.btnText,
    this.elevation = 5.0,
    this.width,
    this.padding,
    this.shape,
  }) : mini = false;

  SignInButton.mini({
    required this.buttonType,
    required this.onPressed,
    this.buttonSize = ButtonSize.small,
    this.btnColor,
    this.btnDisabledColor,
    this.elevation = 5.0,
    this.padding,
  }) : mini = true;

  bool get _enabled => onPressed != null;

  bool get _disabled => !_enabled;

  @override
  Widget build(BuildContext context) {
    _setButtonSize();
    _createStyle(context);
    return !mini
        ? MaterialButton(
            color: btnColor,
            disabledColor: btnDisabledColor,
            shape: shape ?? const StadiumBorder(),
            onPressed: onPressed,
            elevation: elevation,
            child: SizedBox(
              width: width,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: imagePosition == ImagePosition.left
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.all(padding!),
                    child:
                        imagePosition == ImagePosition.left ? _image : _text(),
                  ),
                  Padding(
                    padding: EdgeInsets.all(padding!),
                    child:
                        imagePosition == ImagePosition.left ? _text() : _image,
                  ),
                ],
              ),
            ),
          )
        : MaterialButton(
            onPressed: onPressed,
            color: btnColor,
            disabledColor: btnDisabledColor,
            elevation: elevation,
            padding: EdgeInsets.all(padding!),
            shape: const CircleBorder(),
            child: _image,
          );
  }

  Widget _text() {
    return Text(
      btnText!,
      style: TextStyle(
        fontSize: _fontSize,
        color: _enabled ? btnTextColor : btnDisabledTextColor,
      ),
    );
  }

  void _setButtonSize() {
    if (buttonSize == ButtonSize.small) {
      padding ??= !mini ? 5.0 : 6.0;
      width ??= TRGeneral.signInButtonWidth;
      _fontSize = 15.0;
      _imageSize = !mini ? 24.0 : 30.0;
    } else if (buttonSize == ButtonSize.medium) {
      padding ??= !mini ? 5.5 : 6.5;
      width ??= TRGeneral.signInButtonWidth + 20;
      _fontSize = 17.0;
      _imageSize = !mini ? 28.0 : 34.0;
    } else {
      padding ??= !mini ? 6.0 : 7.0;
      width ??= TRGeneral.signInButtonWidth + 50;
      _fontSize = 19.0;
      _imageSize = !mini ? 32.0 : 38.0;
    }
  }

  void _createStyle(BuildContext context) {
    btnDisabledColor ??= Theme.of(context).disabledColor.withOpacity(0.12);
    btnDisabledTextColor ??= Theme.of(context).disabledColor.withOpacity(0.38);

    if (buttonType == ButtonType.email ||
        buttonType == ButtonType.emailDark ||
        buttonType == ButtonType.account ||
        buttonType == ButtonType.accountDark) {
      _image = Icon(
        Icons.email,
        color:
            buttonType == ButtonType.email || buttonType == ButtonType.account
                ? Colors.grey[800]
                : Colors.grey[300],
        size: _imageSize,
      );
    } else if (buttonType == ButtonType.anon ||
        buttonType == ButtonType.anonDark) {
      _image = Icon(
        Icons.free_breakfast,
        color:
            buttonType == ButtonType.anon ? Colors.grey[800] : Colors.grey[300],
        size: _imageSize,
      );
    } else {
      _image = Image.asset(
        'assets/logos/${describeEnum(buttonType)}.png',
        width: _imageSize,
        height: _imageSize,
      );
    }

    if (_disabled) {
      _image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: _image,
      );
    }

    switch (buttonType) {
      case ButtonType.facebook:
        btnText ??= TRGeneral.signInWith("Facebook");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF1877F2);
        break;

      case ButtonType.facebookDark:
        btnText ??= TRGeneral.signInWith("Facebook");
        btnTextColor ??= Colors.white;
        btnColor ??= Colors.black;
        break;

      case ButtonType.github:
        btnText ??= TRGeneral.signInWith("Github");
        btnTextColor ??= Colors.black87;
        btnColor ??= Colors.white;
        break;

      case ButtonType.githubDark:
        btnText ??= TRGeneral.signInWith("Github");
        btnTextColor ??= Colors.white70;
        btnColor ??= const Color(0xff212121);
        break;

      case ButtonType.pinterest:
        btnText ??= TRGeneral.signInWith("Pinterest");
        btnTextColor ??= Colors.white;
        btnColor ??= Colors.redAccent;
        break;

      case ButtonType.apple:
        btnText ??= TRGeneral.signInWith("Apple");
        btnTextColor ??= Colors.black;
        btnColor ??= const Color(0xfff7f7f7);
        break;

      case ButtonType.appleDark:
        btnText ??= TRGeneral.signInWith("Apple");
        btnTextColor ??= Colors.white;
        btnColor ??= Colors.black;
        break;

      case ButtonType.twitter:
        btnText ??= TRGeneral.signInWith("Twitter");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF1DA1F2);
        break;

      case ButtonType.linkedin:
        btnText ??= TRGeneral.signInWith("LinkedIn");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF3282B8);
        break;

      case ButtonType.google:
        btnText ??= TRGeneral.signInWith("Google");
        btnTextColor ??= Colors.black;
        btnColor ??= const Color(0xfff7f7f7);
        break;

      case ButtonType.googleDark:
        btnText ??= TRGeneral.signInWith("Google");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF4285F4);
        break;

      case ButtonType.youtube:
        btnText ??= TRGeneral.signInWith("Youtube");
        btnTextColor ??= Colors.black;
        btnColor ??= Colors.white;
        break;

      case ButtonType.microsoft:
        btnText ??= TRGeneral.signInWith("Microsoft");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF2F2F2F);
        break;

      case ButtonType.tumblr:
        btnText ??= TRGeneral.signInWith("Tumblr");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF0F4C75);
        break;

      case ButtonType.email:
        btnText ??= TRGeneral.signInWith("Email");
        btnTextColor ??= Colors.black;
        btnColor ??= Colors.white;
        break;

      case ButtonType.emailDark:
        btnText ??= TRGeneral.signInWith("Email");
        btnTextColor ??= Colors.white;
        btnColor ??= Colors.grey[800];
        break;

      case ButtonType.account:
        btnText ??= TRSignIn.createAccount;
        btnTextColor ??= Colors.black;
        btnColor ??= Colors.white;
        break;

      case ButtonType.accountDark:
        btnText ??= TRSignIn.createAccount;
        btnTextColor ??= Colors.white;
        btnColor ??= Colors.grey[800];
        break;

      case ButtonType.anon:
        btnText ??= TRSignIn.justBrowse;
        btnTextColor ??= Colors.black;
        btnColor ??= Colors.white;
        break;

      case ButtonType.anonDark:
        btnText ??= TRSignIn.justBrowse;
        btnTextColor ??= Colors.white;
        btnColor ??= Colors.grey[800];
        break;

      case ButtonType.mail:
        btnText ??= TRGeneral.signInWith("Mail");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF20639B);
        break;

      case ButtonType.reddit:
        btnText ??= TRGeneral.signInWith("Reddit");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFFC85417);
        break;

      case ButtonType.yahoo:
        btnText ??= TRGeneral.signInWith("Yahoo");
        btnTextColor ??= Colors.white;
        btnColor ??= const Color(0xFF7C5295);
        break;

      case ButtonType.amazon:
        btnText ??= TRGeneral.signInWith("Amazon");
        btnTextColor ??= Colors.black87;
        btnColor ??= Colors.white;
        break;

      case ButtonType.quora:
        btnText ??= TRGeneral.signInWith("Quora");
        btnTextColor ??= Colors.black87;
        btnColor ??= Colors.white;
        break;

      case ButtonType.instagram:
        btnText ??= TRGeneral.signInWith("Instagram");
        btnTextColor ??= Colors.black87;
        btnColor ??= Colors.white;
        break;
    }
  }
}

enum ButtonType {
  facebook,
  facebookDark,
  github,
  githubDark,
  pinterest,
  apple,
  appleDark,
  twitter,
  linkedin,
  google,
  googleDark,
  youtube,
  microsoft,
  tumblr,
  email,
  emailDark,
  account,
  accountDark,
  anon,
  anonDark,
  mail,
  reddit,
  yahoo,
  amazon,
  quora,
  instagram
}

enum ImagePosition {
  left,
  right,
}

enum ButtonSize {
  small,
  medium,
  large,
}
