//
//  AppCoordinator.swift
//  Editions Example App
//
//  Created by Luis Ángel San Martín Rodríguez on 04/11/2019.
//

import UIKit
import RichieEditionsSDK
import os

let logging = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "App")

public class AppCoordinator {
    private let window: UIWindow
    
    @MainActor
    public init(window: UIWindow) {
        self.window = window
        
        self.window.rootViewController = LaunchViewController(nibName: "LaunchViewController", bundle: nil)
        
        self.window.makeKeyAndVisible()
        
        let richie = Richie(appIdentifier: "fi.richie.editionsTestApp")
        Task {
            do {
                let editions = try await richie.makeEditions(
                    analyticsListener: AnalyticsListenerImpl(),
                    tokenProvider: TokenProviderImpl()
                )
                self.window.rootViewController = EditionsViewController(editions: editions)
            } catch {
                print("Error initializing Editions SDK: \(error)")
            }
        }
    }
}

class TokenProviderImpl : TokenProvider {
    var hasToken: Bool { true }

    func token(reason: TokenRequestReason, trigger: TokenRequestTrigger, completion: @escaping TokenCompletion) {
        let jwtToken = "eyJhbGciOiJFUzM4NCIsImtpZCI6Im5JYVJ5d1RXNlg1WndPaXllWFNmeDhnYWVWV1d6Z2g4YkRVbUJSeVRseVUifQ.eyJlbnQiOlsiZWRpdGlvbnNfZGVtb19jb250ZW50Il0sImV4cCI6MTkyMTQ3NDgwMCwiaWF0IjoxNzAwNTUwMDAwfQ.zIoJ1htS-xpnHsOR_8ju-gVp9iNmY63424xly4fDaWgtsagoosf2vNW7DDY0gnIV_cJT8SnU0F5GrCO_CVPYT6omsG5qV4KwaGuZrL72j-g_KvO48MYmHlH8OV7oEK3w"
        
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
