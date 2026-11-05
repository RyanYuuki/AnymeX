import 'dart:async';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppsEventsScreen extends StatefulWidget {
  @override
  _AppsEventsScreenState createState() => _AppsEventsScreenState();
}

class _AppsEventsScreenState extends State<AppsEventsScreen> {
  final List<ApplicationEvent> _events = <ApplicationEvent>[];
  late StreamSubscription<ApplicationEvent> _subscription;

  @override
  void initState() {
    super.initState();

    _subscription =
        DeviceApps.listenToAppsChanges().listen((ApplicationEvent event) {
      setState(() {
        _events.add(event);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applications events'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Visibility(
            visible: _events.isNotEmpty,
            child: _EventsList(events: _events),
          ),
          Visibility(
            visible: _events.isEmpty,
            child: const _EmptyList(),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _EventsList extends StatelessWidget {
  final Iterable<ApplicationEvent> _events;

  _EventsList({required List<ApplicationEvent> events})
      : _events = events.reversed;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int position) {
          return KeyedSubtree(
              key: Key('$position'),
              child: _AppEventItem(event: _events.elementAt(position)));
        },
        itemCount: _events.length,
      ),
    );
  }
}

class _AppEventItem extends StatelessWidget {
  final ApplicationEvent event;

  _AppEventItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(event.packageName),
          subtitle: _AppEventItemType(event.event),
          leading: Text('${event.time.hour}:${event.time.minute}'),
        ),
        const Divider()
      ],
    );
  }
}

class _AppEventItemType extends StatelessWidget {
  final String _type;

  _AppEventItemType(ApplicationEventType type)
      : _type = _extractEventTypeName(type);

  static String _extractEventTypeName(ApplicationEventType type) {
    switch (type) {
      case ApplicationEventType.installed:
        return 'Installed';
      case ApplicationEventType.updated:
        return 'Updated';
      case ApplicationEventType.uninstalled:
        return 'Uninstalled';
      case ApplicationEventType.enabled:
        return 'Enabled';
      case ApplicationEventType.disabled:
        return 'Disabled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_type);
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('No event yet!'));
  }
}
