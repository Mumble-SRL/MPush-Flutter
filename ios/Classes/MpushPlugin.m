#import "MpushPlugin.h"
#if __has_include(<mpush/mpush-Swift.h>)
#import <mpush/mpush-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mpush-Swift.h"
#endif

@implementation MpushPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMpushPlugin registerWithRegistrar:registrar];
}
@end
