#import <UIKit/UIKit.h>
#include <stdio.h>

#if defined(MIXED_BINARY_POD_USE_TEXTUAL_HEADER)
#import <MixedBinaryPod/MixedBinaryPod.h>
#else
@import MixedBinaryPod;
#endif

@interface DemoSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation DemoSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    NSString *report = MixedBinaryPodReport();
    printf("%s\n", report.UTF8String);
    fflush(stdout);

    UIViewController *controller = [UIViewController new];
    controller.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *label = [UILabel new];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.adjustsFontForContentSizeCategory = YES;
    label.numberOfLines = 0;
    label.text = report;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [controller.view addSubview:label];

    UILayoutGuide *safeArea = controller.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:32],
        [label.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:24],
        [label.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-24]
    ]];

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
}

@end

@interface DemoAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation DemoAppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(DemoAppDelegate.class));
    }
}
