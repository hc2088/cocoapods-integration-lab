Pod::Spec.new do |s|
  s.name = 'SwiftToObjCPod'
  s.version = '1.0.0'
  s.summary = 'Pure Swift Pod that calls a separate Objective-C Pod.'
  s.homepage = 'https://example.com/SwiftToObjCPod'
  s.license = { :type => 'MIT' }
  s.author = 'ObjCSwiftInteropDemo'
  s.source = { :git => 'https://example.com/SwiftToObjCPod.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5.0']
  s.source_files = 'Sources/*.swift'
  s.dependency 'LegacyObjCPod', '1.0.0'
end
