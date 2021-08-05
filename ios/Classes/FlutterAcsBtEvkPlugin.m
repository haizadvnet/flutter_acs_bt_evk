#import "FlutterAcsBtEvkPlugin.h"

#import "FlutterAcsBtEvkFactory.h"

@interface FlutterAcsBtEvkPlugin ()

@end

@implementation FlutterAcsBtEvkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [registrar registerViewFactory:[[FlutterAcsBtEvkFactory alloc] initWithMessenger:registrar.messenger] withId:@"plugin:acs_bt_evk"];
}

@end
