import Foundation
import LegacyObjCPod
import MixedInteropPod
import SwiftToObjCPod

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

    static func callFromSwiftPod() -> String {
        LegacyCaller.callObjectiveC()
    }

    func hostMessage() -> String {
        "App.Swift 回调已执行"
    }
}
