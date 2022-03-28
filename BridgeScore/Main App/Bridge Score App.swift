//
//  BridgeScore App.swift
//  BridgeScore
//
//  Created by Marc Shearer on 20/01/2022.
//

import SwiftUI
import UIKit
import CoreData

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
            }
        }
        .onChange(of: scenePhase) { phase in
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
