Pod::Spec.new do |s|
  s.name = 'LegacyObjCPod'
  s.version = '1.0.0'
  s.summary = 'Local Objective-C dependency for the Swift interop demo.'
  s.homepage = 'https://example.com/LegacyObjCPod'
  s.license = { :type => 'MIT' }
  s.author = 'ObjCSwiftInteropDemo'
  s.source = { :git => 'https://example.com/LegacyObjCPod.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.source_files = 'Sources/*.{h,m}'
  s.public_header_files = 'Sources/*.h'
end
