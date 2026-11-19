#import "LegacyObjCImportExamples.h"
#import <LegacyObjCPod/LegacyObjCBridge.h>

NSString *CallLegacyObjCWithHeaderImport(void) {
    return [LegacyObjCBridge message];
}
