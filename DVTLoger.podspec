Pod::Spec.new do |s|
  s.name             = 'DVTLoger'
  s.version          = '1.0'
  s.summary          = 'DVTLoger'

  s.description      = <<-DESC
  TODO: 打印日志的组件
                       DESC

  s.homepage         = 'https://github.com/darvintang/DVTLoger'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xt-input' => 'input@tcoding.cn' }
  s.source           = { :git => 'https://github.com/darvintang/DVTLoger.git', :tag => s.version.to_s }

  s.watchos.deployment_target = '2.0'
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Sources/*.swift'

  s.swift_version = '5'
  s.requires_arc  = true
end
