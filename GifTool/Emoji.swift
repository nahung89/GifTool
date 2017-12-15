//
//  EmojiEntity.swift
//  VIBBIDI
//
//  Created by Nah on 9/13/17.
//  Copyright © 2017 glue-th. All rights reserved.
//

import Foundation
import Unbox
import UIKit

struct EmojiCategory: Unboxable {
    
    let id: Int
    let labelPath: String
    let emojis: [Emoji]
    
    init(unboxer u: Unboxer) throws {
        self.id = try u.unbox(key: "id")
        self.labelPath = try u.unbox(key: "label")
        self.emojis = try u.unbox(key: "emojis")
    }
}

struct Emoji: Unboxable {
    
    let key: String
    let size: CGSize
    let path: String
    
    init(unboxer u: Unboxer) throws {
        self.key = try u.unbox(key: "key")
        
        let width: CGFloat = try u.unbox(key: "width")
        let height: CGFloat = try u.unbox(key: "height")
        self.size = CGSize(width: width, height: height)
        
        self.path = try u.unbox(key: "path")
    }
}

enum CommentPart {
    
    case emoji(Emoji)
    case text(String)
    
    static func parse(_ message: String, _ emojis: [Emoji]) -> [CommentPart] {
        guard !emojis.isEmpty else { return [.text(message)] }
        
        let emojiKeys: [String] = emojis.map({ $0.key })
        
        let pattern: String = emojiKeys.map({ ":\($0):" }).joined(separator: "|")
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let s = message as NSString
        let matches = regex.matches(in: message.lowercased(), options: [], range: NSMakeRange(0, s.length))
        
        var commentParts: [CommentPart] = []
        
        // No emoji
        if matches.isEmpty {
            commentParts.append(.text(message))
            return commentParts
        }
        
        // Some first text is not emoji
        if let match = matches.first, match.range.location > 0 {
            let pure = s.substring(to: match.range.location)
            commentParts.append(.text(pure))
        }
        
        // Split emoji and pure text
        for (idx, match) in matches.enumerated() {
            let r = match.range
            let p = s.substring(with: r)
            let key = String(p[p.index(after: p.startIndex)..<p.index(before: p.endIndex)]).lowercased()
            
            if let emo = emojis.filter({ $0.key == key }).first {
                commentParts.append(.emoji(emo))
            } else {
                commentParts.append(.text(p))
            }
            // print("emoji:", key)
            
            if idx + 1 < matches.count {
                let nextMatch = matches[idx + 1]
                let pureRange = NSMakeRange(r.location + r.length, nextMatch.range.location - (match.range.length + match.range.location))
                let pure = s.substring(with: pureRange)
                commentParts.append(.text(pure))
                // print("pure-1:", pure)
            }
            else {
                let pureRange = NSMakeRange(r.location + r.length, s.length - r.length  - r.location)
                let pure = s.substring(with: pureRange)
                commentParts.append(.text(pure))
                // print("pure-2:", pure)
            }
        }
        
        return commentParts
    }
}

