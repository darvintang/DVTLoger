Pod::Spec.new do |s|
  s.name             = 'DVTLoger'
  s.version          = '1.2.1'
  s.summary          = 'DVTLoger'

  s.description      = <<-DESC
  TODO: 打印日志的框架
                       DESC

  s.homepage         = 'https://github.com/darvintang/DVTLoger'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xt-input' => 'input@tcoding.cn' }
  s.source           = { :git => 'https://github.com/darvintang/DVTLoger.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'

  s.source_files = 'Sources/*.swift'

  s.swift_version = '5'
  s.requires_arc  = true
  s.dependency 'Zip', '>= 2.1.1'

end
