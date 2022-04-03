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
       
    private var backgroundView = UIView()
    private var contentView = UIView()
    private var closeButton = UILabel()
    private var messageLabel = UILabel()
    private var webView = WKWebView()
    private var url: URL?
    private var buttonSpacing: CGFloat = 25
    private var buttonHeight: CGFloat = 50
    private var buttonWidth: CGFloat = 160
    private var paddingSize: CGFloat = 20
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadScorecardWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
    
    public func show(from sourceView: UIView, url: URL) {
        self.frame = sourceView.frame
        self.url = url
        backgroundView.frame = sourceView.frame
        sourceView.addSubview(self)
        sourceView.bringSubviewToFront(self)
        let padding = bannerHeight + safeAreaInsets.top + safeAreaInsets.bottom
        let height = (sourceView.frame.height - padding) * 0.90
        let width = (height - buttonHeight - (buttonSpacing * 2)) * 1.33
        contentView.frame = CGRect(x: sourceView.frame.midX - (width / 2), y: ((bannerHeight + safeAreaInsets.top) / 2) + sourceView.frame.midY - (height / 2), width: width, height: height)
        self.bringSubviewToFront(contentView)
        contentView.isHidden = false
        webView.load(URLRequest(url: url))
    }
    
    public func hide() {
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

        // Web view
        contentView.addSubview(webView, constant: paddingSize, anchored: .leading, .trailing, .top)
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = self
        
        // Message
        contentView.addSubview(messageLabel)
        Constraint.anchor(view: contentView, control: messageLabel, to: webView, constant: 100, attributes: .all)
        messageLabel.font = windowTitleFont
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 3

        // Close button
        contentView.addSubview(closeButton, anchored: .centerX)
        Constraint.setHeight(control: closeButton, height: buttonHeight)
        Constraint.setWidth(control: closeButton, width: buttonWidth)
        Constraint.anchor(view: contentView, control: closeButton, constant: buttonSpacing, attributes: .bottom)
        Constraint.anchor(view: contentView, control: closeButton, to: webView, constant: buttonSpacing, toAttribute: .bottom, attributes: .top)
        closeButton.backgroundColor = UIColor(Palette.highlightButton.background)
        closeButton.textColor = UIColor(Palette.highlightButton.text)
        closeButton.textAlignment = .center
        closeButton.text = "Close"
        closeButton.font = replaceTitleFont
        let tapGesture = UITapGestureRecognizer(target: self, action: cancelSelector)
        closeButton.addGestureRecognizer(tapGesture)
        closeButton.isUserInteractionEnabled = true

        contentView.isHidden = true
    }
}
