//
//  Scorecard Web View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 29/03/2022.
//

import UIKit
import CoreMedia
import WebKit

class ScorecardWebView: UIView, WKNavigationDelegate {
       
    private var sourceView: UIView!
    private var completion: (()->())? = nil
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var containerView = UIView()
    private var closeButton = UILabel()
    private var closeImage = UIImageView()
    private var messageLabel = UILabel()
    private var webView = WKWebView()
    private var webWidth: [NSLayoutConstraint] = []
    private var webHeight: [NSLayoutConstraint] = []
    private var url: URL?
    private var buttonSpacing: CGFloat = 25
    private var buttonHeight: CGFloat = 50
    private var buttonWidth: CGFloat = 160
    private var paddingSize: CGFloat = 20
    private var aspectMultiplier: CGFloat = 1.33
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadScorecardWebView()
        
        // Handle rotations
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] (notification) in
            print("bounds layout")
            self?.setNeedsLayout()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setFrames()
        contentView.roundCorners(cornerRadius: 20)
        closeButton.roundCorners(cornerRadius: 10)
    }
    
    // MARK: - Tap handlers ============================================================================ -
    
    @objc private func cancelPressed(_ sender: Any) {
        self.endEditing(true)
        hide()
    }
    
    func cancelTap(_: Int) {
        cancelPressed(self)
    }
    
    // MARK: - Show / Hide ============================================================================ -
    
    public func show(from sourceView: UIView, url: URL, completion: (()->())? = nil) {
        self.sourceView = sourceView
        self.completion = completion
        self.url = url
        self.layoutIfNeeded()
        sourceView.addSubview(self)
        self.setFrames()
        self.bringSubviewToFront(contentView)
        contentView.isHidden = false
        webView.load(URLRequest(url: url))
    }
    
    private func setFrames() {
        let bounds = UIScreen.main.bounds
        print("bounds: \(bounds)")
        if frame != bounds {
            let bannerHeight: CGFloat = (MyApp.format == .phone ? 0 : bannerHeight)
            let fraction: CGFloat = (MyApp.format == .phone ? 0.99 : 0.9)
            let widthAdd: CGFloat = (MyApp.format == .phone && isLandscape ? 50 : 0)
            let heightAdd: CGFloat = (MyApp.format == .phone && !isLandscape ? 100 : 0)

            backgroundView.frame = bounds
            frame = bounds
            let padding = bannerHeight + safeAreaInsets.top + safeAreaInsets.bottom
            let buttonAreaHeight = (MyApp.format == .phone ? 0 : buttonHeight + (buttonSpacing * 2))
            
            let availableHeight = ((bounds.height - padding) * fraction) - buttonAreaHeight
            let availableWidth = bounds.width * fraction
            
            let height = min(availableHeight, availableWidth / aspectMultiplier) + buttonAreaHeight + heightAdd
            let width = min(availableWidth, availableHeight * aspectMultiplier) + widthAdd
            contentView.frame = CGRect(x: bounds.midX - (width / 2), y: ((bannerHeight + safeAreaInsets.top) / 2) + bounds.midY - (height / 2), width: width, height: height)
            
            layoutIfNeeded()
            webHeight.forEach{ (constraint) in constraint.isActive = false }
            webWidth.forEach{ (constraint) in constraint.isActive = !isLandscape }
            webHeight.forEach{ (constraint) in constraint.isActive = isLandscape }
            layoutIfNeeded()
        }
    }
    
    public func hide() {
        self.completion?()
        removeFromSuperview()
    }
    
    internal func webView(_ webView: WKWebView, didFail: WKNavigation!, withError: Error) {
        navigationError()
    }
    
    internal func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        navigationError()
    }
    
    func navigationError() {
        messageLabel.text = "Unable to reach online hand viewer. Check internet connection."
    }
    
    private func loadScorecardWebView() {

        // Background
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let cancelSelector = #selector(ScorecardWebView.cancelPressed(_:))
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        // Content view
        addSubview(contentView)
        contentView.backgroundColor = UIColor(Palette.background.background)
        contentView.addShadow()
        
        // Add container view
        contentView.addSubview(containerView, anchored: .leading, .trailing, .top)
        Constraint.anchor(view: contentView, control: containerView, to: contentView, constant: (MyApp.format == .phone ? paddingSize : buttonHeight + (2 * buttonSpacing)), attributes: .bottom)
        
        // Web view
        containerView.addSubview(webView, anchored: .centerX, .centerY)
        Constraint.aspectRatio(control: webView, multiplier: aspectMultiplier)
        webWidth = Constraint.anchor(view: containerView, control: webView, to: containerView, constant: paddingSize, attributes: .horizontal)
        webHeight = Constraint.anchor(view: containerView, control: webView, to: containerView, constant: paddingSize, attributes: .vertical)
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = self
        
        // Message
        containerView.addSubview(messageLabel)
        Constraint.anchor(view: containerView, control: messageLabel, to: containerView, constant: 10, attributes: .all)
        messageLabel.backgroundColor = UIColor.clear
        messageLabel.font = windowTitleFont
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 3

        // Close button
        if MyApp.format == .phone {
            containerView.addSubview(closeImage, constant: paddingSize, anchored: .leading, .top)
            Constraint.setHeight(control: closeImage, height: 30)
            Constraint.aspectRatio(control: closeImage)
            closeImage.image = UIImage(systemName: "xmark")
            closeImage.tintColor = UIColor(Palette.background.text)
            let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
            closeImage.addGestureRecognizer(tapGesture)
            closeImage.isUserInteractionEnabled = true
        } else {
            contentView.addSubview(closeButton, anchored: .centerX)
            Constraint.setHeight(control: closeButton, height: buttonHeight)
            Constraint.setWidth(control: closeButton, width: buttonWidth)
            Constraint.anchor(view: contentView, control: closeButton, constant: buttonSpacing, attributes: .bottom)
            closeButton.backgroundColor = UIColor(Palette.highlightButton.background)
            closeButton.textColor = UIColor(Palette.highlightButton.text)
            closeButton.textAlignment = .center
            closeButton.text = "Close"
            closeButton.font = replaceTitleFont.bold
            let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
            closeButton.addGestureRecognizer(tapGesture)
            closeButton.isUserInteractionEnabled = true
        }

        contentView.isHidden = true
    }
}
