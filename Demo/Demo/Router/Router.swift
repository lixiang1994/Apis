//
//  Router.swift
//  Demo
//
//  Created by 李响 on 2019/4/12.
//  Copyright © 2019 swift. All rights reserved.
//

import Foundation
import UIKit
import Apis

enum Router {
    
    // 初始化Router 并传入需要的插件
    static let shared = Apis.Provider<RouterTarget>(
        plugins:
            [
                RouterLaunchPlugin(),
                RouterAccountPlugin(),
                RouterSinglePlugin()
            ]
    )
}

extension Router {
    
    /// 打开
    ///
    /// - Parameters:
    ///   - url: url
    ///   - completion: 完成回调
    /// - Returns: true or false
    @discardableResult
    static func open(_ url: URLConvertible,
                     completion: ((Bool) -> Void)? = .none) -> Bool {
        return shared.open(url, completion: completion)
    }
    
    /// 获取视图控制器
    ///
    /// - Parameters:
    ///   - url: url
    ///   - context: context
    /// - Returns: 视图控制器
    static func viewController(_ url: URLConvertible) -> UIViewController? {
        return shared.controller(url)
    }
}
