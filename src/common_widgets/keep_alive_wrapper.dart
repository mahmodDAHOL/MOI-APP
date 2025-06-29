import 'package:flutter/material.dart';

class KeepAliveWrapper extends StatelessWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _KeepAlive(child: child);
  }
}

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => __KeepAliveState();
}

class __KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}