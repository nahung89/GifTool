//
//  VideoComment.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import Unbox

struct VideoComment: Unboxable {
    
    let video: Video
    let comments: [Comment]
    
    init(unboxer u: Unboxer) throws {
        self.video = try u.unbox(key: "greeting")
        self.comments = try u.unbox(key: "comments")
    }
}
