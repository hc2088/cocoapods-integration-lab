import Foundation
import LegacyObjCPod
import MixedInteropPod

@objcMembers
final class AppSwiftBridge: NSObject, InteropHost {
    static func message() -> String {
        "App.Swift 已执行"
    }

    static func callAppObjC() -> String {
        AppObjCBridge.message()
    }

    static func callObjCPod() -> String {
        LegacyObjCBridge.message()
    }

    func hostMessage() -> String {
        "App.Swift 回调已执行"
    }
}
