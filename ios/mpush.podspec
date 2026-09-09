#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mpush.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mpush'
  s.version          = '1.1.8'
  s.summary          = 'MPush client for Flutter, you can use this plugin to interact with MPush.'
  s.description      = <<-DESC
MPush client for Flutter, you can use this plugin to interact with MPush.
                       DESC
  s.homepage         = 'https://github.com/Mumble-SRL/MPush-Flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mumble' => 'developer@mumble.it' }
  s.source           = { :path => '.' }
  s.source_files     = 'mpush/Sources/mpush/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'

  s.framework = 'UserNotifications'

  s.resource_bundles = {'mpush_privacy' => ['mpush/Sources/mpush/PrivacyInfo.xcprivacy']}
end
