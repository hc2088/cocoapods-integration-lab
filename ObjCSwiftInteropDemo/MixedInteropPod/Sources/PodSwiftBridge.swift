import Foundation
import LegacyObjCPod

@objcMembers
public final class PodSwiftBridge: NSObject {
    public static func message() -> String {
        "MixedInteropPod.Swift 已执行"
    }

    public static func callPodObjC() -> String {
        PodObjCBridge.message()
    }

    public static func callObjCDependency() -> String {
        LegacyObjCBridge.message()
    }

    public static func callHost(_ host: InteropHost) -> String {
        host.hostMessage()
    }
}
