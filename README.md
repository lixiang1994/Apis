# Apis

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)

[URLNavigator](https://github.com/devxoul/URLNavigator) abstract routing component written in Swift, Inspired by [Moya](https://github.com/Moya/Moya).

## [天朝子民](README_CN.md)

## Features

- [x] Support for different processing based on plugin mechanism.
- [x] Configuration is independent and easy to manage.
- [x] Good business scalability.
- [x] Safer page management.
- [x] Support for asynchronous completion of callbacks.


## Installation

Apis officially supports CocoaPods only.

**CocoaPods - Podfile**

```ruby
pod 'Apis'
```

## Usage

First make sure to import the framework:

```swift
import Apis
```

Here are some usage examples. All devices are also available as simulators:

### Create Apis

```swift
let router = Apis.Provider<RouterTarget>(
    [RouterXXXXXXPlugin(),
     RouterXXXXXXPlugin(),
     RouterXXXXXXPlugin()]
)
```

### TargetType

```swift
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    completion(true)
                }
            }
        }
    }
}

extension XXXXViewController: Routerable { }
extension SFSafariViewController: Routerable { }
```
### URLTargetType

```
private let schemes = "router"

extension RouterTarget: URLTargetType {
    
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

### Custom plugins

```swift 
class RouterXXXXPlugin: Apis.PluginType {
    
    func should(open target: TargetType) -> Bool {
        /* ... */
        return true
    }
    
    func prepare(open target: TargetType, completion: @escaping (Bool) -> Void) {
        /* ... */
        completion(true)
    }
    
    func will(open target: TargetType, controller: Routerable) {
        /* ... */
    }
    
    func did(open target: TargetType, controller: Routerable) {
        /* ... */
    }
}
```

### Open

```swift
// Open page based on type
router.open(.open_xxxx)

// Open page based on url
router.open("http://xxxxxxxx")

// Result callback
router.open("http://xxxxxxxx") { (result) in
    // Success or failure
}

```

## Contributing

If you have the need for a specific feature that you want implemented or if you experienced a bug, please open an issue.
If you extended the functionality of Apis yourself and want others to use it too, please submit a pull request.


## License

Apis is under MIT license. See the [LICENSE](LICENSE) file for more info.
