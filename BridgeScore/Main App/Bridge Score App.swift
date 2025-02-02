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
        WindowGroup {
            GeometryReader { (geometry) in
                ScorecardListView()
                .onAppear() {
                    MyApp.format = (min(geometry.size.width, geometry.size.height) < 600 ? .phone : .tablet)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIScene.willConnectNotification)) { _ in
                    #if targetEnvironment(macCatalyst)
                        // prevent window in macOS from being resized down
                        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 1200, height: 880)
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
        sceneConfig.delegateClass = SceneDelegate.self
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

class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        self.window = windowScene.keyWindow
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url,
           url.scheme == "file" && url.pathExtension == "bsjson",
           let data = try? Data(contentsOf: url) {
            let _ = String(data: data, encoding: .utf8)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        Utility.mainThread {
            if let intent = userActivity.widgetConfigurationIntent(of: OpenScorecardWidgetConfiguration.self) {
                if let scorecardMO = ScorecardEntity.getLastScorecard(for: intent.filter) {
                    let details = ScorecardDetails(action: .openScorecard, scorecard: scorecardMO)
                    ScorecardListViewChange.send(details)
                }
            } else if let intent = userActivity.widgetConfigurationIntent(of: CreateScorecardWidgetConfiguration.self) {
                var layoutMO: LayoutMO?
                if let layoutId = intent.layout?.id, let layout = MasterData.shared.layouts.first(where: {$0.layoutId == layoutId}) {
                    layoutMO = layout.layoutMO
                }
                let details = ScorecardDetails(action: .createScorecard, layout: layoutMO, forceDisplayDetail: (intent.forceDisplayDetail))
                ScorecardListViewChange.send(details)
            }
        }
    }
}
