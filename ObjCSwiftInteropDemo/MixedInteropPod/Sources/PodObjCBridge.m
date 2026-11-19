#import "PodObjCBridge.h"
#import "MixedInteropPod-Swift.h"

@implementation PodObjCBridge

+ (NSString *)message {
    return @"MixedInteropPod.ObjC 已执行";
}

+ (NSString *)callSwift {
    return [PodSwiftBridge message];
}

+ (NSString *)callHost:(id<InteropHost>)host {
    return [host hostMessage];
}

@end
