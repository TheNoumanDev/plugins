// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const UrlLauncherTvosApp());
}

class UrlLauncherTvosApp extends StatelessWidget {
  const UrlLauncherTvosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'url_launcher tvOS example',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // tvOS has no in-app browser, so only external launches do anything: an app
  // URL scheme (or universal link) that another installed app can handle. This
  // example registers `ullauncherdemo://` for itself in tvos/Runner/Info.plist,
  // so the app-scheme launch below actually hands off. A plain web URL has
  // nothing to open on tvOS.
  static final Uri _appScheme = Uri.parse('ullauncherdemo://demo');
  static final Uri _webUrl = Uri.parse('https://flutter.dev');

  String _status = 'Pick an action with the Siri Remote.';

  void _show(String message) => setState(() => _status = message);

  Future<void> _canLaunch(Uri url) async {
    try {
      final bool can = await canLaunchUrl(url);
      // On tvOS canLaunchUrl can report true for a web URL that nothing will
      // actually open — rely on the launchUrl result, not this.
      _show('canLaunchUrl($url) = $can');
    } catch (e) {
      _show('canLaunchUrl($url) threw: $e');
    }
  }

  Future<void> _launch(Uri url, LaunchMode mode) async {
    try {
      final bool ok = await launchUrl(url, mode: mode);
      _show('launchUrl($url, $mode) = $ok');
    } catch (e) {
      _show('launchUrl($url, $mode) threw: $e');
    }
  }

  Future<void> _showSupport() async {
    final bool external =
        await supportsLaunchMode(LaunchMode.externalApplication);
    final bool inApp = await supportsLaunchMode(LaunchMode.inAppBrowserView);
    _show('supportsLaunchMode: external=$external  inAppBrowser=$inApp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('url_launcher · tvOS')),
      body: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(_status, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 12),
            const Text(
              'In-app browser modes are unsupported on tvOS (no SafariServices) '
              'and fall back to an external launch.',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              autofocus: true,
              onPressed: () =>
                  _launch(_appScheme, LaunchMode.externalApplication),
              child: const Text('Launch app scheme (ullauncherdemo://)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _launch(_webUrl, LaunchMode.externalApplication),
              child: const Text('Launch web URL (no browser → false)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              // Requesting the in-app browser: on tvOS this falls back to an
              // external launch instead of throwing.
              onPressed: () => _launch(_webUrl, LaunchMode.inAppBrowserView),
              child: const Text('Launch web URL in-app mode (falls back)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _canLaunch(_webUrl),
              child: const Text('canLaunchUrl (web — may lie, returns true)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showSupport,
              child: const Text('supportsLaunchMode readout'),
            ),
          ],
        ),
      ),
    );
  }
}
