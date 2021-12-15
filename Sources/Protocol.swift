//
//  Protocol.swift
//  ┌─┐      ┌───────┐ ┌───────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ │      │ └─────┐ │ └─────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ └─────┐│ └─────┐ │ └─────┐
//  └───────┘└───────┘ └───────┘
//
//  Created by lee on 2019/4/1.
//  Copyright © 2019年 lee. All rights reserved.
//

import UIKit

public protocol PluginType {
    
    /// 是否可以打开
    ///
    /// - Parameter target: 类型
    /// - Returns: true or false
    func should(open target: TargetType) -> Bool
    
    /// 准备打开
    ///
    /// - Parameters:
    ///   - target: 类型
    ///   - completion: 准备完成回调 (无论结果如何必须回调)
    func prepare(open target: TargetType, completion: @escaping (Bool) -> Void)
    
    /// 即将打开
    ///
    /// - Parameters:
    ///   - target: 类型
    ///   - controller: 视图控制器
    func will(open target: TargetType, controller: Routerable)
    
    /// 已经打开
    ///
    /// - Parameters:
    ///   - target: 类型
    ///   - controller: 视图控制器
    func did(open target: TargetType, controller: Routerable)
}

public typealias URLPattern = String

public enum Task {
    
    case controller(Routerable)
    
    case handle(working: (_ completion: (@escaping (Bool) -> Void)) -> Void)
}

public protocol TargetType {
    
    var task: Task { get }
}

public protocol URLTargetType: TargetType {
    
    static var activated: [URLPattern] { get }
    
    init?(pattern: URLPattern, url: URLConvertible, values: [String: Any])
}

public protocol Routerable: UIViewController {
    
    /// 打开
    ///
    /// - Parameter completion: 打开完成回调
    func open(with completion: @escaping () -> Void)
    
    /// 关闭
    ///
    /// - Parameters:
    ///   - completion: 关闭完成回调
    func close(with completion: @escaping () -> Void)
}

public extension URL {
    
    func appending(_ params: [String: String]) -> String {
        return absoluteString.appending(params)
    }
}

public extension String {
    
    func appending(_ params: [String: String]) -> String {
        return appending(self, params)
    }
    
    func appending(_ url: String, _ params: [String: String]) -> String {
        guard var components = URLComponents(string: url) else {
            return url
        }
        
        let query = components.percentEncodedQuery ?? ""
        let temp = params.compactMap({
            guard !$0.isEmpty, !$1.isEmpty else { return nil }
            guard let _ = Foundation.URL(string: $1) else {
                let encoded = $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $1
                return "\($0)=\(encoded)"
            }
            
            let string = "?!@#$^&%*+,:;='\"`<>()[]{}/\\| "
            let character = CharacterSet(charactersIn: string).inverted
            let encoded = $1.addingPercentEncoding(withAllowedCharacters: character) ?? $1
            return "\($0)=\(encoded)"
        }).joined(separator: "&")
        components.percentEncodedQuery = query.isEmpty ? temp : query + "&" + temp
        return components.url?.absoluteString ?? url
    }
}

extension Routerable {
    
    public func open(with completion: @escaping () -> Void = {}) {
        guard let controller = UIViewController.top() else {
            return
        }
        
        if let navigation = controller as? UINavigationController {
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            navigation.pushViewController(self, animated: true)
            CATransaction.commit()
            
        } else if let navigation = controller.navigationController {
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            navigation.pushViewController(self, animated: true)
            CATransaction.commit()
            
        } else {
            let navigation = UINavigationController(rootViewController: self)
            controller.present(navigation, animated: true, completion: completion)
        }
    }
    
    public func close(with completion: @escaping () -> Void = {}) {
        guard
            let navigation = navigationController,
            navigation.viewControllers.first != self else {
            let presenting = presentingViewController ?? self
            presenting.dismiss(animated: true, completion: completion)
            return
        }
        guard presentedViewController == nil else {
            dismiss(animated: true) { [weak self] in self?.close(with: completion) }
            return
        }
        
        func parents(_ controller: UIViewController) -> [UIViewController] {
            guard let parent = controller.parent else {
                return [controller]
            }
            return [controller] + parents(parent)
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        if let top = navigation.topViewController, parents(self).contains(top) {
            navigation.popViewController(animated: true)
            
        } else {
            let temp = navigation.viewControllers.filter { !parents(self).contains($0) }
            navigation.setViewControllers(temp, animated: true)
        }
        CATransaction.commit()
    }
}

extension PluginType {
    
    public func should(open target: TargetType) -> Bool {
        return true
    }
    
    public func prepare(open target: TargetType, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    public func will(open target: TargetType, controller: Routerable) {
    }
    
    public func did(open target: TargetType, controller: Routerable) {
    }
}
