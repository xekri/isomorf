//
//  Sampler.swift
//  isomorf
//
//  Created by sumi on 2023/01/27.
//

import AVFoundation

typealias Channel = UInt8
typealias Note = UInt8
typealias Number = Int

enum Play: Hashable {
    case touch(Int)
    case sustain(Date)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .touch(let touchHash):
            hasher.combine(touchHash)
        case .sustain(let date):
            hasher.combine(date)
        }
    }
}

struct Sampler {
    private var engine = AVAudioEngine()
    private var unitSampler = AVAudioUnitSampler()
    
    private let maxPitchBend: Int = 16384
    private let maxNoteBend: Int = 4
    
    var played: [Note: (Play, Channel, Float)] = [:]
    
    static func toNote(_ number: Number) -> Note {
        return UInt8.init(number - 2)
    }
    
    static func toNumber(_ note: Note) -> Number {
        return Int(note + 2)
    }
    
    init() {
        engine.attach(unitSampler)
        engine.connect(unitSampler, to: engine.mainMixerNode, format: nil)
        
        loadInstrument(0)
        
        do {
            try engine.start()
        } catch {
            fatalError("Sampler falied to start engin")
        }
    }
    
    func pitchBend(_ diff: Float) -> UInt16 {
        let pitchBendF: Float = diff * (Float(maxPitchBend) / Float(maxNoteBend)) + Float(maxPitchBend) / 2
        return UInt16.init(Int(pitchBendF))
    }
    
    mutating func play(_ touchHash: Int, _ note: Note, _ diff: Float) {
        if let (_, channel, diff) = played[note] {
            unitSampler.startNote(note, withVelocity: 127, onChannel: channel)
            played[note] = (.touch(touchHash), channel, diff)
            
        } else if let channel = (0..<128).first(where: { !played.keys.contains($0) }) {
            unitSampler.sendPitchBend(pitchBend(diff), onChannel: channel)
            unitSampler.startNote(note, withVelocity: 127, onChannel: channel)
            played[note] = (.touch(touchHash), channel, diff)
            
        } else {
            print("Sampler failed to play note \(note)")
        }
    }
    
    mutating func unplay(_ touchHash: Int) {
        played.forEach { (note: Note, value) in
            if case let (.touch(th), channel, _) = value {
                if(th == touchHash) {
                    unitSampler.stopNote(note, onChannel: channel)
                    played.removeValue(forKey: note)
                }
            }
        }
    }
    
    mutating func bend(_ note: Note, _ diff: Float) {
        played.forEach { (n: Note, value) in
            let (p, channel, _) = value
            if(n == note) {
                unitSampler.sendPitchBend(pitchBend(diff), onChannel: channel)
                played[n] = (p, channel, diff)
            }
        }
    }
    
    mutating func unbend() {
        played.forEach { (n: Note, value) in
            let (p, channel, _) = value
            unitSampler.sendPitchBend(pitchBend(0), onChannel: channel)
            played[n] = (p, channel, 0)
        }
    }
    
    mutating func sustain(_ touchHash: Int) {
        played.forEach { (note: Note, value) in
            if case let (.touch(_), channel, diff) = value {
                played[note] = (.sustain(Date()), channel, diff)
            }
        }
    }
    
    mutating func unsustain() {
        played.forEach { (note: Note, value) in
            if case let (.sustain(_), channel, _) = value {
                unitSampler.stopNote(note, onChannel: channel)
                played.removeValue(forKey: note)
            }
        }
    }
    
    func loadInstrument(_ instrument: UInt8) {
        if let url = Bundle.main.url(forResource: "SGM-V2.01", withExtension: "sf2"),
           let _ = try? unitSampler.loadSoundBankInstrument(
            at: url, program: instrument,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        {
            print("instrument \(instrument) loaded")
        } else {
            print("Sampler failed to load instrument")
        }
    }
}

let generalMidi = [
    "Acoustic Piano",
    "Bright Piano",
    "Electric Grand Piano",
    "Honky-tonk Piano",
    "Electric Piano",
    "Electric Piano 2",
    "Harpsichord",
    "Clavi",
    "Celesta",
    "Glockenspiel",
    "Music box",
    "Vibraphone",
    "Marimba",
    "Xylophone",
    "Tubular Bell",
    "Dulcimer",
    "Drawbar Organ",
    "Percussive Organ",
    "Rock Organ",
    "Church organ",
    "Reed organ",
    "Accordion",
    "Harmonica",
    "Tango Accordion",
    "Acoustic Guitar ",
    "Acoustic Guitar ",
    "Electric Guitar ",
    "Electric Guitar ",
    "Electric Guitar ",
    "Overdriven Guitar",
    "Distortion Guitar",
    "Guitar harmonics",
    "Acoustic Bass",
    "Electric Bass ",
    "Electric Bass ",
    "Fretless Bass",
    "Slap Bass 1",
    "Slap Bass 2",
    "Synth Bass 1",
    "Synth Bass 2",
    "Violin",
    "Viola",
    "Cello",
    "Double bass",
    "Tremolo Strings",
    "Pizzicato Strings",
    "Orchestral Harp",
    "Timpani",
    "String Ensemble 1",
    "String Ensemble 2",
    "Synth Strings 1",
    "Synth Strings 2",
    "Voice Aahs",
    "Voice Oohs",
    "Synth Voice",
    "Orchestra Hit",
    "Trumpet",
    "Trombone",
    "Tuba",
    "Muted Trumpet",
    "French horn",
    "Brass Section",
    "Synth Brass 1",
    "Synth Brass 2",
    "Soprano Sax",
    "Alto Sax",
    "Tenor Sax",
    "Baritone Sax",
    "Oboe",
    "English Horn",
    "Bassoon",
    "Clarinet",
    "Piccolo",
    "Flute",
    "Recorder",
    "Pan Flute",
    "Blown Bottle",
    "Shakuhachi",
    "Whistle",
    "Ocarina",
    "Lead 1 ",
    "Lead 2 ",
    "Lead 3 ",
    "Lead 4 ",
    "Lead 5 ",
    "Lead 6 ",
    "Lead 7 ",
    "Lead 8 ",
    "Pad 1 ",
    "Pad 2 ",
    "Pad 3 ",
    "Pad 4 ",
    "Pad 5 ",
    "Pad 6 ",
    "Pad 7 ",
    "Pad 8 ",
    "FX 1 ",
    "FX 2 ",
    "FX 3 ",
    "FX 4 ",
    "FX 5 ",
    "FX 6 ",
    "FX 7 ",
    "FX 8 ",
    "Sitar",
    "Banjo",
    "Shamisen",
    "Koto",
    "Kalimba",
    "Bagpipe",
    "Fiddle",
    "Shanai",
    "Tinkle Bell",
    "Agogo",
    "Steel Drums",
    "Woodblock",
    "Taiko Drum",
    "Melodic Tom",
    "Synth Drum",
    "Reverse Cymbal",
    "Guitar Fret Noise",
    "Breath Noise",
    "Seashore",
    "Bird Tweet",
    "Telephone Ring",
    "Helicopter",
    "Applause",
    "Gunshot"
]
