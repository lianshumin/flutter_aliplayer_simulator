import 'dart:async';
import 'dart:io';

import 'package:aliplayer_widget/aliplayer_widget_lib.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage =
      await Directory.systemTemp.createTemp('aliplayer-mock-example-');
  AliPlayerWidgetGlobalSetting.setStoragePaths(
      cachePath: storage.path, filesPath: storage.path);
  runApp(const SimulatorSmokeApp());
}

class SimulatorSmokeApp extends StatefulWidget {
  const SimulatorSmokeApp({super.key});
  @override
  State<SimulatorSmokeApp> createState() => _SimulatorSmokeAppState();
}

class _SimulatorSmokeAppState extends State<SimulatorSmokeApp> {
  final AliPlayerWidgetController controller = AliPlayerWidgetController();
  String status = 'Configuring';
  @override
  void initState() {
    super.initState();
    unawaited(_configure());
  }

  Future<void> _configure() async {
    await AliPlayerWidgetGlobalSetting.setupConfig();
    await controller.configure(
      AliPlayerWidgetData(
        sceneType: SceneType.listPlayer,
        videoSource: VideoSourceFactory.createUrlSource(
            'https://example.invalid/mock.mp4'),
        autoPlay: false,
        allowedScreenSleep: true,
      ),
    );
    if (mounted) setState(() => status = 'Mock ready');
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('AliPlayer Simulator Mock')),
          body: Column(
            children: [
              Text(status),
              const Text('No video playback. Native platform view below.'),
              Expanded(
                child: AliPlayerWidget(
                  controller,
                  slotBuilders: {
                    for (final slot in SlotType.builtInSlots)
                      if (slot != SlotType.playerSurface) slot: null,
                  },
                ),
              ),
              Wrap(
                children: [
                  TextButton(
                      onPressed: controller.play, child: const Text('Play')),
                  TextButton(
                      onPressed: controller.pause, child: const Text('Pause')),
                ],
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    controller.destroy();
    super.dispose();
  }
}
