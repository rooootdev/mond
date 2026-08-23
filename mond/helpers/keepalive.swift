//
//  keepalive.swift
//  JESSI
//
//  Created by ruter on 22.12.25.
//

import AVFoundation
import UIKit

private var _player: AVAudioPlayer?
private var _timer: Timer?

public func keep_alive() {
    guard _player == nil else { return }
    try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
    try? AVAudioSession.sharedInstance().setActive(true)

    let sr = 8000, samples = Int(Double(sr) * 0.5)
    var w = Data("RIFF".utf8)
    w += withUnsafeBytes(of: UInt32(36 + samples * 2).littleEndian) { Data($0) }
    w += Data("WAVEfmt ".utf8)
    w += withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }
    w += withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }
    w += withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }
    w += withUnsafeBytes(of: UInt32(sr).littleEndian) { Data($0) }
    w += withUnsafeBytes(of: UInt32(sr * 2).littleEndian) { Data($0) }
    w += withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }
    w += withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }
    w += Data("data".utf8)
    w += withUnsafeBytes(of: UInt32(samples * 2).littleEndian) { Data($0) }
    w += Data(count: samples * 2)

    _player = try? AVAudioPlayer(data: w)
    _player?.volume = 0
    _player?.numberOfLoops = -1
    _player?.play()

    _timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
        _player?.play()
    }
    
    print("(ka) keep alive started")
}

public func let_die() {
    _timer?.invalidate(); _timer = nil
    _player?.stop(); _player = nil
    print("(ka) keep alive stopped")
}
