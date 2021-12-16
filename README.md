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
    
    static var bindings: [URLPatternBinding<RouterTarget>] {
        return [
            .init("http://<path:_>") { source in
                guard let url = source.url.value else { return .none }
                return .open_http(url: url)
            },
            .init("https://<path:_>") { source in
                guard let url = source.url.value else { return .none }
                return .open_https(url: url)
            },
            .init(schemes + "://open/none") {
                return .open_none
            },
            .init(schemes + "://open/live") { source in
                guard let id = source.url.queryParameters["id"] else { return nil }
                return .open_live(id: id)
            },
            .init(schemes + "://open/some") {
                return .open_some
            }
        ]
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
