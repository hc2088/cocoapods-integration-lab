#import "SwiftCaller.h"
// 跨 Pod 调用 Swift，导入 CocoaPods 为静态库生成的 Swift 子模块。
@import MixedInteropPod.Swift;

@implementation SwiftCaller

+ (NSString *)callSwift {
    return [PodSwiftBridge message];
}

- (NSString *)hostMessage {
    return @"SwiftCallerPod.ObjC 回调已执行";
}

@end
