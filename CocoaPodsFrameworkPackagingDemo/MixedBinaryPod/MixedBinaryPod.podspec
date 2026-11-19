Pod::Spec.new do |s|
  s.name = 'MixedBinaryPod'
  s.version = '1.0.0'
  s.summary = 'Local demo of three vendored binary formats in one source Pod.'
  s.homepage = 'https://example.com/MixedBinaryPod'
  s.license = { :type => 'MIT' }
  s.author = 'VendoredBinaryDemo'
  s.source = { :git => 'https://example.com/MixedBinaryPod.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'

  s.source_files = 'Sources/*.{h,m}', 'Vendor/ArchiveVendor.h'
  s.public_header_files = 'Sources/MixedBinaryPod.h'
  s.private_header_files = 'Vendor/ArchiveVendor.h'
  s.vendored_libraries = 'Vendor/libArchiveVendor.a'
  s.vendored_frameworks = 'Vendor/StaticVendor.framework',
                          'Vendor/DynamicVendor.framework'
  # A dynamic MixedBinaryPod resolves its own DynamicVendor references at link time.
  # CocoaPods already lists the vendored framework for the App's link and embed steps.
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-framework DynamicVendor' }
end
