#import <UIKit/UIKit.h>
#import "LegacyObjCImportExamples.h"
@import MixedInteropPod;
@import MixedInteropPod.Swift;
#import "ObjCSwiftInteropDemo-Swift.h"

@interface AppObjCHost : NSObject <InteropHost>
@end

@implementation AppObjCHost

- (NSString *)hostMessage {
    return @"App.ObjC 回调已执行";
}

@end

static NSString *CaseResult(NSString *route, NSString *result) {
    return [NSString stringWithFormat:@"%@\n%@", route, result];
}

static UILabel *MakeLabel(NSString *text, UIFontTextStyle style) {
    UILabel *label = [UILabel new];
    label.font = [UIFont preferredFontForTextStyle:style];
    label.adjustsFontForContentSizeCategory = YES;
    label.numberOfLines = 0;
    label.textColor = UIColor.labelColor;
    label.text = text;
    return label;
}

static void AddSection(UIStackView *screen, NSString *title, NSArray<NSString *> *results) {
    UIStackView *section = [UIStackView new];
    section.axis = UILayoutConstraintAxisVertical;
    section.spacing = 10;
    [section addArrangedSubview:MakeLabel(title, UIFontTextStyleTitle2)];
    for (NSString *result in results) {
        [section addArrangedSubview:MakeLabel(result, UIFontTextStyleSubheadline)];
    }
    [screen addArrangedSubview:section];
    NSLog(@"%@\n%@", title, [results componentsJoinedByString:@"\n"]);
}

@interface InteropSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation InteropSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    UIViewController *controller = [UIViewController new];
    controller.view.backgroundColor = UIColor.systemBackgroundColor;

    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [controller.view addSubview:scrollView];

    UIStackView *screen = [UIStackView new];
    screen.axis = UILayoutConstraintAxisVertical;
    screen.spacing = 22;
    screen.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:screen];

    UILayoutGuide *safeArea = controller.view.safeAreaLayoutGuide;
    UILayoutGuide *content = scrollView.contentLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
        [screen.topAnchor constraintEqualToAnchor:content.topAnchor constant:20],
        [screen.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [screen.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24],
        [screen.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-24],
        [screen.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-48]
    ]];

    AddSection(screen, @"主工程内", @[
        CaseResult(@"Swift → Objective-C", [AppSwiftBridge callAppObjC]),
        CaseResult(@"Objective-C → Swift", [AppSwiftBridge message])
    ]);
    AddSection(screen, @"Pod 内与 Pod 之间", @[
        CaseResult(@"Swift → 同 Pod 的 Objective-C", [PodSwiftBridge callPodObjC]),
        CaseResult(@"Objective-C → 同 Pod 的 Swift", [PodObjCBridge callSwift]),
        CaseResult(@"Swift → 另一个 Objective-C Pod", [PodSwiftBridge callObjCDependency])
    ]);
    AddSection(screen, @"主工程与 Pod 之间", @[
        CaseResult(@"App Swift → Pod Objective-C", [AppSwiftBridge callObjCPod]),
        CaseResult(@"App ObjC → Pod ObjC · #import", CallLegacyObjCWithHeaderImport()),
        CaseResult(@"App ObjC → Pod ObjC · @import", CallLegacyObjCWithModuleImport()),
        CaseResult(@"App Objective-C → Pod Swift", [PodSwiftBridge message]),
        CaseResult(@"Pod Swift → App Objective-C", [PodSwiftBridge callHost:[AppObjCHost new]]),
        CaseResult(@"Pod Objective-C → App Swift", [PodObjCBridge callHost:[AppSwiftBridge new]])
    ]);

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
}

@end

@interface InteropAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation InteropAppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(InteropAppDelegate.class));
    }
}
