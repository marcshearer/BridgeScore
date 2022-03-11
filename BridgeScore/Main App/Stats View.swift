//
//  Stats View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 10/03/2022.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var filterValues = ScorecardFilterValues()
    
    var body: some View {
        StandardView("Stats", slideIn: true) {
            VStack(spacing: 0) {
                Banner(title: Binding.constant("Statistics"), back: true, backAction: backAction)
                DoubleColumnView(leftWidth: 350) {
                    StatsFilterView(filterValues: filterValues)
                } rightView: {
                    StatsWrapperView(filterValues: filterValues)
                }
            }
        }
    }
    
    private func backAction() -> Bool {
        presentationMode.wrappedValue.dismiss()
        return true
    }
}

struct StatsFilterView: View {
    @ObservedObject var filterValues: ScorecardFilterValues
    @State private var partnerIndex: Int?
    @State private var locationIndex: Int?
    let players = MasterData.shared.players.filter{!$0.retired}
    let locations = MasterData.shared.locations.filter{!$0.retired}
    let types = Type.allCases
    
    var body: some View {
        
        HStack {
            Spacer().frame(width: 16)
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    HStack {
                        Text("FILTER BY:").font(.title3).foregroundColor(Palette.tile.faintText)
                        Spacer()
                    }
                    Spacer().frame(height: 20)
                    
                    PickerInput(field: $partnerIndex, values: {["No partner filter"] + players.map{$0.name}}, popupTitle: "Partners", placeholder: "Partner", height: 40, centered: true, color: (partnerIndex != nil ? Palette.filterUsed : Palette.filterUnused), font: searchFont, cornerRadius: 20, animation: .none) { (index) in
                        if index ?? 0 != 0 {
                            filterValues.partner = players[index! - 1]
                        } else {
                            partnerIndex = nil
                            filterValues.partner = nil
                        }
                    }
                    
                    Spacer().frame(height: 15)
                    
                    PickerInput(field: $locationIndex, values: {["No location filter"] + locations.map{$0.name}}, popupTitle: "Locations", placeholder: "Location", height: 40, centered: true, color: (locationIndex != nil ? Palette.filterUsed : Palette.filterUnused), font: searchFont, cornerRadius: 20, animation: .none) { (index) in
                        if index ?? 0 != 0 {
                            filterValues.location = locations[index! - 1]
                        } else {
                           locationIndex = nil
                           filterValues.location = nil
                        }
                    }
                }
                
                VStack(spacing: 0) {
                    
                    Spacer().frame(height: 15)
                    
                    OptionalDatePickerInput(field: $filterValues.dateFrom, placeholder: "Date from", clearText: "Clear date from", to: filterValues.dateTo, color: (filterValues.dateFrom != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, font: searchFont, cornerRadius: 20, height: 40, centered: true)
                    
                    Spacer().frame(height: 15)
                    
                    OptionalDatePickerInput(field: $filterValues.dateTo, placeholder: "Date to", clearText: "Clear date to", from: filterValues.dateFrom, color: (filterValues.dateTo != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, font: searchFont, cornerRadius: 20, height: 40, centered: true)
                    
                    Spacer()
                }
            }
            Spacer().frame(width:16)
        }
        .background(Palette.tile.background)
        .onAppear {
            partnerIndex = filterValues.partner == nil ? nil : (players.firstIndex(where: {$0 == filterValues.partner})  ?? -1) + 1
            locationIndex = filterValues.location == nil ? nil : (locations.firstIndex(where: {$0 == filterValues.location})  ?? -1) + 1
        }
    }
    
    private func reset() {
        filterValues.partner = nil
        filterValues.location = nil
        filterValues.dateFrom = nil
        filterValues.dateTo = nil
        filterValues.types = nil
        filterValues.searchText = ""
    }
}

struct StatsWrapperView: UIViewRepresentable {
    @ObservedObject var filterValues: ScorecardFilterValues
    @State var values: [CGFloat] = []
    @State var drillRef: [String] = []
    @State var xAxisLabels: [String] = []
    
    func makeUIView(context: Context) -> StatsUIView {
        let view = StatsUIView(filterValues: filterValues)
       
        return view
    }

