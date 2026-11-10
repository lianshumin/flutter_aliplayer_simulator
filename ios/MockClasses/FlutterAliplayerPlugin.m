#import "FlutterAliplayerPlugin.h"
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>

#if !TARGET_OS_SIMULATOR
#error "Simulator Mock selected. Remove the flutter_aliplayer dependency override before building for an iOS device."
#endif

@interface SimulatorPlayerView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView *placeholder;
@end

@implementation SimulatorPlayerView
- (UIView *)view { return self.placeholder; }
@end

@interface SimulatorEventStream : NSObject <FlutterStreamHandler>
@property(nonatomic, copy) FlutterEventSink sink;
@end

@implementation SimulatorEventStream
- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.sink = events;
    return nil;
}
- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.sink = nil;
    return nil;
}
@end

@interface FlutterAliplayerPlugin () <FlutterPlatformViewFactory, FlutterStreamHandler>
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *players;
@property(nonatomic, strong) NSArray<FlutterMethodChannel *> *methodChannels;
@property(nonatomic, strong) NSArray<FlutterEventChannel *> *eventChannels;
@property(nonatomic, copy) NSDictionary *preloadConfig;
@property(nonatomic, strong) NSNumber *brightness;
@property(nonatomic, strong) NSNumber *logLevel;
@property(nonatomic, strong) SimulatorEventStream *playerEvents;
@end

@implementation FlutterAliplayerPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterAliplayerPlugin *plugin = [FlutterAliplayerPlugin new];
    plugin.players = [NSMutableDictionary dictionary];
    plugin.preloadConfig = @{@"duration": @1000};
    plugin.brightness = @0.5;
    plugin.logLevel = @0;
    NSMutableArray *methods = [NSMutableArray array];
    for (NSString *name in @[@"plugins.flutter_aliplayer_factory", @"plugins.flutter_global_setting",
                            @"plugins.flutter_aliplayer_media_loader", @"plugins.flutter_aliplayer_loader_v2",
                            @"plugins.flutter_alidownload"]) {
        FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:name
                                                                  binaryMessenger:registrar.messenger];
        [registrar addMethodCallDelegate:plugin channel:channel];
        [methods addObject:channel];
    }
    plugin.methodChannels = methods;
    NSMutableArray *events = [NSMutableArray array];
    for (NSString *name in @[@"flutter_aliplayer_event", @"plugins.flutter_global_setting_event",
                            @"flutter_aliplayer_media_loader_event", @"flutter_aliplayer_loader_v2_event",
                            @"plugins.flutter_alidownload_event"]) {
        FlutterEventChannel *channel = [FlutterEventChannel eventChannelWithName:name
                                                                binaryMessenger:registrar.messenger];
        SimulatorEventStream *stream = [SimulatorEventStream new];
        [channel setStreamHandler:stream];
        if ([name isEqualToString:@"flutter_aliplayer_event"]) plugin.playerEvents = stream;
        [events addObject:channel];
    }
    plugin.eventChannels = events;
    [registrar registerViewFactory:plugin withId:@"plugins.flutter_aliplayer"];
    [registrar publish:plugin];
    NSLog(@"[flutter_aliplayer] SIMULATOR MOCK 7.18.0: video playback is disabled.");
}

