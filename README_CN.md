# Apis

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)

基于[URLNavigator](https://github.com/devxoul/URLNavigator) 抽象的路由组件, 灵感来自 [Moya](https://github.com/Moya/Moya).

## Features

- [x] 支持基于插件机制的不同处理 如登录拦截等.
- [x] 配置独立且易于管理.
- [x] 良好的业务可扩展性.
- [x] 安全的页面管理.
- [x] 支持异步完成结果回调.


## 安装

Apis 仅支持CocoaPods.

**CocoaPods - Podfile**

```ruby
pod 'Apis'
```

## 使用

首先导入framework:

```swift
import Apis
```

下面是一些简单示例. 支持所有设备和模拟器:

### 创建 Apis

```swift
let router = Apis.Provider<RouterTarget>(
    [RouterXXXXXXPlugin(),
     RouterXXXXXXPlugin(),
     RouterXXXXXXPlugin()]
)
```

### TargetType

```swift
// 可以通过枚举声明所有类型 
enum RouterTarget {
    case open_http(url: URL)
    case open_https(url: URL)
    case open_none
    case open_live(id: String)
    case open_some
}

extension RouterTarget: Apis.TargetType {
    
    var task: Task {
        switch(self) {
        case let .open_http(url):
            return .controller(SFSafariViewController(url: url))
            
        case let .open_https(url):
            return .controller(SFSafariViewController(url: url))
            
        case .open_none:
            return .controller(NoneViewController())
            
        case let .open_live(id):
            let controller = LiveViewController()
            controller.id = id
            return .controller(controller)
            
        case .open_some:
            return .handle { completion in
                // 处理一些其他事情, 结束后务必调用completion回调
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // 巴拉巴拉..
                    completion(true)
                }
            }
        }
    }
}

// 每个支持路由的视图控制器需要实现 Routerable 协议
extension XXXXViewController: Routerable { }
extension SFSafariViewController: Routerable { }
```

### URLTargetType

```
private let schemes = "router"

extension RouterTarget: URLTargetType {
    
    // 激活的URL模板集合
    static var activated: [URLPattern] {
        return [
            "http://<path:_>",
            "https://<path:_>",
            schemes + "://open/none",
            schemes + "://open/fast",
            schemes + "://open/live",
            schemes + "://open/needlogin"
        ]
    }
    
    // URL模板
    var pattern: String {
        switch self {
        case .open_http:        return "http://<path:_>"
        case .open_https:       return "https://<path:_>"
        case .open_none:        return schemes + "://open/none"
        case .open_live:        return schemes + "://open/live"
        case .open_some:        return schemes + "://open/some"
        }
    }
    
    init?(pattern: URLPattern, url: URLConvertible, values: [String : Any]) {
        switch pattern {
        case "http://<path:_>":
            guard let url = url.value else { return nil }
            self = .open_http(url: url)
            
        case "https://<path:_>":
            guard let url = url.value else { return nil }
            self = .open_https(url: url)
            
        case schemes + "://open/none":
            self = .open_none
            
        case schemes + "://open/live":
            guard let id = url.queryParameters["id"] else { return nil }
            self = .open_live(id: id)
            
        case schemes + "://open/some":
            self = .open_some
            
        default:
            return nil
        }
    }
}
```

### 自定义插件

```swift 
// 实现需要的方法 你可以在整个打开过程中做一切你想做的事情
class RouterXXXXPlugin: Apis.PluginType {
    
    // 能否打开
    func should(open target: TargetType) -> Bool {
        /* ... */
        return true
    }
    
    // 准备打开时
    func prepare(open target: TargetType, completion: @escaping (Bool) -> Void) {
        /* ... */
        completion(true)
    }
    
    // 即将打开
    func will(open target: TargetType, controller: Routerable) {
        /* ... */
    }
    
    // 已经打开
    func did(open target: TargetType, controller: Routerable) {
        /* ... */
    }
}
```

### 打开

```swift
// 根据目标类型打开页面
router.open(.open_xxxx)

// 根据URL打开页面
router.open("http://xxxxxxxx")

// 打开结果回调  打开过程中可能由于各种原因导致打开失败 例如: 这个页面需要登录 但是当前没有登录之类的
router.open("http://xxxxxxxx") { (result) in
    // 成功或失败
}
```

## 贡献

如果你需要实现特定功能或遇到错误，请打开issue。 如果你自己扩展了Apis的功能并希望其他人也使用它，请提交拉取请求。


## 协议

Apis 使用 MIT 协议. 有关更多信息，请参阅 [LICENSE](LICENSE) 文件.
