//
//  RouterTarget.swift
//  Demo
//
//  Created by 李响 on 2021/12/10.
//  Copyright © 2021 swift. All rights reserved.
//

import Apis
import SafariServices

enum RouterTarget {
    case open_http(url: URL)
    case open_https(url: URL)
    case open_none
    case open_live(id: String)
    case open_fast
    case open_needlogin
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
            
        case .open_fast:
            return .controller(FastViewController())
            
        case .open_needlogin:
            return .controller(NeedLoginViewController())
            
        case .open_some:
            return .handle { completion in
                // 处理一些其他事情, 结束后务必调用completion回调
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // 巴拉巴拉..
                    print("do something")
                    completion(true)
                }
            }
        }
    }
}

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
            .init(schemes + "://open/fast") {
                return .open_fast
            },
            .init(schemes + "://open/live") { source in
                guard let id = source.url.queryParameters["id"] else { return nil }
                return .open_live(id: id)
            },
            .init(schemes + "://open/needlogin") {
                return .open_needlogin
            },
            .init(schemes + "://open/some") {
                return .open_some
            }
        ]
    }
}

// 所有需要支持 Router 的视图控制器都需要实现 Routerable 协议
// Routerable 协议默认实现了通用的打开关闭处理逻辑 如无法满足 可重写

extension NoneViewController: Routerable { }
extension NeedLoginViewController: Routerable { }

extension SFSafariViewController: Routerable {
    
    public func open(with completion: @escaping () -> Void = {}) {
        guard let controller = UIViewController.top() else {
            return
        }
        
        controller.present(self, animated: true, completion: completion)
    }
}
