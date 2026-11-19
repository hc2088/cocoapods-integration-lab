#import "LegacyObjCImportExamples.h"
@import LegacyObjCPod;

NSString *CallLegacyObjCWithModuleImport(void) {
    return [LegacyObjCBridge message];
}
