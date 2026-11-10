import 'dart:io';

import 'package:aliplayer_widget/aliplayer_widget_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_medialoader.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_medialoader_v2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:simulator_smoke/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUpAll(() async {
    storage = await Directory.systemTemp.createTemp('aliplayer-mock-smoke-');
    AliPlayerWidgetGlobalSetting.setStoragePaths(
        cachePath: storage.path, filesPath: storage.path);
  });
  tearDownAll(() async {
    if (await storage.exists()) await storage.delete(recursive: true);
  });

  testWidgets('native getters keep types and player settings stay isolated',
      (tester) async {
    expect(await FlutterAliplayer.getSDKVersion(), contains('simulator-mock'));
    await FlutterAliplayer.setAudioSessionTypeForIOS(
        AliPlayerAudioSesstionType.none);
    final first = FlutterAliPlayerFactory.createAliPlayer(playerId: 'first');
    final second = FlutterAliPlayerFactory.createAliPlayer(playerId: 'second');
    addTearDown(first.release);
    addTearDown(second.release);
    expect(await first.getVolume(), isA<double>());
    expect(await first.getSpeed(), isA<double>());
    expect(await first.isLoop(), isFalse);
    expect(await first.getDuration(), 0);
    expect(await first.getCurrentDownloadSpeed(), 0);
    expect(await first.getPlayConfig(), isA<AVPConfig>());
    expect((await first.getMediaInfo())['tracks'], isEmpty);
    await first.setSpeed(1.5);
    await first.setLoop(true);
    await first.setMuted(true);
    await first.setScalingMode(ScaleMode.SCALE_ASPECT_FILL);
    expect(await first.getSpeed(), 1.5);
    expect(await second.getSpeed(), 1.0);
    expect(await first.isLoop(), isTrue);
    expect(await second.isLoop(), isFalse);
    expect(await first.isMuted(), isTrue);
    expect(await first.getScalingMode(), ScaleMode.SCALE_ASPECT_FILL);
    final playbackEvents = <String>[];
    first.setOnRenderingStart((_) => playbackEvents.add('first-frame'));
    first.setOnCompletion((_) => playbackEvents.add('completion'));
    first.setOnInfo(
        (code, value, message, id) => playbackEvents.add('progress'));
    await first.prepare();
    await first.play();
    await first.seekTo(900, 0);
    await first.pause();
    expect(await first.getCurrentPosition(), 0);
    expect(playbackEvents, isEmpty);
    await first.release();
    final recreated =
        FlutterAliPlayerFactory.createAliPlayer(playerId: 'first');
    expect(await recreated.getSpeed(), 1.0);
    expect(await recreated.isLoop(), isFalse);
    await recreated.release();
  });

  testWidgets('global setup, both preloaders and cache cleanup need no SDK',
      (tester) async {
    await AliPlayerWidgetGlobalSetting.setupConfig();
    final loader = FlutterAliPlayerMediaLoader();
    loader.setOnLoadStatusListener(
        (_) => fail('Mock must not finish downloads'), null, null, null);
    loader.load('https://example.invalid/mock.mp4', 3000);
    loader.cancel('https://example.invalid/mock.mp4');
    final loaderV2 = FlutterAliMediaLoaderV2();
    addTearDown(loaderV2.dispose);
    loaderV2.setPreloadConfig(PreloadConfig(duration: 3000));
    expect((await loaderV2.getPreloadConfig()).duration, 3000);
    final task = await loaderV2.addUrlTask(
        videoSource: 'https://example.invalid/mock.mp4');
    expect(task, isNotEmpty);
    loaderV2.cancelTask(task);
    loaderV2.resetPreloadConfig();
    expect((await loaderV2.getPreloadConfig()).duration, 1000);
    await AliPlayerWidgetGlobalSetting.clearCaches();
    await tester.pump();
    expect(tester.takeException(), isNull);
    loader.setOnLoadStatusListener(null, null, null, null);
  });

  testWidgets(
      'unmodified aliplayer_widget mounts its native view and exits repeatedly',
      (tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(SimulatorSmokeApp(key: ValueKey(i)));
      await tester.pumpAndSettle();
      expect(find.text('Mock ready'), findsOneWidget);
      expect(find.byType(UiKitView), findsOneWidget);
      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
