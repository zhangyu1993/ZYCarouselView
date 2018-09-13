Pod::Spec.new do |s|
  s.name = 'ZYCarouselView'
  s.version = '0.1.0'
  s.license = 'MIT'
  s.summary = 'CarouselView in Swift'
  s.homepage = 'https://github.com/zhangyu1993/ZYCarouselView'
  s.authors = { 'MrYu' => 'zhangyu_mp@icloud.com' }
  s.source = { :git => 'https://github.com/zhangyu1993/ZYCarouselView.git', :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Source/*.swift'
end