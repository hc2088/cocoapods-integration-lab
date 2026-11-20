Pod::Spec.new do |s|
  s.name = 'SwiftCallerPod'
  s.version = '1.0.0'
  s.summary = 'Objective-C caller of a separate Swift-containing Pod.'
  s.homepage = 'https://example.com/SwiftCallerPod'
  s.license = { :type => 'MIT' }
  s.author = 'ObjCSwiftInteropDemo'
  s.source = { :git => 'https://example.com/SwiftCallerPod.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.source_files = 'Sources/*.{h,m}'
  s.public_header_files = 'Sources/*.h'
  s.dependency 'MixedInteropPod', '1.0.0'
end
