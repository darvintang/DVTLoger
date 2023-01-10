Pod::Spec.new do |s|
  s.name             = 'DVTLoger'
  s.version          = '2.0.2'
  s.summary          = 'DVTLoger'

  s.description      = <<-DESC
  TODO:
    打印日志的框架，可以输出到控制台，导出日志文件
  DESC

  s.homepage         = 'https://github.com/darvintang/DVTLoger'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'darvin' => 'darvin@tcoding.cn' }
  s.source           = { :git => 'https://github.com/darvintang/DVTLoger.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'

  s.source_files = 'Sources/*.swift'

  s.swift_version = '5'
  s.requires_arc  = true
  s.dependency 'Zip', '~> 2.1.2'

end
