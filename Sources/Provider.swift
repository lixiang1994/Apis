//
//  Provider.swift
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

private let navigator = URLNavigator()

/// 打开 (全局)
///
/// - Parameters:
///   - url: url
///   - completion: 打开完成回调
/// - Returns: true or false
@discardableResult
public func open(_ url: URLConvertible,
                 completion: ((Bool) -> Void)? = .none) -> Bool {
    return navigator.open(url, context: Context(completion ?? { _ in }))
}

/// 获取视图控制器 (全局)
///
/// - Parameters:
///   - url: url
///   - context: context
/// - Returns: 视图控制器
public func controller(_ url: URLConvertible) -> Routerable? {
    return navigator.viewController(for: url) as? Routerable
}

public class Provider<Target: TargetType> {
    
    private let plugins: [PluginType]
    
    public init(plugins: [PluginType]) {
        self.plugins = plugins
    }
}

extension Provider where Target: TargetType {
    
    /// 打开
    ///
    /// - Parameters:
    ///   - target: TargetType
    ///   - completion: 打开完成回调
    /// - Returns: true or false
    @discardableResult
    public func open(_ target: Target, completion: ((Bool) -> Void)? = .none) -> Bool {
        if self.plugins.isEmpty {
            switch target.task {
            case .controller(let controller):
                controller.open {
                    completion?(true)
                }
                
            case .handle(working: let closure):
                closure { result in
                    completion?(result)
                }
            }
            
            return true
            
        } else {
            guard self.plugins.contains(where: { $0.should(open: target) }) else {
                return false
            }
            
            var result = true
            let total = self.plugins.count
            var count = 0
            let group = DispatchGroup()
            self.plugins.forEach { p in
                group.enter()
                p.prepare(open: target) {
                    // 防止插件多次回调
                    defer { count += 1 }
                    guard count < total else { return }
                    
                    result = $0 ? result : false
                    group.leave()
                }
            }
            
            group.notify(queue: .main) { [weak self] in
                guard let self = self else {
                    completion?(false)
                    return
                }
                guard result else {
                    completion?(false)
                    return
                }
                
                switch target.task {
                case .controller(let controller):
                    self.plugins.forEach {
                        $0.will(open: target, controller: controller)
                    }
                    
                    controller.open { [weak self] in
                        guard let self = self else { return }
                        self.plugins.forEach {
                            $0.did(open: target, controller: controller)
                        }
                        
                        completion?(true)
                    }
                    
                case .handle(working: let closure):
                    closure { result in
                        completion?(result)
                    }
                }
            }
            
            return true
        }
    }

    /// 获取视图控制器
    ///
    /// - Parameters:
    ///   - target: TargetType
    /// - Returns: 视图控制器
    public func controller(_ target: Target) -> Routerable? {
        guard case .controller(let controller) = target.task else {
            return nil
        }
        return controller
    }
}

extension Provider where Target: URLTargetType {
    
    /// 打开
    ///
    /// - Parameters:
    ///   - url: url
    ///   - completion: 打开完成回调
    /// - Returns: true or false
    @discardableResult
    public func open(_ url: URLConvertible,
                     completion: ((Bool) -> Void)? = .none) -> Bool {
        let patterns = Target.bindings.map({ $0.pattern })
        guard let result = navigator.matcher.match(url, from: patterns) else {
            return false
        }
        guard let target = self.target(result.pattern, url, result.values) else {
            return false
        }
        return open(target, completion: completion)
    }

    /// 获取视图控制器
    ///
    /// - Parameters:
    ///   - url: url
    ///   - context: context
    /// - Returns: 视图控制器
    public func controller(_ url: URLConvertible) -> Routerable? {
        let patterns = Target.bindings.map({ $0.pattern })
        guard let result = navigator.matcher.match(url, from: patterns) else {
            return nil
        }
        guard let target = self.target(result.pattern, url, result.values) else {
            return nil
        }
        return controller(target)
    }
}

extension Provider where Target: URLTargetType {
    
    /// 加入全局
    public func global() {
        Target.bindings.forEach { binding in
            self.binding(binding.pattern)
        }
    }
    
    private func target(_ pattern: URLPattern, _ url: URLConvertible, _ values: [String : Any]) -> Target? {
        guard let binding = Target.bindings.last(where: { $0.pattern == pattern }) else {
            return nil
        }
        return binding.target(.init(url: url, values: values))
    }
    
    typealias ViewControllerFactory = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Routerable?
    
    private func register(_ pattern: URLPattern, _ factory: @escaping ViewControllerFactory) {
        navigator.register(pattern) { (url, values, context) -> UIViewController? in
            return factory(url, values, context)
        }
    }
    
    private func handle(_ pattern: URLPattern, _ factory: @escaping URLOpenHandlerFactory) {
        navigator.handle(pattern) { (url, values, context) -> Bool in
            return factory(url, values, context)
        }
    }
    
    private func binding(_ pattern: URLPattern) {
        self.register(pattern) { [weak self] (url, values, context) -> Routerable? in
            guard let self = self else { return nil }
            guard let target = self.target(pattern, url, values) else {
                return nil
            }
            return self.controller(target)
        }
        self.handle(pattern) { [weak self] (url, values, context) -> Bool in
            guard let self = self else { return false }
            guard let target = self.target(pattern, url, values) else {
                return false
            }
            let context = context as? Context
            return self.open(target, completion: context?.callback)
        }
    }
}
