//
//  Ads.swift
//  openred
//
//  Created by Norbert Antal on 8/17/23.
//

import GoogleMobileAds
import SwiftUI

// MARK: - Helper to present Interstitial Ad
struct AdViewControllerRepresentable: UIViewControllerRepresentable {
  let viewController = UIViewController()

  func makeUIViewController(context: Context) -> some UIViewController {
    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

class InterstitialAdCoordinator: NSObject, GADFullScreenContentDelegate {
    private var interstitial: GADInterstitialAd?
    var userSessionManager: UserSessionManager?
    
    func loadAd(show: Bool = false, from viewController: UIViewController? = nil) {
        GADInterstitialAd.load(
            withAdUnitID: "ca-app-pub-1887657859018428/7104933625", request: GADRequest()
        ) { ad, error in
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            if show && viewController != nil {
                self.showAd(from: viewController!)
            }
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitial = nil
    }
    
    func showAd(from viewController: UIViewController) {
        guard let interstitial = interstitial else {
            return print("Ad wasn't ready")
        }
        
        if userSessionManager != nil {
            userSessionManager!.markAdPresented()
        }
        interstitial.present(fromRootViewController: viewController)
    }
    
    var hasAd: Bool {
        interstitial != nil
    }
}
