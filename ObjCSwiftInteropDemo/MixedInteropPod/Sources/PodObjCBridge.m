#import "PodObjCBridge.h"
// 同一个 Pod target 内使用 DERIVED_SOURCES_DIR 下的 Swift 兼容头。
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
