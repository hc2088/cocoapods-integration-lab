#import "MixedBinaryPod.h"
#import "ArchiveVendor.h"
#import <StaticVendor/StaticVendor.h>
#import <DynamicVendor/DynamicVendor.h>
#include <dlfcn.h>

static NSString *ImageName(const void *address) {
    Dl_info info;
    if (dladdr(address, &info) == 0 || info.dli_fname == NULL) {
        return @"Unknown image";
    }
    return [@(info.dli_fname) lastPathComponent];
}

NSString *MixedBinaryPodReport(void) {
    return [NSString stringWithFormat:
            @"libArchiveVendor.a\n%d  →  %@\n\n"
             "StaticVendor.framework\n%d  →  %@\n\n"
             "DynamicVendor.framework\n%d  →  %@",
            BinaryDemoArchiveValue(), ImageName((const void *)BinaryDemoArchiveValue),
            BinaryDemoStaticFrameworkValue(), ImageName((const void *)BinaryDemoStaticFrameworkValue),
            BinaryDemoDynamicFrameworkValue(), ImageName((const void *)BinaryDemoDynamicFrameworkValue)];
}
