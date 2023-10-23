//
//  BridgeScore App.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/01/2022.
//

import SwiftUI
import UIKit
import CoreData
import Combine

@main
struct BridgeScoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public let context = PersistenceController.shared.container.viewContext

    init() {
        CoreData.context = context
        
        MyApp.shared.start()
    }
    
    var body: some Scene {
        MyScene()
    }
}

struct MyScene: Scene {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {GeometryReader
            { (geometry) in
                ScorecardListView()
                .onAppear() {
                    MyApp.format = (min(geometry.size.width, geometry.size.height) < 600 ? .phone : .tablet)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIScene.willConnectNotification)) { _ in
                    #if targetEnvironment(macCatalyst)
                        // prevent window in macOS from being resized down
                        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 1150, height: 880)
                            windowScene.sizeRestrictions?.allowsFullScreen = false
                        }
                    #endif
                }
            }
        }
        .onChange(of: scenePhase, initial: false) { (_, phase) in
            if phase == .active {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    #if targetEnvironment(macCatalyst)
                        if let titlebar = scene.titlebar {
                            titlebar.titleVisibility = .hidden
                            titlebar.toolbar = nil
                        }
                    #endif
                }
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = MySceneDelegate.self
        return sceneConfig
      }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        if builder.system == UIMenuSystem.main {
            builder.remove(menu: .services)
            builder.remove(menu: .format)
            builder.remove(menu: .file)
            builder.remove(menu: .view)
        }
    }
}

class MySceneDelegate: NSObject, UIWindowSceneDelegate {
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
    }
    
}
