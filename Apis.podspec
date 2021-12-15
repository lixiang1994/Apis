Pod::Spec.new do |s|

s.name         = "Apis"
s.version      = "1.0.0"
s.summary      = "基于URLNavigator抽象的URL路由组件 灵感来自Moya 配置化 插件化."

s.homepage     = "https://github.com/lixiang1994/Apis"

s.license      = { :type => "MIT", :file => "LICENSE" }

s.author       = { "LEE" => "18611401994@163.com" }

s.platform     = :ios, "9.0"

s.source       = { :git => "https://github.com/lixiang1994/Apis.git", :tag => s.version }

s.source_files  = "Sources/**/*.swift"

s.requires_arc = true

s.frameworks = "UIKit", "Foundation"

s.swift_version = "5.0"

end
