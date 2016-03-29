Pod::Spec.new do |s|
  s.name         = 'NHNetworkTime'
  s.version      = '1.5'
  s.summary      = 'Network time protocol NTP for iOS.'
  s.homepage     = 'https://github.com/huynguyencong/NHNetworkTime'
  s.license      = { :type => 'Apache', :file => 'LICENSE' }
  s.source       = { :git => 'https://github.com/huynguyencong/NHNetworkTime.git', :tag => "#{s.version}" }
  s.author       = { 'Huy Nguyen Cong' => 'https://github.com/huynguyencong' }
  s.ios.deployment_target = '7.0'
  s.source_files = 'NHNetworkTime/*.{h,m}'
  s.framework = 'CFNetwork'
  s.dependency 'CocoaAsyncSocket', '<=7.4.1'
  s.requires_arc = true
end
