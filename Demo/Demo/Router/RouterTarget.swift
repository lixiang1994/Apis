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
            
        case schemes + "://open/fast":
            self = .open_fast
            
        case schemes + "://open/live":
            guard let id = url.queryParameters["id"] else { return nil }
            self = .open_live(id: id)
            
        case schemes + "://open/needlogin":
            self = .open_needlogin
            
        case schemes + "://open/some":
            self = .open_some
            
        default:
            return nil
        }
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
