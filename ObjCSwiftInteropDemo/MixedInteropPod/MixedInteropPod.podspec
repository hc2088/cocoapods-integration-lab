Pod::Spec.new do |s|
  s.name = 'MixedInteropPod'
  s.version = '1.0.0'
  s.summary = 'Mixed Objective-C and Swift Pod with a host callback.'
  s.homepage = 'https://example.com/MixedInteropPod'
  s.license = { :type => 'MIT' }
  s.author = 'ObjCSwiftInteropDemo'
  s.source = { :git => 'https://example.com/MixedInteropPod.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5.0']
  s.source_files = 'Sources/*.{h,m,swift}'
  s.public_header_files = 'Sources/*.h'
  s.dependency 'LegacyObjCPod', '1.0.0'
end
