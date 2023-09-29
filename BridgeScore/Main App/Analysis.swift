//
//  Analysis.swift
//  BridgeScore
//
//  Created by Marc Shearer on 26/09/2023.
//

import Foundation

class Analysis : ObservableObject {
    @Published private(set) var tricksMade: [AnalysisTrickCombination:(modeFraction: Float, made: [AnalysisAssessmentMethod:Int])] = [:]
    private(set) var options: [AnalysisOption] = []
    private(set) var rankingNumber: Int
    private(set) var sitting: Seat
    private(set) var board: BoardViewModel
    private(set) var traveller: TravellerViewModel
    private var boardTravellers: [TravellerViewModel]
    private var scoreType: Type
    private var boardScoreType: ScoreType
    
    init(board: BoardViewModel, traveller: TravellerViewModel, sitting: Seat) {
        self.rankingNumber = traveller.rankingNumber[sitting] ?? -1
        self.sitting = sitting
        self.board = board
        self.traveller = traveller
        self.boardTravellers = Scorecard.current.travellers(board: board.board).sorted(by: {$0.points(sitting: sitting) < $1.points(sitting: sitting)})
        self.scoreType = Scorecard.current.scorecard!.type
        self.boardScoreType = scoreType.boardScoreType
        buildOptions()
    }
    
    public func madeValues(combinations: [AnalysisTrickCombination]) -> [AnalysisTrickCombination:(method: AnalysisAssessmentMethod, default: Int, override: Int?)] {
        var result: [AnalysisTrickCombination:(method: AnalysisAssessmentMethod, default: Int, override: Int?)] = [:]
        for combination in combinations {
            if let method = useMethod(suit: combination.suit, declarer: combination.declarer), let made = made(board: board.board, suit: combination.suit, declarer: combination.declarer, method: method) {
                result[combination] = (method, default: made, override: nil)
            }
        }
        return result
    }
    
    public func made(board: Int, suit: Suit, declarer: Pair, method: AnalysisAssessmentMethod) -> Int? {
        return tricksMade[AnalysisTrickCombination(board: board, suit: suit, declarer: declarer)]?.made[method]
    }
    
    public func setOverride(board: Int, suit: Suit, declarer: Pair, override: Int) {
        tricksMade[AnalysisTrickCombination(board: board, suit: suit, declarer: declarer)]?.made[.override] = override
        if let (_, made) = tricksMade[AnalysisTrickCombination(board: board, suit: Suit(string: "C"), declarer: .ew)] {
            print(made[AnalysisAssessmentMethod.override])
        }
    }
    
    public func useMethod(suit: Suit, declarer: Pair) -> AnalysisAssessmentMethod? {
        var result: AnalysisAssessmentMethod?
        if traveller.contract.suit == suit {
            result = .play
        }
        let combination = AnalysisTrickCombination(board: board.board, suit: suit, declarer: declarer)
        if let (modeFraction, made) = tricksMade[combination] {
            if made[.override] != nil {
                result = .override
            } else if result == nil && modeFraction >= 0.25 {
                result = .mode
            }
            if result == nil {
                result = (made[.median] != nil ? .median : .doubleDummy)
            }
        }
        return result
    }
    
