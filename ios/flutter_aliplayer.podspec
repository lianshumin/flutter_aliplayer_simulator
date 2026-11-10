Pod::Spec.new do |s|
  s.name = 'flutter_aliplayer'
  s.version = '7.18.0'
  s.summary = 'Simulator-only mock of flutter_aliplayer 7.18.0.'
  s.description = 'Keeps the original Dart API while replacing the iOS SDK with a no-op implementation for UI debugging.'
  s.homepage = 'https://github.com/lianshumin/flutter_aliplayer_simulator'
  s.license = { :file => '../LICENSE' }
  s.author = { 'Alibaba Inc.' => 'https://www.aliyun.com/product/vod' }
  s.source = { :path => '.' }
  s.source_files = 'MockClasses/**/*.{h,m}'
  s.public_header_files = 'MockClasses/FlutterAliplayerPlugin.h'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
