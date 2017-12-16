//
//  Comment.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import Unbox

struct Comment {
    
    let id: String
    let videoId: String
    
    let content: String
    let startAt: TimeInterval
    let row: Int
}

extension Comment: Unboxable {
    
    init(unboxer u: Unboxer) throws {
        self.id = try u.unbox(key: "Id")
        self.videoId = try u.unbox(key: "GreetingId")
        
        self.content = try u.unbox(key: "Comment")
        self.startAt = try u.unbox(key: "Sec")
        self.row = try u.unbox(key: "Row")
    }
}