    private func buildOptions() {
        options = []
        
        let bids = traveller.bids
        let declarer = traveller.declarer.pair
        let weDeclared = (declarer == sitting.pair)
        
        // Find last bid by defenders
        var bidder = declarer
        var previousBid: Contract?
        var started = false
        for bid in bids.reversed() {
            if bid != nil || started {
                started = true
                if bidder != declarer && bid != nil {
                    previousBid = bid
                    break
                }
                bidder = bidder.other
            }
        }
        
        let ourBid = (weDeclared ? traveller.contract : previousBid)
        let theirBid = (weDeclared ? previousBid : traveller.contract)
               
        let types = (weDeclared ? AnalysisOptionType.declaringCases : AnalysisOptionType.defendingCases)
        for type in types {
            if type.formatMatch {
                var typeOptions: [AnalysisOption] = []
                
                    // Generic options
                switch type {
                case .actual:
                    typeOptions.append(AnalysisOption(parent: self, type: type, board: board.board, contract: Contract(copying: traveller.contract), declarer: traveller.declarer.pair))
                case .otherTable:
                    if let otherTableTraveller = boardTravellers.filter({$0.rankingNumber[sitting.leftOpponent] == traveller.rankingNumber[sitting]}).first {
                        let contract = Contract(copying: otherTableTraveller.contract)
                        if otherTableTraveller.declarer.pair == sitting.pair && (theirBid == nil || contract >+ theirBid!) {
                            typeOptions.append(AnalysisOption(parent: self, type: type, board: board.board, contract: contract, declarer: otherTableTraveller.declarer.pair))
                        }
                    }
                default:
                    break
                }
            
                if weDeclared {
                    // Options if we declared
                    switch type {
                    case .stopLower:
                        // Stop in a lower contract below game
                        if let ourBid = ourBid {
                            if ourBid.level.rawValue > 1 {
                                for level in 1..<ourBid.level.rawValue {
                                    let tryBid = Contract(copying: ourBid)
                                    tryBid.level = ContractLevel(rawValue: level)!
                                    if theirBid == nil || tryBid >+ theirBid! {
                                        typeOptions.append(AnalysisOption(parent: self, type: type, board: board.board, contract: tryBid, declarer: sitting.pair))
                                    }
                                }
                            }
                        }
                    default:
                        break
                    }
                }
            
                // Options if bidding or declaring
                switch type {
                case .passPrevious:
                        // Pass their last bid
                    if let theirBid = theirBid {
                        if weDeclared || theirBid.double == .doubled {
                            let contract = Contract(copying: theirBid)
                            contract.double = .undoubled
                            typeOptions.append(AnalysisOption(parent: self, type: type, board: board.board, contract: contract, declarer: sitting.pair.other, decisionBy: sitting.pair))
                        }
                    }
                case .upToGame:
                        // Bid on to part-score game or slam level
                    if let ourBid = ourBid {
                        typeOptions.append(contentsOf: bidOverOptions(ourBid: Contract(higher: ourBid, suit: ourBid.suit), above: theirBid))
                    }
                case .otherSuit:
                    // Bid another suit (bid by someone else or double-dummy optimum)
                    let suitsBidSet = Set(boardTravellers.filter{$0.declarer.pair == sitting.pair}.map{$0.contract.suit}.filter{$0 != ourBid?.suit})
                    var suitsBid: [Suit] = Array(suitsBidSet)
                    if let optimum = board.optimumScore?.contract, let declarer = board.optimumScore?.declarer {
                        let suit = board.optimumScore!.contract.suit
                        if !suitsBid.contains(suit) && suit != ourBid?.suit && declarer == sitting.pair && (theirBid == nil || optimum >+ theirBid!) {
                            suitsBid.append(suit)
                        }
                    }
                    if !suitsBid.isEmpty {
                        for suit in suitsBid {
                            if let aboveBid = theirBid ?? ourBid {
                                if let bid = Contract(higher: aboveBid, suit: suit) {
                                    typeOptions.append(contentsOf: bidOverOptions(ourBid: bid, above: nil, forceType: .otherSuit))
                                }
                            }
                        }
                    }
                default:
                    break
                }

                if !typeOptions.isEmpty {
                    // Add linked options
                    for option in typeOptions {
                        options.append(option)
                        
                        if !weDeclared {
                            if option.type == .actual && option.contract.double != .undoubled {
                                // We have doubled them - consider not doubling
                                let dontDouble = Contract(copying: option.contract)
                                dontDouble.double = .undoubled
                                options.append(AnalysisOption(parent: self, type: .dontDouble, board: board.board, contract: dontDouble, declarer: option.declarer, decisionBy: option.declarer.other, linked: option))
                            } else if option.declarer == sitting.pair {
                                // We have over bid
                                // Add linked options for opps doubling or overbidding
                                // and us then doubling them or them doubling us
                                let doubleUs = Contract(copying: option.contract)
                                doubleUs.double = .doubled
                                options.append(AnalysisOption(parent: self, type: .double, board: board.board, contract: doubleUs, declarer: option.declarer, decisionBy: option.declarer.other, linked: option, double: true))
                                
                                if let bidOver = Contract(higher: option.contract, suit: theirBid!.suit) {
                                    let bidOverOption = AnalysisOption(parent: self, type: .bidOver, board: board.board, contract: bidOver, declarer: option.declarer.other, decisionBy: option.declarer.other, linked: option)
                                    options.append(bidOverOption)
                                    
                                    let doubleThem = Contract(copying: bidOver)
                                    doubleThem.double = .doubled
                                    options.append(AnalysisOption(parent: self, type: .bidOverDouble, board: board.board, contract: doubleThem, declarer: option.declarer.other, decisionBy: option.declarer, linked: bidOverOption, double: true))
                                }
                            }
                        } else if option.type == .passPrevious || (!weDeclared && option.type == .actual) {
                            // If we passed them consider doubling them
                            let doubleThem = Contract(copying: option.contract)
                            doubleThem.double = .doubled
                            options.append(AnalysisOption(parent: self, type: .passPrevious, board: board.board, contract: doubleThem, declarer: option.declarer, decisionBy: option.declarer.other, linked: option, double: true))
                        }
                    }
                }
            }
        }
                
        buildScores()
        removeBadOptions()
        
    }
    
