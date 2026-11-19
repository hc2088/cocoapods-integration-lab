#import <Foundation/Foundation.h>
#import <MixedInteropPod/InteropHost.h>

NS_ASSUME_NONNULL_BEGIN

@interface PodObjCBridge : NSObject
+ (NSString *)message;
+ (NSString *)callSwift;
+ (NSString *)callHost:(id<InteropHost>)host;
@end

NS_ASSUME_NONNULL_END
