//
//  Navigator.swift
//  ┌─┐      ┌───────┐ ┌───────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ │      │ └─────┐ │ └─────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ └─────┐│ └─────┐ │ └─────┐
//  └───────┘└───────┘ └───────┘
//
//  Created by lee on 2021/12/10.
//  Copyright © 2021 lee. All rights reserved.
//

import UIKit

typealias ViewControllerFactory = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> UIViewController?
typealias URLOpenHandlerFactory = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Bool
typealias URLOpenHandler = () -> Bool

class URLNavigator {
    
    let matcher = URLMatcher()
    
    private var controllerFactories = [URLPattern: ViewControllerFactory]()
    private var handlerFactories = [URLPattern: URLOpenHandlerFactory]()
    
    func register(_ pattern: URLPattern, _ factory: @escaping ViewControllerFactory) {
        self.controllerFactories[pattern] = factory
    }
    
    func handle(_ pattern: URLPattern, _ factory: @escaping URLOpenHandlerFactory) {
        self.handlerFactories[pattern] = factory
    }
    
    func viewController(for url: URLConvertible, context: Any? = nil) -> UIViewController? {
        let urlPatterns = Array(self.controllerFactories.keys)
        guard let match = self.matcher.match(url, from: urlPatterns) else { return nil }
        guard let factory = self.controllerFactories[match.pattern] else { return nil }
        return factory(url, match.values, context)
    }
    
    func handler(for url: URLConvertible, context: Any?) -> URLOpenHandler? {
        let urlPatterns = Array(self.handlerFactories.keys)
        guard let match = self.matcher.match(url, from: urlPatterns) else { return nil }
        guard let handler = self.handlerFactories[match.pattern] else { return nil }
        return { handler(url, match.values, context) }
    }
    
    @discardableResult
    func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
        guard let handler = self.handler(for: url, context: context) else { return false }
        return handler()
    }
}
