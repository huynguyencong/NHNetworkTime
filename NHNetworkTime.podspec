Pod::Spec.new do |s|
  s.name         = 'NHNetworkTime'
  s.version      = '1.7.1'
  s.summary      = 'Simple Network Time Protocol SNTP for iOS.'
  s.homepage     = 'https://github.com/huynguyencong/NHNetworkTime'
  s.license      = { :type => 'Apache', :file => 'LICENSE' }
  s.source       = { :git => 'https://github.com/huynguyencong/NHNetworkTime.git', :tag => "#{s.version}" }
  s.author       = { 'Huy Nguyen Cong' => 'https://github.com/huynguyencong' }
  s.ios.deployment_target = '7.0'
  s.source_files = 'NHNetworkTime/*.{h,m}'
  s.framework = 'CFNetwork'
  s.dependency 'CocoaAsyncSocket', '~>7.5.0'
  s.requires_arc = true
end