    public func refreshOptions() {
        for option in options {
            option.removed(by: nil)
        }
        buildScores()
        removeBadOptions()
    }
    
    private func bidOverOptions(ourBid: Contract?, above: Contract?, forceType: AnalysisOptionType? = nil) -> [AnalysisOption] {
        var options: [AnalysisOption] = []
        if let ourBid = ourBid, let ourGameLevel = ContractLevel(rawValue: ourBid.suit.gameTricks) {
            if ourBid.level < .grandSlam {
                var startLevel = ourBid.level
                if let above = above {
                    if above >+ ourBid {
                            // Need to outbid opposition
                        if let overBid = Contract(higher: above, suit: ourBid.suit) {
                            if overBid.level < ourGameLevel {
                                startLevel = overBid.level
                            }
                        }
                    }
                }
                for rawLevel in startLevel.rawValue...ContractLevel.grandSlam.rawValue {
                    let contract = Contract(copying: ourBid)
                    let level = ContractLevel(rawValue: rawLevel)!
                    contract.level = level
                    var type: AnalysisOptionType
                    if above == nil || contract >+ above! {
                        if forceType != nil {
                            type = forceType!
                        } else if level < ourGameLevel {
                            type = .bidOver
                        } else if level == ourGameLevel {
                            type = .upToGame
                        } else if level == .smallSlam {
                            type = .upToSlam
                        } else {
                            type = .upToGrand
                        }
                        options.append(AnalysisOption(parent: self, type: type, board: board.board, contract: contract, declarer: sitting.pair))
                    }
                }
            }
        }
        return options
    }
    
    private func buildScores(){
        tricksMade  = buildTricksMade()
        for option in options {
            var assessment: [Int:AnalysisAssessment] = [:]
            let combination = AnalysisTrickCombination(board: board.board, suit: option.contract.suit, declarer: option.declarer)
            if let allTricksMade = tricksMade[combination]?.made.map({$0.value}) {
                let tricksMadeSet = Set(allTricksMade)
                for made in tricksMadeSet {
                    let points = Scorecard.points(contract: option.contract, vulnerability: Vulnerability(board: traveller.boardNumber), declarer: option.declarer.seats.first!, made: made - Values.trickOffset - option.contract.level.rawValue, seat: sitting)
                    assessment[made] = (AnalysisAssessment(tricks: made, points: points, score: 0))
                }
                for method in AnalysisAssessmentMethod.allCases {
                    if let methodTricks = tricksMade[combination]?.made[method] {
                        option.assessments[method] = assessment[methodTricks]
                        option.modeFraction = tricksMade[combination]?.modeFraction ?? 0
                    }
                }
                option.calculateScores(traveller: traveller, sitting: sitting)
            }
        }
    }
    
