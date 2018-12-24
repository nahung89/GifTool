//
//  SGif.swift
//  GifTool
//
//  Created by Nah on 12/21/17.
//  Copyright © 2017 glue-th. All rights reserved.
//

import Foundation
import Unbox
import UIKit

struct Gifs: Unboxable {
    
    let gifs: [Gif]
    
    init(unboxer u: Unboxer) throws {
        self.gifs = try u.unbox(key: "sgifs")
    }
}


struct Gif {
    
    let id: String
    let category: Int
    let size: CGSize
    let title: String
    
    let gifPath: String
    let previewPath: String
    let filePath: String
}

extension Gif: Unboxable {
    
    init(unboxer u: Unboxer) throws {
        self.id = try u.unbox(key: "id")
        self.title = try u.unbox(key: "title")
        self.category = try u.unbox(key: "category")
        
        do {
            let width: CGFloat = try u.unbox(key: "width")
            let height: CGFloat = try u.unbox(key: "height")
            self.size = CGSize(width: width, height: height)
        } catch {
            self.size = CGSize.zero
        }
        
        self.filePath = try u.unbox(key: "path")
        self.previewPath = try u.unbox(key: "preview_path")
        self.gifPath = try u.unbox(key: "gif_path")
    }
}

/*
{
    "id": 256615668530312,
    "category": 8,
    "creator": {
        "user_id": 583059875159115,
        "full_name": "",
        "profile_photo": {
            "uri": "http://berserker3.vibbidi-vid.com/vibbidi-us/pictures/profile-photos/583059875159115-qfm98a2xszg9jrqzwmq7fqj4ae.jpeg"
        },
        "username": "ICEDBARCELONA10"
    },
    "height": 360,
    "width": 480,
    "title": "I Don't See Nothing Wrong With A Little Birthday Song",
    "gif_path": "http://berserker2.vibbidi-vid.com/vibbidi-us/sgif/256615668530312.gif",
    "preview_path": "http://berserker2.vibbidi-vid.com/vibbidi-us/sgif/256615668530312_preview.mp4",
    "path": "http://berserker2.vibbidi-vid.com/vibbidi-us/sgif/256615668530312.mp4"
}
*/
