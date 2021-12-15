//
//  UIApplicationExtension.swift
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

extension UIApplication {
    
    var window: UIWindow? {
        if #available(iOS 13.0, *) {
            let windows: [UIWindow] = UIApplication.shared.connectedScenes.compactMap { scene in
                guard let scene = scene as? UIWindowScene else { return nil }
                guard scene.session.role == .windowApplication else { return nil }
                guard let delegate = scene.delegate as? UIWindowSceneDelegate else { return nil }
                guard let window = delegate.window else { return nil }
                guard let window = window else { return nil }
                return window
            }
            
            if windows.isEmpty {
                guard let delegate = UIApplication.shared.delegate else { return nil }
                guard let window = delegate.window else { return nil }
                return window
                
            } else {
                return windows.first
            }
            
        } else {
            guard let delegate = UIApplication.shared.delegate else { return nil }
            guard let window = delegate.window else { return nil }
            return window
        }
    }
}