    func updateUIView(_ uiView: StatsUIView, context: Context) {
        uiView.set(filterValues: filterValues)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        
        override init() {
            
        }
    }
}

class StatsUIView: UIView, GraphDetailDelegate {
    private var filterValues: ScorecardFilterValues
    private var graphView = GraphView()
    private var values: [CGFloat] = []
    private var drillRef: [String] = []
    private var xAxisLabels: [String] = []
    private let statsDetailView = StatsDetailView(frame: CGRect(origin: .zero, size: CGSize(width: 400, height: 200)))
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawGraph()
        graphView.setNeedsDisplay()
    }
    
    init(filterValues: ScorecardFilterValues) {
        self.filterValues = filterValues
        super.init(frame: CGRect.zero)
        addSubview(graphView, anchored: .all)
        let graphGesture = UITapGestureRecognizer(target: self, action: #selector(StatsUIView.clearDetail(_:)))
        graphView.addGestureRecognizer(graphGesture)
        let detailGesture = UITapGestureRecognizer(target: self, action: #selector(StatsUIView.clearDetail(_:)))
        statsDetailView.addGestureRecognizer(detailGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func set(filterValues: ScorecardFilterValues) {
        self.filterValues = filterValues
        setNeedsLayout()
    }
    
    @objc private func clearDetail(_ sender: Any) {
        statsDetailView.hide()
    }
    
    func drawGraph() {
        var values: [CGFloat] = []
        var drillRef: [String] = []
        var xAxisLabels: [String] = []
        let phoneSize = MyApp.format == .phone
        let portraitPhoneSize = phoneSize && frame.height > frame.width
        let showLimit = (portraitPhoneSize ? 12 : (phoneSize ? 25 : 100))
        
        // Initialise the view
        graphView.reset()
        graphView.backgroundColor = UIColor(Palette.alternate.background)
        graphView.setColors(axis: UIColor(Palette.background.text), gradient: [UIColor(Palette.tile.background), UIColor(Palette.tile.background)])
        graphView.setXAxis(hidden: true, fractionMin: 1.0)
        
        // Build data
        var count = 0
        var total: Float = 0
        values = []
        for scorecard in MasterData.shared.scorecards.reversed() {
            if let score = scorecard.score {
                if filterValues.filter(scorecard) {
                    count += 1
                    let score = (score <= 20 ? score * 5 : score)
                    total += score
                    values.append(CGFloat(score))
                    drillRef.append(scorecard.scorecardId.uuidString)
                    xAxisLabels.append(Utility.dateString(scorecard.date))
                }
            }
        }
        
        let average = total / Float(count)
        
        if values.count > showLimit {
            values = values.suffix(showLimit)
            drillRef = drillRef.suffix(showLimit)
            xAxisLabels = xAxisLabels.suffix(showLimit)
        }
        
        // Reset
        graphView.reset()
        
        if values.count > 1 {
            
            // Add average score line
            graphView.addDataset(values: [CGFloat(average), CGFloat(average)], weight: 3.0, color: UIColor(Palette.gridLine).withAlphaComponent(0.4))
            graphView.addYaxisLabel(text: "\(average.toString(places: 2))", value: CGFloat(average), position: .right, color: UIColor(Palette.background.strongText))
            if !portraitPhoneSize {
                graphView.addYaxisLabel(text: "Average", value: CGFloat(average), position: .left, color: UIColor(Palette.background.strongText))
            } else {
            }
            
            // Add 5% lines
            for count in 0...8 {
                let value = CGFloat(30) + (CGFloat(count) * 5)
                if abs(CGFloat(average) - value) > 2 || value == 50 {
                    graphView.addDataset(values: [value, value], weight: (value == 50 ? 2.0 : 1.0), color: (value == 50 ? UIColor.black : UIColor.white))
                    if abs(CGFloat(average) - value) > 6 {
                        graphView.addYaxisLabel(text: "\(value)%", value: value, position: .right, color: UIColor.white)
                    }
                }
            }
            
            // Add notional invisible min and max lines
            let lowerBound = CGFloat(max(-5, Int((values.min()! - 5) * 5) / 5))
            graphView.addDataset(values: [lowerBound, lowerBound], weight: 0, color: UIColor.clear)
            let upperBound = CGFloat(min(105, Int((values.max()! + 10) * 5) / 5))
            graphView.addDataset(values: [upperBound, upperBound], weight: 0, color: UIColor.clear)

            // Add main dataset - score per game
            graphView.addDataset(values: values, weight: 3.0, color: UIColor(Palette.gridLine), gradient: false, pointSize: 12.0, tag: 1, drillRef: drillRef)
            graphView.detailDelegate = self
        }
    }
    
    func graphDetail(drillRef: Any, position: CGPoint) {
        if let uuidString = drillRef as? String {
            if let scorecard = MasterData.shared.scorecard(id: UUID(uuidString: uuidString)) {
                statsDetailView.show(parent: self, scorecard: scorecard, position: position)
            }
        }
    }
}

fileprivate enum Row: Int, CaseIterable {
    case description = 0
    case location = 1
    case partner = 2
    case date = 3
    case score = 4
    case position = 5
    case scoring = 6
    
    var label: String {
        return "\(self)".capitalized
    }
    
    func value(_ scorecard: ScorecardViewModel) -> String {
        switch self {
        case .description:
            return scorecard.desc
        case .location:
            return scorecard.location?.name ?? ""
        case .partner:
            return scorecard.partner?.name ?? ""
        case .date:
            return scorecard.date.toString(format: dateFormat, localized: true)
        case .score:
            return scorecard.score == nil ? "" : "\(scorecard.score!)"
        case .position:
            return "\(scorecard.position) of \(scorecard.entry)"
        case .scoring:
            return scorecard.type.string
        }
    }
}

fileprivate enum Column: Int, CaseIterable {
    case label = 0
    case value = 1
}

class StatsDetailView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var collectionView: UICollectionView!
    private var shadowView = UIView()
    private var scorecard: ScorecardViewModel!
       
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(shadowView, constant: 2, anchored: .all)
        shadowView.backgroundColor = UIColor(Palette.tile.background)
        self.addShadow()
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        shadowView.addSubview(collectionView, leading: 5, trailing: 5, top: 5, bottom: 5)
        StatsDetailCell.register(collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.roundCorners(cornerRadius: 10)
        collectionView.reloadData()
    }
    
    public func show(parent: UIView, scorecard: ScorecardViewModel, position: CGPoint) {
        let x = min(position.x, parent.frame.width - frame.width - 5)
        let y = min(position.y, parent.frame.height - frame.height - 5)
        self.frame = CGRect(origin: CGPoint(x: x, y: y), size: frame.size)
        self.scorecard = scorecard
        parent.addSubview(self)
        collectionView.reloadData()
        self.isHidden = false
    }
    
    public func hide() {
        self.isHidden = true
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Row.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Column.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = indexPath.item == 0 ? 120 : collectionView.frame.width - 120
        return CGSize(width: width, height: collectionView.frame.height / CGFloat(Row.allCases.count))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = StatsDetailCell.dequeue(collectionView, for: indexPath)
        cell.set(scorecard: scorecard, indexPath: indexPath)
        
        return cell
    }
    
}

class StatsDetailCell: UICollectionViewCell {
    static let identifier = "Stats Detail Cell"
    private var label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label, anchored: .all)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func set(scorecard: ScorecardViewModel, indexPath: IndexPath) {
        if let row = Row(rawValue: indexPath.section), let column = Column(rawValue: indexPath.item) {
            switch column {
            case .label:
                label.text = "\(row.label):"
                label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            case.value:
                label.text = row.value(scorecard)
                label.font = UIFont.systemFont(ofSize: 15)
            }
            label.textColor = UIColor(Palette.background.text)
        }
    }
    
    public class func register(_ collectionView: UICollectionView) {
        collectionView.register(StatsDetailCell.self, forCellWithReuseIdentifier: identifier)
    }

    public class func dequeue(_ collectionView: UICollectionView, for indexPath: IndexPath) -> StatsDetailCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! StatsDetailCell
        cell.prepareForReuse()
        return cell
    }
}
