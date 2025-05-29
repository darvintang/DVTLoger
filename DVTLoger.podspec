Pod::Spec.new do |s|
  s.name             = 'DVTLoger'
  s.version          = '3.0.0'
  s.summary          = 'DVTLoger'

  s.description      = <<-DESC
  TODO:
    打印日志的框架，可以输出到控制台，导出日志文件
  DESC

  s.homepage         = 'https://github.com/darvintang/DVTLoger'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'darvin' => 'darvin@tcoding.cn' }
  s.source           = { :git => 'https://github.com/darvintang/DVTLoger.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13'
  
  s.source_files = 'Sources/*.swift'

  s.swift_version = '5'
  s.requires_arc  = true
  s.dependency 'Zip', '2.1.2'

end
