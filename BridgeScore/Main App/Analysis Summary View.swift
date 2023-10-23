//
//  Analysis Summary View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 14/10/2023.
//

import UIKit

class AnalysisSummaryView: UIView {
    private var contentView = UIView()
    private var viewTapped: (()->())?
    private var statusImage = UIImageView()
    private var textLabel = UILabel()
    private var impactLabel = UILabel()
    private var impactWidth: NSLayoutConstraint!
    private var statusLeading: NSLayoutConstraint?
    private var textLeading: NSLayoutConstraint?
    private var impactLeading: NSLayoutConstraint?
    private var impactTrailing: NSLayoutConstraint?
    private var statusWidth: NSLayoutConstraint!
    private var tapGesture: UITapGestureRecognizer!

    private var summary: AnalysisSummaryData?
    private var board: BoardViewModel!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadAnalysisView()
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        loadAnalysisView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        statusLeading?.constant = frame.width < 150 ? 0 : 8
        textLeading?.constant = frame.width < 150 ? 0 : 8
        impactLeading?.constant = frame.width < 150 ? 0 : 8
        impactTrailing?.constant = frame.width < 150 ? 0 : -8
        statusWidth.constant = frame.width < 150 ? 0 : 30
        impactWidth.constant = frame.width < 150 ? 0 : (summary?.impactDescription != "" ? 60 : 0)
    }
    
    @objc internal func viewTappedHandler(_ touch: UITapGestureRecognizer) {
        viewTapped?()
    }
    
    public func prepareForReuse() {
        self.summary = nil
        
        statusImage.isHidden = true
        statusImage.image = UIImage()
        statusImage.tintColor = nil
        statusWidth.constant = 0
        statusLeading?.constant = 0

        textLabel.isHidden = true
        textLabel.attributedText = NSAttributedString("")
        textLabel.layer.opacity = 1
        textLeading?.constant = 0

        impactLabel.isHidden = true
        impactLabel.attributedText = NSAttributedString("")
        impactWidth.constant = 0
        impactLeading?.constant = 0
        impactTrailing?.constant = 0
        
        // tapGesture.isEnabled = false
    }
    
    public func set(board: BoardViewModel, summary: AnalysisSummaryData, hideRejected: Bool = true, viewTapped: (()->())? = nil) {
        self.board = board
        self.summary = summary
        self.viewTapped = viewTapped

        tapGesture.isEnabled = true

        if summary.status >= .ok || (hideRejected && summary.status == .rejected) {
            statusImage.isHidden = true
            textLabel.isHidden = true
            impactLabel.isHidden = true
        } else {
            let opacity: CGFloat = (summary.status == .rejected ? 0.3 : 1.0)
            contentView.isHidden = false
            
            statusImage.isHidden = false
            statusImage.image = summary.status.uiImage
            statusImage.tintColor = summary.status.tintColor.withAlphaComponent(opacity)

            textLabel.isHidden = false
            textLabel.attributedText = summary.attributedText
            textLabel.layer.opacity = Float(opacity)
            
            impactLabel.isHidden = false
            impactLabel.attributedText = NSAttributedString(summary.impactDescription)
            impactLabel.textColor = UIColor(Palette.background.text).withAlphaComponent(opacity)
        }
    }
    
    private func loadAnalysisView() {
        addSubview(contentView, constant: 0, anchored: .all)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(AnalysisSummaryView.viewTappedHandler(_:)))
        contentView.addGestureRecognizer(tapGesture)
        contentView.isUserInteractionEnabled = true
        
        statusLeading = contentView.addSubview(statusImage, constant: 8, anchored: .leading).first
        Constraint.anchor(view: contentView, control: statusImage, constant: 0, attributes: .centerY)
        statusWidth = Constraint.setWidth(control: statusImage, width: 0)
        statusImage.backgroundColor = UIColor.clear
        statusImage.contentMode = .scaleAspectFill
        
        contentView.addSubview(textLabel, constant: 0, anchored: .top, .bottom)
        textLeading = Constraint.anchor(view: contentView, control: textLabel, to: statusImage, constant: 0, toAttribute: .trailing, attributes: .leading).first
        textLabel.backgroundColor = UIColor.clear
        textLabel.font = analysisFont
        textLabel.minimumScaleFactor = 0.3
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        
        contentView.addSubview(impactLabel, constant: 0, anchored: .top, .bottom)
        impactLeading = Constraint.anchor(view: contentView, control: impactLabel, to: textLabel, constant: 0, toAttribute: .trailing, attributes: .leading).first
        impactTrailing = Constraint.anchor(view: contentView, control: impactLabel, constant: 0, attributes: .trailing).first
        impactWidth = Constraint.setWidth(control: impactLabel, width: 0)
        impactLabel.backgroundColor = UIColor.clear
        impactLabel.font = analysisFont.bold
        impactLabel.minimumScaleFactor = 0.3
        impactLabel.adjustsFontSizeToFitWidth = true
        impactLabel.textAlignment = .right
    }
}