    private func removeBadOptions () {
        if options.count >= 2 {
            // Remove any option which is always equal or worse to something above it (for decision maker)
            for optionIndex in 1..<options.count {
                let option = options[optionIndex]
                for compareIndex in 0..<optionIndex {
                    let compare = options[compareIndex]
                    if !compare.removed {
                        // First consider removing the option if it is worse
                        if AnalysisOption.equalOrWorsePoints(option, compare, invert: invert(option), specificMethod: (compare.type == .actual && option.contract.suit == compare.contract.suit && option.declarer == compare.declarer ? .play : nil)) {
                            option.removed(by: compare, reason: "Earlier better")
                        } else if option.contract.suit == compare.contract.suit && option.contract.double == .undoubled && compare.contract.double == .undoubled && option.declarer == compare.declarer && option.type == compare.type {
                            // Different levels for the same thing - allow earlier (lower) option to be removed as well
                            if AnalysisOption.equalOrWorsePoints(compare, option, invert: invert(compare), specificMethod: (compare.type == .actual && option.contract.suit == compare.contract.suit && option.declarer == compare.declarer ? .play : nil)) {
                                compare.removed(by: option, reason: "Later better")
                                break
                            }
                        }
                    }
                }
            }
            
            // Remove linking options if no longer in play
            for option in options {
                if let linked = option.linked {
                    if linked.removed {
                        option.removed(by: linked, reason: "Linked gone")
                    }
                }
            }
            
            // Now consider removing original linked bid if worse than double
            for option in options {
                if option.double && !option.removed {
                    if let linked = option.linked {
                        if !linked.removed && linked.type.allowRemove {
                            if AnalysisOption.equalOrWorsePoints(linked, option, invert: invert(option)) {
                                linked.removed(by: option, reason: "Worse than linker")
                            }
                        }
                    }
                }
            }
            
            // Now consider removing doubled bid if original bid does not make sense if doubled
            for optionIndex in 1..<options.count {
                let option = options[optionIndex]
                if option.double && !option.removed {
                    if let linked = option.linked {
                        if linked.removed {
                            for compareIndex in 0..<optionIndex {
                                let compare = options[compareIndex]
                                if !compare.removed {
                                    if AnalysisOption.equalOrWorsePoints(option, compare, invert: invert(linked), specificMethod: (compare.type == .actual && option.contract.suit == compare.contract.suit && option.declarer == compare.declarer ? .play : nil)) {
                                        option.removed(by: compare, reason: "Original bad dbled")
                                        // And remove any options also linked to this original bad option
                                        for linking in options {
                                            if linking.linked == linked {
                                                linking.removed(by: option, reason: "Linked to bad bid")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func invert(_ option: AnalysisOption) -> Bool {
            var invert = option.declarer != sitting.pair
            if option.decisionBy != option.declarer {
                invert.toggle()
            }
            return invert
        }
    }
    
    private func buildTricksMade() -> [AnalysisTrickCombination:(Float, [AnalysisAssessmentMethod:Int])] {
        var assessment: [AnalysisTrickCombination:(modeFraction: Float, made: [AnalysisAssessmentMethod:Int])] = [:]
        for pair in Pair.validCases {
            for suit in Suit.validCases {
                let combination = AnalysisTrickCombination(board: board.board, suit: suit, declarer: pair)
                assessment[combination] = (0,[:])
                let suitTravellers = Scorecard.current.travellers(board: board.board).filter({ $0.contract.suit == suit && $0.declarer.pair == pair}) .sorted(by: { ((($0.contractLevel + $0.made) - ($1.contractLevel + $1.made)) * ($0.declarer.pair == pair ? 1 : -1)) < 0 })
                    // Play
                if suit == traveller.contract.suit {
                    assessment[combination]!.made[.play] = Values.trickOffset + traveller.contractLevel + traveller.made
                }
                
                    // Double dummy
                var made: [Int] = []
                for index in 0...1 {
                    made.append(board.doubleDummy[pair.seats[index]]?[suit]?.made ?? -1)
                }
                if made.max() ?? -1 >= 0 {
                    assessment[combination]!.made[.doubleDummy] = made.max()
                }
                
                    // Median
                if suitTravellers.count > 0 {
                    let medianTraveller = suitTravellers[(suitTravellers.count) / 2]
                    assessment[combination]!.made[.median] = Values.trickOffset + medianTraveller.contractLevel + medianTraveller.made
                }
                
                    //Mode
                let counts = NSCountedSet(array: suitTravellers.map{Values.trickOffset + $0.contractLevel + $0.made})
                if counts.count > 0 {
                    if let maxCount = counts.max(by: { counts.count(for: $0) < counts.count(for: $1)}), let mostFrequent = maxCount as? Int {
                        assessment[combination]!.made[.mode] = mostFrequent
                        assessment[combination]!.modeFraction = Float(counts.count(for: mostFrequent)) / Float(suitTravellers.count)
                    }
                }
                    // Best
                if let bestTraveller = suitTravellers.last {
                    assessment[combination]!.made[.best] = Values.trickOffset + bestTraveller.contractLevel + bestTraveller.made
                }
            }
        }
        return assessment
    }
}

struct AnalysisTrickCombination: Hashable {
    var board: Int
    var suit: Suit
    var declarer: Pair
}
enum AnalysisActionType: Int, CaseIterable {
    case noAction
    case otherTable
    case bidLower
    case bidToMake
    case sacrifice
    case upToGame
    case upToSlam
    case upToGrandSlam
    case passPrevious
    case doublePrevious
    case doubleThem
    case doubleOvercall
    case dontDouble
    case otherSuit
    
    var description: String {
        return switch self {
        case .noAction:
            "Stick with actual bidding"
        case .otherTable:
            "Bid as on the other table"
        case .bidLower:
            "Stop bidding at a lower level"
        case .bidToMake:
            "Overcall to make"
        case .sacrifice:
            "Overcall as a sacrifice"
        case .upToGame:
            "Bid on to game"
        case .upToSlam:
            "Bid on to slam"
        case .upToGrandSlam:
            "Bid on to grand slam"
        case .passPrevious:
            "Pass last bid by opponents"
        case .doublePrevious:
            "Double last bid by opponents"
        case .doubleThem:
            "Double last bid by opponents"
        case .doubleOvercall:
            "Overcall and then double"
        case .dontDouble:
            "Don't double opponents"
        case .otherSuit:
            "Bid another suit"
        }
    }
}

enum AnalysisOptionType : Int, CaseIterable, Hashable {
    case actual
    case otherTable
    case dontDouble
    case passPrevious
    case double
    case stopLower
    case otherSuit
    case bidOver
    case bidOverDouble
    case upToGame
    case upToSlam
    case upToGrand
    
    var string: String {
        return "\(self)".replacingOccurrences(of: "Double", with: "*").splitCapitals
    }
    
    var upToTypes: [AnalysisOptionType] {
        return [.upToGame, .upToSlam, .upToGrand]
    }
    
    var notMakingType: AnalysisOptionType {
        return (upToTypes.contains(self) ? .bidOver : self)
    }
    
    static func doubleString(_ type: AnalysisOptionType?) -> String? {
        return (type == nil ? nil : (type == .passPrevious ? "Last bid*" : "\(type!.string)*"))
    }
    
    static var declaringCases: [AnalysisOptionType] = [.actual, .otherTable, .passPrevious, .stopLower, .upToGame, .otherSuit]
    
    static var defendingCases: [AnalysisOptionType] = [.actual, .otherTable, .passPrevious, .bidOver, .upToGame]
    
    var formatMatch: Bool {
        switch Scorecard.current.scorecard?.type.players ?? 0 {
        case 1, 2:
            return self != .otherTable
        default:
            return true
        }
    }
    
    var allowRemove: Bool {
        return self != .actual
    }
    
}

enum AnalysisAssessmentMethod : Int, CaseIterable, Hashable {
    case play
    case median
    case mode
    case best
    case doubleDummy
    case override
    
    var string: String {
        return "\(self)".splitCapitals
    }
    
    static var realCases: [AnalysisAssessmentMethod] {
        AnalysisAssessmentMethod.allCases.filter({$0 != .override})
    }
    
    var short: String {
        switch self {
        case .doubleDummy:
            return "DD"
        case .median:
            return "Med"
        default:
            return "\(self)".capitalized
        }
    }
}

class AnalysisAssessment : Hashable {
    var tricks: Int
    var points: Int
    var score: Float?
    
    init(tricks: Int, points: Int, score: Float?) {
        self.tricks = tricks
        self.points = points
        self.score = score
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tricks)
        hasher.combine(points)
        hasher.combine(score)
    }
    
    static func == (lhs: AnalysisAssessment, rhs: AnalysisAssessment) -> Bool {
        return (lhs.tricks == rhs.tricks && lhs.points == rhs.points && lhs.score == rhs.score)
    }
}

enum AnalysisOptionFormat: Int, CaseIterable, Identifiable {
    case tricks
    case made
    case points
    case score
    
    public var id: Self { self }
    
    var string: String { "\(self)".capitalized }
}

class AnalysisOption : Identifiable, Equatable, Hashable {
    private(set) var id: UUID = UUID()
    public var type: AnalysisOptionType
    public var board: Int
    public var contract: Contract
    public var declarer: Pair
    public var decisionBy: Pair
    public var assessments: [AnalysisAssessmentMethod:AnalysisAssessment] = [:]
    public var linked: AnalysisOption?
    public var removedBy: AnalysisOption?
    public var double: Bool
    public var modeFraction: Float = 0
    weak private var parent: Analysis!
    
    init(parent: Analysis, type: AnalysisOptionType, board: Int, contract: Contract, declarer: Pair, decisionBy: Pair? = nil, linked: AnalysisOption? = nil, double: Bool = false) {
        self.parent = parent
        self.type = type
        self.board = board
        self.contract = contract
        self.declarer = declarer
        self.decisionBy = decisionBy ?? declarer
        self.linked = linked
        self.double = double
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(board)
        hasher.combine(contract)
        hasher.combine(declarer)
        hasher.combine(assessments)
        hasher.combine(removedBy)
    }
    
    public var action: AnalysisActionType {
        var result: AnalysisActionType = .noAction
        var madeContract: Bool?
        if let tricksMade = useAssessment?.tricks {
            madeContract = (tricksMade >= Values.trickOffset + contract.level.rawValue)
        }
        result = switch self.type {
        case .actual:
            .noAction
        case .otherTable:
            .otherTable
        case .passPrevious:
            (double ? .doublePrevious : .passPrevious)
        case .double:
            ((madeContract ?? false) ? .bidToMake : .sacrifice)
        case .dontDouble:
            .dontDouble
        case .stopLower:
            .bidLower
        case .otherSuit:
            .otherSuit
        case .bidOver:
            (madeContract ?? false) ? .bidToMake : .sacrifice
        case .bidOverDouble:
            .doubleOvercall
        case .upToGame:
            .upToGame
        case .upToSlam:
            .upToSlam
        case .upToGrand:
            .upToGrandSlam
        }
        return result
    }
    
    public var useMethod: AnalysisAssessmentMethod? {
        return parent.useMethod(suit: contract.suit, declarer: declarer)
    }
    
    public var useAssessment: AnalysisAssessment? {
        if let useMethod = useMethod {
            return assessments[useMethod]
        } else {
            return nil
        }
    }
    
    public var reliability: Int {
        if let useMethod = parent.useMethod(suit: contract.suit, declarer: declarer) {
            switch useMethod {
            case .override:
                return 9
            case .play, .mode, .median:
                return 6
            case .doubleDummy:
                return 3
            case .best:
                return 1
            }
        } else {
            return 0
        }
    }
    
    public var removed: Bool { removedBy != nil }
    
    public static func == (lhs: AnalysisOption, rhs: AnalysisOption) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var displayType : AnalysisOptionType {
        var allNotMaking = true
        for (_, assess) in assessments {
            if assess.tricks >= Values.trickOffset + contract.level.rawValue {
                allNotMaking = false
            }
        }
        return allNotMaking ? type.notMakingType : type
    }
    
    public func removed(by: AnalysisOption?, reason: String? = nil) {
        if self.type.allowRemove && removedBy == nil {
            self.removedBy = by
            if let by = by {
                print("\((reason ?? "Unknown").padding(toLength: 30, withPad: " ", startingAt: 0)) - \(type.string) \(contract.compact) removed by \(by.type.string) \(by.contract.compact)")
            }
        }
    }
    
    public func calculateScores(traveller: TravellerViewModel, sitting: Seat) {
        let travellers = Scorecard.current.travellers(board: traveller.board)
        let otherTravellers = travellers.filter({!($0 == traveller)})
        let pointsList = Set(assessments.map{$0.value.points})
        for points in pointsList {
            var score: Float? = nil
            switch Scorecard.current.scorecard!.type.boardScoreType {
            case .percent:
                // 2 points for every pair beaten, 1 for every pair tied divided by 2 points for every pair
                var mps = 0
                for compareTraveller in otherTravellers {
                    let compare = compareTraveller.points(sitting: sitting)
                    if points > compare {
                        mps += 2
                    } else if points == compare {
                        mps += 1
                    }
                }
                score = Float(mps * 100) / Float((otherTravellers.count * 2))
            case .aggregate:
                score = Float(points)
            case .xImp:
                // Compare our score with every othre traveller and average
                score = otherTravellers.map({Float(BridgeImps(points: points - $0.points(sitting: sitting)).imps)}).reduce(0,+) / Float(otherTravellers.count)
            case .imp:
                let compare = otherTravellers.map{$0.points(sitting: sitting)}.reduce(0, +) / otherTravellers.count
                let imps = BridgeImps(points: points - compare)
                score = Float(imps.imps)
            case .vp, .acblVp:
                break
            case .unknown:
                break
            }
            for (_, assessment) in assessments.filter({$0.value.points == points}) {
                assessment.score = score
            }
        }
    }
    
    public func value(method: AnalysisAssessmentMethod, format: AnalysisOptionFormat, compare: AnalysisAssessment? = nil, verbose: Bool = false, showVariance: Bool = false, colorCode: Bool = true) -> AttributedString {
        var result = ""
        var variance: Float = 0.0
        var places = 0
        var suffix = ""
        if let assessment = assessments[method] {
            let compare = compare ?? assessments[method]!
            switch format{
            case .tricks:
                variance = Float(assessment.tricks - compare.tricks)
                result = "\(assessment.tricks)" + (verbose ? " tricks" : "")
            case .made:
                variance = Float(assessment.tricks - compare.tricks)
                result = "\(Scorecard.madeString(made: assessment.tricks - Values.trickOffset - contract.level.rawValue))"
            case .points:
                variance = Float(assessment.points - compare.points)
                result = String(format: "%+2d", assessment.points)
            case .score:
                if let score = assessment.score {
                    if let compareScore = compare.score {
                        variance = score - compareScore
                    }
                    let type = Scorecard.current.scorecard!.type
                    places = verbose && !showVariance ? type.boardPlaces : 0
                    result = type.boardScoreType.prefix(score: score) + score.toString(places: places)
                    suffix = type.boardScoreType.suffix
                    if suffix.count == 1 || verbose {
                        // Only short suffices!
                        result += suffix
                    }
                } else {
                    result = "N/A"
                }
            }
            if showVariance {
                if variance == 0 {
                    result = ""
                } else {
                    result = (variance > 0 ? "+" : "") + variance.toString(places: places) + suffix
                }
            }
        }
        return AttributedString(result, color: (!colorCode || variance > 0 ? Palette.background.text : ( variance < 0 ? Palette.background.strongText : Palette.background.faintText)))
    }
    
    public static func equalOrWorsePoints(_ lhs: AnalysisOption, _ rhs: AnalysisOption, invert: Bool = false, specificMethod: AnalysisAssessmentMethod? = nil) -> Bool{
        var result = true
        for (method, lhsValue) in lhs.assessments {
            if specificMethod == nil || method == specificMethod {
                if let rhsValue = rhs.assessments[method] {
                    if (lhsValue.points - rhsValue.points) * (invert ? -1 : 1) > 0 {
                        result = false
                        break
                    }
                }
            }
        }
        return result
    }
}
