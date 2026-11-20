#import <Foundation/Foundation.h>
#import <MixedInteropPod/InteropHost.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwiftCaller : NSObject <InteropHost>
+ (NSString *)callSwift;
- (NSString *)hostMessage;
@end

NS_ASSUME_NONNULL_END
