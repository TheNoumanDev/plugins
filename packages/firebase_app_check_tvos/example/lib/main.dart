// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppCheckExampleApp());
}

class AppCheckExampleApp extends StatelessWidget {
  const AppCheckExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'firebase_app_check tvOS example',
      theme: ThemeData.dark(useMaterial3: true),
      home: const AppCheckHomePage(),
    );
  }
}

class AppCheckHomePage extends StatefulWidget {
  const AppCheckHomePage({super.key});

  @override
  State<AppCheckHomePage> createState() => _AppCheckHomePageState();
}

class _AppCheckHomePageState extends State<AppCheckHomePage> {
  final _appCheck = FirebaseAppCheck.instance;
  String _status = 'Ready.';
  String _token = '(none yet)';

  /// A token is ~700 chars of JWT; show enough to tell a real one from a stub.
  static String _describe(String? token) => token == null
      ? '(null)'
      : '${token.substring(0, token.length.clamp(0, 24))}… (${token.length} chars)';

  Future<void> _run(String label, Future<void> Function() action) async {
    try {
      await action();
      setState(() => _status = '✅ $label — ok.');
    } catch (e) {
      setState(() => _status = '❌ $label — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('firebase_app_check · tvOS')),
      body: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 16),
            Text('token = $_token', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                ElevatedButton(
                  autofocus: true,
                  onPressed: () => _run('activate (DeviceCheck)', () async {
                    // DeviceCheck + App Attest are the Apple providers available
                    // on tvOS 15+. Debug provider is handy for the simulator.
                    await _appCheck.activate(
                      providerApple: const AppleDeviceCheckProvider(),
                    );
                  }),
                  child: const Text('activate (DeviceCheck)'),
                ),
                ElevatedButton(
                  onPressed: () => _run('activate (Debug)', () async {
                    // The only provider that can mint a token on the simulator:
                    // App Attest and DeviceCheck both need real hardware.
                    await _appCheck.activate(
                      providerApple: const AppleDebugProvider(),
                    );
                  }),
                  child: const Text('activate (Debug)'),
                ),
                ElevatedButton(
                  onPressed: () => _run('getToken', () async {
                    final token = await _appCheck.getToken();
                    setState(() => _token = _describe(token));
                  }),
                  child: const Text('get App Check token'),
                ),
                ElevatedButton(
                  onPressed: () => _run('getLimitedUseToken', () async {
                    final token = await _appCheck.getLimitedUseToken();
                    setState(() => _token = _describe(token));
                  }),
                  child: const Text('get limited-use token'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
