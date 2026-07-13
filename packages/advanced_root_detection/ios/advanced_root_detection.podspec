Pod::Spec.new do |s|
  s.name             = 'advanced_root_detection'
  s.version          = '0.0.1'
  s.summary          = 'Flutter RASP plugin: root/jailbreak, hooking, debugger, emulator, and tamper detection.'
  s.description      = <<-DESC
    Comprehensive Runtime Application Self-Protection for Android and iOS.
    Detects rooted/jailbroken devices, hooking frameworks (Frida, Substrate),
    emulators/simulators, attached debuggers, and app integrity violations.
  DESC
  s.homepage         = 'https://pub.dev/packages/advanced_root_detection'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'advanced_root_detection' => 'dev@advanced_root_detection.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SWIFT_VERSION' => '5.0',
    'OTHER_SWIFT_FLAGS' => '-DRELEASE_BUILD'
  }
  s.swift_version = '5.0'
end
