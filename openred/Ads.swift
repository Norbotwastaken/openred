//
//  Ads.swift
//  openred
//
//  Created by Norbert Antal on 8/17/23.
//

import GoogleMobileAds
import SwiftUI

struct NativeAdView: UIViewRepresentable {
    typealias UIViewType = GADNativeAdView
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var nativeAdViewModel: NativeAdViewModel
    var adUnit: Int
    
    func makeUIView(context: Context) -> GADNativeAdView {
        return Bundle.main.loadNibNamed(
            "NativeAdView",
//            "GADTMediumTemplateView",
            owner: nil,
            options: nil)?.first as! GADNativeAdView
    }
    
    func updateUIView(_ nativeAdView: GADNativeAdView, context: Context) {
        guard let nativeAd = nativeAdViewModel.ads[adUnit] ?? nil else {
            return
        }
        nativeAdView.isHidden = false
        nativeAdView.backgroundColor = UIColor.systemBackground
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.headlineView as? UILabel)?.textColor = fontColor
        
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.bodyView as? UILabel)?.textColor = fontColor
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        
        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
        
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        (nativeAdView.storeView as? UILabel)?.textColor = fontColor
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        (nativeAdView.priceView as? UILabel)?.textColor = fontColor
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        (nativeAdView.advertiserView as? UILabel)?.textColor = fontColor
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        (nativeAdView.callToActionView as? UILabel)?.textColor = fontColor
        
        //      (nativeAdView. as? UILabel)?.textColor = fontColor
        
        // In order for the SDK to process touch events properly, user interaction should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        // Associate the native ad view with the native ad object. This is required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
    
    private var fontColor: UIColor {
        colorScheme == .dark ? .white : .black
    }
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}

class NativeAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
//    @Published var nativeAd: GADNativeAd?
    @Published var ads: [Int:GADNativeAd?] = [:]
    private var adLoader: GADAdLoader!
//    private let adUnits: [String] = [
//        // main
//        "ca-app-pub-1887657859018428/7047598079",
//        // main-2
//        "ca-app-pub-1887657859018428/1645797810",
//        // main-3
//        "ca-app-pub-1887657859018428/6448614077"
//    ]
    
    private let adUnits: [String] = [
        "ca-app-pub-3940256099942544/3986624511",
        "ca-app-pub-3940256099942544/2521693316"
    ]
    
    func refreshAd(adPosition: Int = 0) {
        if adPosition > adUnits.count - 1 {
            return
        }
        adLoader = GADAdLoader(
            adUnitID: adUnits[adPosition],
            rootViewController: nil,
            adTypes: [.native], options: nil)
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        let adPosition = adUnits.firstIndex{ $0 == adLoader.adUnitID }
        if adPosition == nil {
            return
        }
        self.ads[adPosition! + 1] = nativeAd
        
        nativeAd.delegate = self
        if adPosition! < adUnits.count - 1 {
            refreshAd(adPosition: adPosition! + 1)
        }
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        let adPosition = adUnits.firstIndex{ $0 == adLoader.adUnitID }
        if adPosition == nil {
            return
        }
        print("\(adLoader) failed with error: \(error.localizedDescription)")
        self.ads[(adPosition!)] = nil
        
        if adPosition! < adUnits.count {
            refreshAd(adPosition: adPosition! + 1)
        }
    }
}

// MARK: - GADNativeAdDelegate implementation
extension NativeAdViewModel: GADNativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
}
