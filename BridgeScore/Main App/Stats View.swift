//
//  Stats View.swift
//  BridgeScore
//
//  Created by Marc Shearer on 10/03/2022.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        
    @StateObject var filterValues = ScorecardFilterValues(.stats)
    @State private var hideLeft = false
    
    private let id = statsViewId
    var body: some View {
        StandardView("Stats", slideInId: id) {
            VStack(spacing: 0) {
                Banner(title: Binding.constant("Statistics"), back: true, backAction: backAction, leftTitle: true)
                DoubleColumnView(leftWidth: (hideLeft ? 0 : 350), separator: false) {
                    StatsFilterView(id: id, filterValues: filterValues, hideLeft: $hideLeft)
                } rightView: {
                    ZStack {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 16)
                            StatsGraphWrapperView(filterValues: filterValues)
                            Spacer().frame(height: 24)
                        }
                        .background(Palette.alternate.background)
                        .ignoresSafeArea()
                        if hideLeft {
                            VStack(spacing: 0) {
                                Spacer().frame(height: 16)
                                HStack {
                                    Spacer().frame(width: 16)
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title)
                                        .foregroundColor(Palette.filterUnused.background)
                                        .onTapGesture {
                                            hideLeft = false
                                        }
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .keyboardAdaptive
            }
        }
    }
    
    private func backAction() -> Bool {
        presentationMode.wrappedValue.dismiss()
        return true
    }
}

struct StatsFilterView: View {
    var id: UUID
    @ObservedObject var filterValues: ScorecardFilterValues
    @Binding var hideLeft: Bool
    @State private var refresh = false
    let players = MasterData.shared.players.filter{!$0.retired && !$0.isSelf}
    let locations = MasterData.shared.locations.filter{!$0.retired}
    let types = EventType.validCases
    
    var body: some View {
        
        // To allow manual refresh
        if refresh { EmptyView() }
        
        VStack(spacing: 0) {
            InsetView(color: Palette.tile) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 8)
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.title)
                                .foregroundColor(Palette.filterUnused.background)
                                .onTapGesture {
                                    hideLeft = true
                                }
                        }
                        .frame(height: 8)
                        HStack {
                            Text("FILTER BY:").font(.title3).foregroundColor(Palette.tile.faintText)
                            Spacer()
                        }
                        Spacer().frame(height: 20)
                        
                        MultiSelectPickerInput(id: id, values: {players.map{($0.name, $0.playerId.uuidString)}}, selected: $filterValues.partners, placeholder: "Partner", multiplePlaceholder: "Multiple Partners", selectAll: "No partner filter", height: 40, centered: true, color: (filterValues.partners.firstValue(equal: true) != nil ? Palette.filterUsed : Palette.filterUnused), selectedColor: Palette.filterUsed, font: searchFont, cornerRadius: 20, animation: .none) { (index) in
                                filterValues.objectWillChange.send()
                                filterValues.save()
                        }
                    
                        
                        Spacer().frame(height: 15)
                        
                        MultiSelectPickerInput(id: id, values: {locations.map{($0.name, $0.locationId.uuidString)}}, selected: $filterValues.locations, placeholder: "Location", multiplePlaceholder: "Multiple Locations", selectAll: "No location filter", height: 40, centered: true, color: (filterValues.locations.firstValue(equal: true) != nil ? Palette.filterUsed : Palette.filterUnused), selectedColor: Palette.filterUsed, font: searchFont, cornerRadius: 20, animation: .none) { (index) in
                                filterValues.objectWillChange.send()
                                filterValues.save()
                        }
                        
                        Spacer().frame(height: 15)
                        
                        MultiSelectPickerInput(id: id, values: {types.map{($0.string, $0.rawValue)}}, selected: $filterValues.types, placeholder: "Event type", multiplePlaceholder: "Multiple Types", selectAll: "No type filter", height: 40, centered: true, color: (filterValues.types.firstValue(equal: true) != nil ? Palette.filterUsed : Palette.filterUnused), selectedColor: Palette.filterUsed, font: searchFont, cornerRadius: 20, animation: .none) { (index) in
                                filterValues.objectWillChange.send()
                                filterValues.save()
                        }
                    }
                    
                    VStack(spacing: 0) {
                        
                        Spacer().frame(height: 15)
                        
                        OptionalDatePickerInput(field: $filterValues.dateFrom, placeholder: "Date from", clearText: "Clear date from", to: filterValues.dateTo, color: (filterValues.dateFrom != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, font: searchFont, cornerRadius: 20, height: 40, centered: true) { (dateFrom) in
                                filterValues.save()
                        }
                        
                        Spacer().frame(height: 15)
                        
                        OptionalDatePickerInput(field: $filterValues.dateTo, placeholder: "Date to", clearText: "Clear date to", from: filterValues.dateFrom, color: (filterValues.dateTo != nil ? Palette.filterUsed : Palette.filterUnused), textType: .normal, font: searchFont, cornerRadius: 20, height: 40, centered: true) { (dateTo) in
                                filterValues.save()
                        }
                    }
                    
                    VStack(spacing: 0) {
                        
                        Spacer().frame(height: 40)
                        
                        HStack {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(Palette.input.background)
                                    .cornerRadius(20)
                                HStack {
                                    Spacer().frame(width: 20)
                                    Input(field: $filterValues.searchText, placeHolder: "Search words", height: 40, color: Palette.clear, clearText: (filterValues.searchText != "")) { (searchText) in
                                            filterValues.save()
                                    }
                                    .foregroundColor(Palette.input.text)
                                }
                            }
                            .frame(height: 40)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Text("Clear All Filters")
                                .foregroundColor(Palette.filterUnused.text)
                                .font(searchFont)
                            Spacer()
                        }
                        .onTapGesture {
                            reset()
                        }
                        .frame(height: 40)
                        .background(Palette.filterUnused.background)
                        .cornerRadius(20)
                        
                        Spacer().frame(height: 20)
                    }
                }
                Spacer().frame(width: 16)
            }
            Spacer().frame(height: 8)
        }
        .background(Palette.alternate.background)
        .onAppear {
            filterValues.load()
        }
    }
    
    private func reset() {
        filterValues.clear()
        filterValues.save()
    }
}

