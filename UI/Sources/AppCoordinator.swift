//
//  AppCoordinator.swift
//  Editions Example App
//
//  Created by Luis Ángel San Martín Rodríguez on 04/11/2019.
//

import UIKit
import RichieEditionsSDK

public class AppCoordinator {
    private let window: UIWindow
    
    public init(window: UIWindow) {
        self.window = window
        let editions = Editions(bundleId: "fi.richie.editionsTestApp",
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
    var hasToken: Bool { true }

    func token(reason: TokenRequestReason, trigger: TokenRequestTrigger, completion: @escaping TokenCompletion) {
        let jwtToken = "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCIsImtpZCI6InJpY2hpZS1ib29rcy1kZXYifQ.eyJlbnQiOlsiZGV2LWFsbC1hY2Nlc3MiXSwiZXhwIjoxNzE3NDExMjk5LCJpc3MiOiJyaWNoaWUtYm9va3MtZGV2Iiwic3ViIjoicmljaGllLWJvb2tzLWRldiIsImlhdCI6MTU1OTU1ODU2NH0.mC8jbluWgSMa6f0b4fGesZElNr74S36tMAQFPjSyGwINjBNnbf-NG9DXgO6qwyhKk1RgnkpfyiRxkzfrYjkHhgDCPMlcNsA_MvWWdCEehOn3DE5HsvxS2Ev21fotXDXb"
        
        switch reason {
            
        case .noToken:
            // Here, the host app would get this JWT token from user login flow and return it to Richie SDK asynchronously.
            // For subsequent token requests, the host app would cache the token in memory for faster retrieval.
            // For demo purposes, we are using hardcoded JWT token generated by Richie.
            completion(jwtToken)
        case .noAccess:
            // Here, the host app would attempt to refresh the JWT token using app-specific auth backend.
            // This case is used if token provided in .noToken case was invalid or expired.
            Log.error("Current token is invalid.")
            completion(nil)
        case .noEntitlements:
            // Here, the host app would notify the user that he/she does not have enough entitlements for accessing the selected content.
            // This case is used if token provided in .noToken case was valid, but didn't provide enough entitlements for content.
            Log.error("Current token is not entitled to the selected content.")
            completion(nil)
        @unknown default:
            assertionFailure("Unknown token request reason: \(reason)")
            Log.error("Unknown token request reason: \(reason)")
            completion(nil)
        }
    }
}


class AnalyticsListenerImpl: AnalyticsListener {
    func onAnalyticsEvent(event: AnalyticsEvent) {
        Log.debug("Analytics event received: \(event.name) -> \(event.parameters)")
    }
}
