//
//  UIViewControllerExtension.swift
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

extension UIViewController {
    
    /// 获取Window下的顶层控制器
    open class func top(in window: UIWindow? = .none) -> UIViewController? {
        return (window ?? UIApplication.shared.window)?.rootViewController?.top()
    }
    
    open func top() -> UIViewController {
        // presented view controller
        if let controller = presentedViewController {
            return controller.top()
        }
        
        // UITabBarController
        if let tabBarController = self as? UITabBarController,
            let controller = tabBarController.selectedViewController {
            return controller.top()
        }
        
        // UINavigationController
        if let navigationController = self as? UINavigationController,
            let controller = navigationController.visibleViewController {
            return controller.top()
        }
        
        // UIPageController
        if let pageViewController = self as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 ,
           let controller = pageViewController.viewControllers?.first {
            return controller.top()
        }
        
        // child view controller
//        for subview in self.view?.subviews ?? [] {
//            if let controller = subview.next as? UIViewController {
//                return controller.top()
//            }
//        }
        return self
    }
}
