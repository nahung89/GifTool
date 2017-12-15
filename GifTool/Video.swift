//
//  Video.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import Unbox
import UIKit

struct Videos: Unboxable {
    
    let videos: [Video]
    
    init(unboxer u: Unboxer) throws {
        self.videos = try u.unbox(key: "greetings")
    }
}

struct Video {
    
    let id: String
    let title: String
    
    let videoId: String
    let videoTitle: String
    let youtubeId: String
    
    let artist: String
    let category: Int
    let videoPath: String
    let size: CGSize
    let duration: TimeInterval
    
    let isComplied: Bool?
    let isCompleted: Bool
    
    let commentSpeed: TimeInterval
    let start: TimeInterval
    let end: TimeInterval
}

extension Video: Unboxable {
    
    init(unboxer u: Unboxer) throws {
        self.id = try u.unbox(key: "Id")
        self.title = try u.unbox(key: "Title")
        
        self.videoId = try u.unbox(key: "VideoId")
        self.videoTitle = try u.unbox(key: "VideoTitle")
        self.videoPath = try u.unbox(key: "Path")
        
        self.youtubeId = try u.unbox(key: "YoutubeId")
        self.artist = try u.unbox(key: "Artist")
        self.category = try u.unbox(key: "Category")
        
        self.isComplied = u.unbox(key: "isCompiled")
        self.isCompleted = try u.unbox(key: "isCompleted")
        
        self.commentSpeed = try u.unbox(key: "CommentSpeed")
        self.start = try u.unbox(key: "StartSec")
        self.end = try u.unbox(key: "EndSec")
        
        do {
            let width: CGFloat = try u.unbox(key: "Width")
            let height: CGFloat = try u.unbox(key: "Height")
            let duration: Double = try u.unbox(key: "Duration")
            self.size = CGSize(width: width, height: height)
            self.duration = duration
        } catch {
            self.size = CGSize.zero
            self.duration = 0
        }
    }
}
