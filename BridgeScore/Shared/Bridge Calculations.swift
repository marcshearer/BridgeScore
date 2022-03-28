//
//  Bridge Calculations.swift
//  BridgeScore
//
//  Created by Marc Shearer on 22/02/2022.
//

import Foundation

class BridgeImps {
    
    private(set) var imps: Int!
    
    // let tau: Float = 0.5 * (sqrt(5) - 1)
    // let r: Float = Utility.round(powf(tau, 3), places: 6)
    let r: Float = 0.236068
    
    init(_ imps: Int) {
        self.imps = imps
    }
    
    init(points: Int) {
        imps = (pointsToImps.firstIndex(where: {$0 >= abs(points)}) ?? pointsToImps.count) * points.sign
    }
    
    private init(vp: Float, boards: Int, maxVp: Int = 20) {
        self.imps = impFromVp(vp: vp, boards: boards, maxVp: maxVp)
    }
    
    private func impFromVp(vp: Float, boards: Int, maxVp: Int) -> Int {
        let midVp = Float(maxVp) / 2
        let blitz = 15 * sqrt(Float(boards))
        let imps = blitz * (log(1 - ((1 - r) * ((vp / midVp) - 1))) / log(r))
        return Int(imps)
    }
    
    private func pureVp(boards: Int, maxVp: Int = 20, places: Int) -> Float {
        
        let blitz = 15 * sqrt(Float(boards))
        let vp = min(Float(maxVp), (Float(maxVp) / 2) * (1 + ((1 - powf(r, Float(imps) / blitz))/(1 - r))))
        return round(vp, places: places)
    }
    
    public func vp(boards: Int, maxVp: Int = 20, places: Int) -> Float {
     
        // Calculate vps for all imps up to value given and 1 more
        var vp: [Float] = []
        let positive = abs(imps)
        
        for value in 0...positive+1 {
            vp.append(BridgeImps(value).pureVp(boards: boards, maxVp: maxVp, places: places))
        }
        
        // Now check for concavity
        if positive >= 2 {
            var index: Int?
            repeat {
                let adjust = 1 / powf(Float(10), Float(places))
                let tolerance = 1 / powf(Float(10), Float(places + 1))
                let secondDiff = [0, 0] + diff(diff(vp))
                index = secondDiff.firstIndex(where: {$0 >= tolerance})
                if let index = index {
                    vp[index - 1] += adjust
                }
            } while index != nil
        }
        
        return (imps < 0 ? Float(maxVp) - vp[positive] : vp[positive])
    }
    
    public func discreteVp(boards: Int, maxVp: Int = 20) -> Int {
        let midVp = maxVp / 2
        let positive = abs(imps)
        
        var bounds: [Int] = []
        for index in midVp...(maxVp - 1) {
            bounds.append(BridgeImps(vp: Float(index) + 0.5, boards: boards, maxVp: maxVp).imps)
        }
        bounds.insert(-bounds.first!, at: 0)
        var index: Int?
        repeat {
            let tolerance: Float = 0.1
            if (bounds[2] - bounds[1]) < ((2 * bounds[1]) + 1) {
                index = 2
            } else {
                let secondDiff = [0, 0] + diff(diff(bounds.map{Float($0)}))
                index = secondDiff.firstIndex(where: {$0 <= -tolerance})
            }
            if let index = index {
                bounds[index - 1] -= 1
            }
        } while index != nil
        bounds.remove(at: 0)
        return midVp + (bounds.firstIndex(where: {positive <= $0}) ?? midVp) * imps.sign
    }
        
    public func round(_ value: Float, places: Int = 0) -> Float {
        let scale: Float = powf(10, Float(places))
        var large = value * scale
        large.round()
        return large / scale
    }

    private func diff(_ array: [Float]) -> [Float] {
        var result: [Float] = []
        for index in 1...array.count-1 {
            result.append(array[index] - array[index - 1])
        }
        return result
    }
    
    let pointsToImps = [10, 40, 80, 120, 160, 210, 260, 310, 360, 420, 490, 590, 740, 890, 090, 1290, 1490, 1740, 1990, 2240, 2490, 2990, 3490, 3990]
}

class BridgeMatchPoints {
    private(set) var percent: Float
       
    init(_ percent: Float) {
        self.percent = percent
    }
    
    public func vp(boards: Int) -> Int? {
        var vp: Int?
        let positive = (percent > 50 ? percent : 100 - percent)
        if let element = mpsToVps.first(where: {$0.from <= boards && $0.to >= boards}) {
            let increment = element.cutoffs.firstIndex(where: {$0 > positive}) ?? 10
            vp = 10 + increment * (percent < 50 ? -1 : 1)
        }
        return vp
    }
    
    let mpsToVps: [(from: Int, to: Int, cutoffs: [Float])] =
        [(2,  4,  [ 50.92, 52.80, 54.71, 56.70, 58.80, 61.08, 63.63, 66.61, 70.36, 75.95 ]),
         (5,  6,  [ 50.78, 52.39, 54.02, 55.72, 57.51, 59.45, 61.62, 64.17, 67.37, 72.13 ]),
         (7,  9,  [ 50.65, 51.98, 53.33, 54.74, 56.23, 57.83, 59.64, 61.75, 64.40, 68.35 ]),
         (10, 13, [ 50.54, 51.65, 52.78, 53.95, 55.19, 56.53, 58.04, 59.80, 62.01, 65.30 ]),
         (14, 19, [ 50.45, 51.38, 52.32, 53.30, 54.34, 55.45, 56.71, 58.18, 60.03, 62.78 ]),
         (20, 27, [ 50.38, 51.16, 51.94, 52.77, 53.63, 54.57, 55.62, 56.85, 58.40, 60.71 ]),
         (28, 39, [ 50.32, 50.97, 51.63, 52.32, 53.04, 53.83, 54.71, 55.74, 57.04, 58.97 ]),
         (40, 55, [ 50.27, 50.81, 51.37, 51.95, 52.56, 53.21, 53.95, 54.82, 55.91, 57.53 ])]
     
}