- (NSMutableDictionary *)defaultPlayer {
    return [@{@"getVolume": @1.0, @"getSpeed": @1.0,
              @"isLoop": @NO, @"isMuted": @NO, @"isAutoPlay": @NO,
              @"enableHardwareDecoder": @NO,
              @"getMirrorMode": @0, @"getRotateMode": @0,
              @"getScalingMode": @0, @"getAlPhaRenderMode": @0,
              @"getVideoWidth": @1080, @"getVideoHeight": @1920,
              @"getUserData": @"", @"getPlayerName": @"simulator-mock",
              @"getPlayConfig": @{}, @"getConfig": @{}, @"getOption": @""} mutableCopy];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *method = call.method;
    NSDictionary *arguments = [call.arguments isKindOfClass:NSDictionary.class] ? call.arguments : @{};
    NSString *playerID = [arguments[@"playerId"] isKindOfClass:NSString.class] ? arguments[@"playerId"] : @"";
    id arg = arguments[@"arg"];
    if (arg == NSNull.null) arg = nil;
    if ([method isEqualToString:@"createAliPlayer"]) {
        self.players[playerID] = [self defaultPlayer];
        result(nil);
        return;
    }
    if ([method isEqualToString:@"destroy"] || [method isEqualToString:@"releaseAsync"]) {
        [self.players removeObjectForKey:playerID];
        result(nil);
        return;
    }
    NSMutableDictionary *state = self.players[playerID];
    if ([method isEqualToString:@"prepare"] && state) {
        // The upper widget requires a nonzero size to create any slots. This is
        // layout metadata only: do not report prepared, rendered or playing.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.players[playerID] == state && self.playerEvents.sink) {
                self.playerEvents.sink(@{@"method": @"onVideoSizeChanged", @"playerId": playerID,
                                         @"width": @1080, @"height": @1920, @"rotation": @0});
            }
        });
        result(nil);
        return;
    }
    NSDictionary *setterKeys = @{
        @"setVolume": @"getVolume", @"setSpeed": @"getSpeed",
        @"setLoop": @"isLoop", @"setMuted": @"isMuted", @"setAutoPlay": @"isAutoPlay",
        @"setEnableHardwareDecoder": @"enableHardwareDecoder",
        @"setMirrorMode": @"getMirrorMode", @"setRotateMode": @"getRotateMode",
        @"setScalingMode": @"getScalingMode", @"setAlphaRenderMode": @"getAlPhaRenderMode",
        @"setUserData": @"getUserData", @"setPreferPlayerName": @"getPlayerName"
    };
    NSString *key = setterKeys[method];
    if (key) {
        if (arg) state[key] = arg;
        result(nil);
        return;
    }
    if ([method isEqualToString:@"setConfig"] || [method isEqualToString:@"setPlayConfig"]) {
        if ([arg isKindOfClass:NSDictionary.class]) {
            state[@"getConfig"] = arg;
            state[@"getPlayConfig"] = arg;
        }
        result(nil);
        return;
    }
    if ([method isEqualToString:@"setOption"]) {
        // Global and per-player options are accepted without modifying the system.
        result(nil);
        return;
    }
    if ([method isEqualToString:@"setSystemBrightness"]) {
        self.brightness = arguments[@"brightness"] ?: self.brightness;
        result(nil);
        return;
    }
    if ([method isEqualToString:@"getSystemBrightness"]) { result(self.brightness); return; }
    if ([method isEqualToString:@"setLogLevel"]) {
        if ([call.arguments isKindOfClass:NSNumber.class]) self.logLevel = call.arguments;
        result(nil);
        return;
    }
    if ([method isEqualToString:@"getLogLevel"]) { result(self.logLevel); return; }
    if ([method isEqualToString:@"getSDKVersion"]) { result(@"7.18.0-simulator-mock"); return; }
    if ([method isEqualToString:@"getDeviceUUID"]) { result(@"simulator-mock"); return; }
    if ([method isEqualToString:@"isFeatureSupport"]) { result(@NO); return; }
    id value = state[method] ?: [self defaultPlayer][method];
    if (value) {
        if ([method isEqualToString:@"getVolume"] || [method isEqualToString:@"getSpeed"]) {
            result(@([value doubleValue]));
        } else {
            result(value);
        }
        return;
    }
    if ([method isEqualToString:@"getMediaInfo"] || [method isEqualToString:@"getSubMediaInfo"]) {
        result(@{@"tracks": @[], @"title": @"", @"coverURL": @"", @"duration": @0});
        return;
    }
    if ([method isEqualToString:@"getCurrentTrack"]) { result(@{}); return; }
    if ([@[@"getDuration", @"getCurrentPosition", @"getBufferedPosition", @"getPlayedDuration",
           @"getVideoWidth", @"getVideoHeight", @"getVideoRotation", @"getCurrentUtcTime",
           @"getLocalCacheLoadedSize", @"getCurrentDownloadSpeed", @"getCurrentLiveTime",
           @"getCurrentTime"] containsObject:method]) {
        result(@0);
        return;
    }
    if ([@[@"getCacheFilePath", @"getCacheFilePathWithVid", @"getCacheFilePathWithVidAtPreviewTime",
           @"getCurrentUid", @"getCurrentVps", @"getPropertyString", @"getFilePath",
           @"getFullSaveDir", @"generatePlayerConfig"] containsObject:method]) {
        result(@"");
        return;
    }
    if ([method isEqualToString:@"setPreloadConfig"]) {
        self.preloadConfig = arguments;
        result(nil);
        return;
    }
    if ([method isEqualToString:@"resetPreloadConfig"]) {
        self.preloadConfig = @{@"duration": @1000};
        result(nil);
        return;
    }
    if ([method isEqualToString:@"getPreloadConfig"]) { result(self.preloadConfig); return; }
    if ([method isEqualToString:@"addTask"]) { result(NSUUID.UUID.UUIDString); return; }
    // New queries require an explicit typed result instead of a mistyped null.
    if ([method hasPrefix:@"get"] || [method hasPrefix:@"is"]) {
        result([FlutterError errorWithCode:@"SIMULATOR_MOCK_UNSUPPORTED_QUERY"
                                  message:method details:nil]);
        return;
    }
    // Playback, loading, downloads and other commands are intentional no-ops.
    // Never emit first-frame, progress, completion or download-success events.
    result(nil);
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec { return FlutterStandardMessageCodec.sharedInstance; }
- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                  viewIdentifier:(int64_t)viewId arguments:(id)args {
    SimulatorPlayerView *view = [SimulatorPlayerView new];
    view.placeholder = [[UIView alloc] initWithFrame:frame];
    view.placeholder.backgroundColor = UIColor.clearColor;
    view.placeholder.userInteractionEnabled = NO;
    return view;
}
- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events { return nil; }
- (FlutterError *)onCancelWithArguments:(id)arguments { return nil; }
- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    for (FlutterMethodChannel *channel in self.methodChannels) [channel setMethodCallHandler:nil];
    for (FlutterEventChannel *channel in self.eventChannels) [channel setStreamHandler:nil];
    [self.players removeAllObjects];
    self.playerEvents.sink = nil;
    self.playerEvents = nil;
    self.methodChannels = @[];
    self.eventChannels = @[];
}
@end