struct StatsGraphWrapperView: UIViewRepresentable {
    @ObservedObject var filterValues: ScorecardFilterValues
    @State var values: [CGFloat] = []
    @State var drillRef: [String] = []
    @State var xAxisLabels: [String] = []
    
    func makeUIView(context: Context) -> StatsGraphUIView {
        let view = StatsGraphUIView(filterValues: filterValues)
       
        return view
    }

    func updateUIView(_ uiView: StatsGraphUIView, context: Context) {
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

class StatsGraphUIView: UIView, GraphDetailDelegate {
    private var filterValues: ScorecardFilterValues
    private var graphView = GraphView()
    private var errorLabel = UILabel()
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
        let graphGesture = UITapGestureRecognizer(target: self, action: #selector(StatsGraphUIView.clearDetail(_:)))
        graphView.addGestureRecognizer(graphGesture)
        let detailGesture = UITapGestureRecognizer(target: self, action: #selector(StatsGraphUIView.clearDetail(_:)))
        statsDetailView.addGestureRecognizer(detailGesture)
        addSubview(errorLabel, anchored: .centerX, .centerY)
        Constraint.setWidth(control: errorLabel, width: 500)
        Constraint.setHeight(control: errorLabel, height: 50)
        errorLabel.font = UIFont.systemFont(ofSize: (MyApp.format != .phone ? 40.0 : 20.0))
        errorLabel.backgroundColor = UIColor.clear
        errorLabel.textColor = UIColor(Palette.background.faintText)
        errorLabel.textAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func set(filterValues: ScorecardFilterValues) {
        self.filterValues = filterValues
        statsDetailView.hide()
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
            if scorecard.scorer?.isSelf ?? true {
            if let score = scorecard.score, let maxScore = scorecard.maxScore, maxScore > 0 {
                if filterValues.filter(scorecard) {
                    count += 1
                    let percentage = (score / maxScore) * 100
                    total += percentage
                    values.append(CGFloat(percentage))
                    drillRef.append(scorecard.scorecardId.uuidString)
                    xAxisLabels.append(Utility.dateString(scorecard.date))
                }
                }
            }
        }
        // Moving averages
        var last: [CGFloat] = []
        var lastCount = 0
        if values.count >= 9 {
            lastCount = (Int(values.count / 4) * 2) + 3
            for i in 0...(values.count - lastCount) {
                let slice = values[i..<(i + lastCount - 1)]
                let total = slice.reduce(0, +)
                last.append(total / CGFloat(slice.count))
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
        
        if values.count <= 1 {
            graphView.isHidden = true
            errorLabel.isHidden = false
            errorLabel.text = "Insufficient Data!"
        } else {
            errorLabel.isHidden = true
            graphView.isHidden = false
            
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

            // Add trend line
            if last.count > 3 {
                graphView.addDataset(values: last, weight: 3.0, color: UIColor.red, gradient: false, pointSize: 0, tag: 2, startX: lastCount - 1, curveType: .curve)
            }
            
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
    case comment = 7
    
    static func relevantCases(individual: Bool = true) -> [Row] {
        Row.allCases.filter({$0 != .partner || !individual})
    }
    
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
            return scorecard.score == nil ? "" : "\(scorecard.score!.toString(places: min(1, scorecard.type.matchPlaces)))\(scorecard.type.matchSuffix(maxScore: scorecard.maxScore))"
        case .position:
            return "\(scorecard.position) of \(scorecard.entry)"
        case .scoring:
            return scorecard.type.string
        case .comment:
            return scorecard.comment
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
        return Row.relevantCases(individual: scorecard.type.eventType == .individual).count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Column.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = indexPath.item == 0 ? 120 : collectionView.frame.width - 120
        return CGSize(width: width, height: collectionView.frame.height / CGFloat(Row.relevantCases(individual: scorecard.type.eventType == .individual).count))
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
        let row = Row.relevantCases(individual: scorecard.type.eventType == .individual)[indexPath.section]
        if let column = Column(rawValue: indexPath.item) {
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
