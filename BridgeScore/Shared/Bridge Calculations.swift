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
    
    init(vp: Float, boards: Int, maxVp: Int = 20) {
        self.imps = impFromVp(vp: vp, boards: boards, maxVp: maxVp)
    }
    
    private func impFromVp(vp: Float, boards: Int, maxVp: Int) -> Int {
        let midVp = Float(maxVp) / 2
        let blitz = 15 * sqrt(Float(boards))
        let imps = blitz * (log(1 - ((1 - r) * ((vp / midVp) - 1))) / log(r))
        return Int(imps)
    }
    
    public func pureVp(boards: Int, maxVp: Int = 20, places: Int) -> Float {
        
        let blitz = 15 * sqrt(Float(boards))
        let vp = min(Float(maxVp), (Float(maxVp) / 2) * (1 + ((1 - powf(r, Float(imps) / blitz))/(1 - r))))
        return round(vp, places: places)
    }
    
    public func vp(boards: Int, maxVp: Int = 20, places: Int) -> Float {
     
        // Calculate vps for all imps up to value given and 1 more
        var vp: [Float] = []
        for value in 0...imps+1 {
            vp.append(BridgeImps(value).pureVp(boards: boards, maxVp: maxVp, places: places))
        }
        
            // Now check for concavity
        if imps >= 2 {
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
        
        return vp[imps]
    }
    
    public func discreteVp(boards: Int, maxVp: Int = 20) -> Int {
        var bounds: [Int] = []
        let midVp = maxVp / 2
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
                print("DIFF \(index) \(imps!)")
                bounds[index - 1] -= 1
            }
        } while index != nil
        bounds.remove(at: 0)
        for index in 0...midVp {
            print("\(midVp + index) - \(midVp - index)  \(index == 0 ? 0 : bounds[index - 1] + 1) \(index == midVp ? "+" :  "- \(bounds[index])")")
        }
        return midVp + (bounds.firstIndex(where: {imps <= $0}) ?? midVp)
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
}
