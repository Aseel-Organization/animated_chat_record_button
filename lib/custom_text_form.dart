import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

class CustomTextForm extends StatefulWidget {
  const CustomTextForm({
    super.key,
    this.border = 20,
    this.boxFillColor = const Color.fromARGB(255, 217, 214, 214),
    this.hinText = 'Email',
    this.isPasss = false,
    this.controller,
    this.validate,
    this.keyBoardType,
    this.autoFocus = false,
    this.cursorOpacityAanimation = true,
    this.cursorHight = 30,
    this.cursorWidth = 2,
    this.cursorRadius = 20,
    this.cursorColor = Colors.grey,
    this.inputDecoration,
    this.suffixIcon,
    this.preffixIcon,
    this.contentPading,
    this.hintStyle,
    this.focusNode,
    this.enteredTextStyle,
    this.onChanged,
    this.onSupmit,
  });
  final bool isPasss;

  final double border;
  final Color boxFillColor;
  final String hinText;
  final TextEditingController? controller;
  final String? Function(String? val)? validate;
  final TextInputType? keyBoardType;
  final bool autoFocus;
  final bool cursorOpacityAanimation;
  final double cursorHight;
  final double cursorWidth;
  final double cursorRadius;
  final Color cursorColor;
  final InputDecoration? inputDecoration;
  final Widget? suffixIcon;
  final Widget? preffixIcon;
  final EdgeInsets? contentPading;
  final TextStyle? hintStyle;
  final FocusNode? focusNode;
  final TextStyle? enteredTextStyle;
  final Function(String)? onChanged;
  final Function(String)? onSupmit;

  @override
  State<CustomTextForm> createState() => _CustomTextFormState();
}

class _CustomTextFormState extends State<CustomTextForm> {
  FocusNode myFocusNode = FocusNode();
  bool isFilled = true;
  @override
  void initState() {
    super.initState();
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        setState(() {
          isFilled = false;
        });
      } else {
        setState(() {
          isFilled = true;
          myFocusNode.unfocus();
        });
      }
    });
  }

  // final globalFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // textAlign: TextAlign.justify,
      textAlignVertical: TextAlignVertical.center,
      // style: TextStyle(height: 3.55.rH),
      onFieldSubmitted: widget.onSupmit,
      onChanged: widget.onChanged,
      validator: widget.validate,
      style: widget.enteredTextStyle ?? const TextStyle(),
      focusNode: widget.focusNode ?? myFocusNode,
      keyboardType: widget.keyBoardType ?? TextInputType.text,
      obscureText: widget.isPasss ? true : false,
      controller: widget.controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: widget.cursorColor,
      cursorErrorColor: Colors.grey,
      cursorHeight: widget.cursorHight,
      cursorWidth: widget.cursorWidth,
      cursorOpacityAnimates: widget.cursorOpacityAanimation,
      cursorRadius: Radius.circular(widget.cursorRadius),
      autofocus: widget.autoFocus,
      enableSuggestions: true,


      decoration: widget.inputDecoration ??
          InputDecoration(
              contentPadding: widget.contentPading ??
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              filled: true,
              suffixIcon: widget.suffixIcon,
              fillColor: widget.boxFillColor,
              prefixIcon: widget.preffixIcon,
              errorMaxLines: 1,
              hintText: widget.hinText,
              hintStyle: widget.hintStyle ??
                  const TextStyle(
                    color: Colors.grey,
                  ),
              prefixIconConstraints: const BoxConstraints(
                minHeight: 20,
                minWidth: 40,
              ),
              // counterStyle: TextStyle(color: Colors.blue),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(widget.border),
              )),
    );
  }
}

class PasswordTextForm extends StatefulWidget {
  const PasswordTextForm({
    super.key,
    this.border = 20,
    this.boxFillColor = const Color.fromARGB(255, 217, 214, 214),
    this.hinText = 'Password',
    this.controller,
    this.validate,
    this.keyBoardType,
    this.autoFocus = false,
    this.cursorOpacityAanimation = true,
    this.cursorHight = 30,
    this.cursorWidth = 2,
    this.cursorRadius = 20,
    this.cursorColor = Colors.grey,
    this.inputDecoration,
  });

  final double border;
  final Color boxFillColor;
  final String hinText;
  final TextEditingController? controller;
  final String? Function(String? val)? validate;
  final TextInputType? keyBoardType;
  final bool autoFocus;
  final bool cursorOpacityAanimation;
  final double cursorHight;
  final double cursorWidth;
  final double cursorRadius;
  final Color cursorColor;
  final InputDecoration? inputDecoration;
  @override
  State<PasswordTextForm> createState() => _PasswordTextFormState();
}

class _PasswordTextFormState extends State<PasswordTextForm> {
  FocusNode myFocusNode = FocusNode();
  bool isFilled = true;
  @override
  void initState() {
    super.initState();
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        setState(() {
          isFilled = false;
        });
      } else {
        setState(() {
          isFilled = true;
          myFocusNode.unfocus();
        });
      }
    });
  }

  bool _see = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: widget.validate,
      focusNode: myFocusNode,
      keyboardType: widget.keyBoardType ?? TextInputType.text,
      obscureText: _see,
      controller: widget.controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: widget.cursorColor,
      cursorErrorColor: Colors.grey,
      cursorHeight: widget.cursorHight,
      cursorWidth: widget.cursorWidth,
      cursorOpacityAnimates: widget.cursorOpacityAanimation,
      cursorRadius: Radius.circular(widget.cursorRadius),
      autofocus: widget.autoFocus,
      enableSuggestions: true,
      decoration: widget.inputDecoration ??
          InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              filled: true,
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: 25),
                child: InkWell(
                    onTap: () {
                      _see
                          ? setState(() {
                              _see = false;
                            })
                          : setState(() {
                              _see = true;
                            });
                    },
                    child: _see
                        ? const Icon(Icons.visibility_off)
                        : const Icon(Icons.visibility)),
              ),
              fillColor: widget.boxFillColor,
              errorMaxLines: 1,
              hintText: widget.hinText,
              hintStyle: const TextStyle(color: Colors.grey),
              // counterStyle: TextStyle(color: Colors.blue),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(widget.border),
              )),
    );
  }
}
