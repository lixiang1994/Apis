//
//  RouterAccountPlugin.swift
//  Demo
//
//  Created by 李响 on 2019/4/10.
//  Copyright © 2019 swift. All rights reserved.
//

import Apis

class RouterAccountPlugin: Apis.PluginType {
    
    /*
        在准备打开阶段 拦截需要登录的类型, 并根据登录状态处理是否需要打开登录页面
        登录成功后可执行回调继续打开流程
     */
    func prepare(open target: TargetType, completion: @escaping (Bool) -> Void) {
        guard case .open_needlogin = target as? RouterTarget else {
            completion(true)
            return
        }
        guard !Account.isLogin else {
            completion(true)
            return
        }
        guard let root = AppDelegate.shared.window?.rootViewController else {
            completion(false)
            return
        }
        let controller = LoginViewController.init { (result) in
            completion(result)
        }
        root.present(controller, animated: true)
    }
}
