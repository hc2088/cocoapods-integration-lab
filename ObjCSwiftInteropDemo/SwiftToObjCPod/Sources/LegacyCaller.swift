import LegacyObjCPod

public enum LegacyCaller {
    public static func callObjectiveC() -> String {
        LegacyObjCBridge.message()
    }
}
