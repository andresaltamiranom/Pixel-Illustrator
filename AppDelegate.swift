//
//  AppDelegate.swift
//  Pixel Artist
//
//  Created by Andres Altamirano on 6/6/18.
//  Copyright © 2018 AndresAltamirano. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UserDefaults.standard.register(defaults: ["gridIndex": -1])
        UserDefaults.standard.register(defaults: ["brushSize": CGFloat(10.0)])
        UserDefaults.standard.register(defaults: ["brushOpacity": CGFloat(1.0)])
        UserDefaults.standard.register(defaults: ["lastDrawing": Data()])
        UserDefaults.standard.register(defaults: ["brushColor": Data()])
        UserDefaults.standard.register(defaults: ["pixelationCounter": 0])
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}
}

