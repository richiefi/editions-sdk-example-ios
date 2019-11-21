//
//  AppCoordinator.swift
//  Editions Example App
//
//  Created by Luis Ángel San Martín Rodríguez on 04/11/2019.
//

import UIKit
import RichieSDK

public class AppCoordinator {
    private let window: UIWindow
    
    public init(window: UIWindow) {
        self.window = window
        let editions = Editions(appId: "fi.richie.editionsTestApp",
                                tokenProvider: TokenProviderImpl(),
                                analyticsListener: AnalyticsListenerImpl())
        
        self.window.rootViewController = LaunchViewController(nibName: "LaunchViewController", bundle: nil)

        self.window.makeKeyAndVisible()
        
        editions.initialize { success in
            if success {
                self.window.rootViewController = EditionsViewController(editions: editions)
            }
        }
    }
}

class TokenProviderImpl : TokenProvider {
    func token(reason: TokenRequestReason, trigger: TokenRequestTrigger, completion: @escaping TokenCompletion) {
        //TODO provide here a valid token
        completion("")
    }
}


class AnalyticsListenerImpl: AnalyticsListener {
    func onAnalyticsEvent(event: AnalyticsEvent) {
        Log.debug("Analytics event received: \(event.name) -> \(event.parameters)")
    }
}
