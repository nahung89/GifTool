//
//  GenerateViewController.swift
//  GifTool
//
//  Created by Nah on 12/14/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import UIKit
import RxAlamofire
import RxSwift
import Unbox
import Kingfisher

class GenerateViewController: UIViewController {
 
    @IBOutlet weak var videoArea: UIView!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    
    private(set) var videoId: String?
    
    private var videoComment: VideoComment?
    private var emojis: [Emoji] = []
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = videoId {
            request(id: id)
        }
    }
    
    func set(video: Video, emojis: [Emoji]) {
        navigationItem.title = video.title
        self.videoId = video.id
        self.emojis = emojis
    }
    
    func reloadData() {
        guard let videoComment = videoComment else { return }
        
        guard !videoComment.comments.isEmpty else {
            displayError("Has no comment...")
            return
        }
        
        // Update video area
        videoHeightConstraint.constant = videoArea.frame.width * videoComment.video.size.height / videoComment.video.size.width
        videoArea.layoutIfNeeded()
        
        // Play comments
        for comment in videoComment.comments {
            let commentParts = CommentPart.parse(comment.content, emojis)
            
            let commentView = CommentItemView(scale: 1.0)
            commentView.setCommentParts(commentParts)
            commentView.frame.origin = CGPoint(x: videoArea.frame.width, y: CGFloat(comment.row) * CommentItemView.Design.height)
            // commentView.makeColor(includeSelf: true) // ERROR
            
            videoArea.addSubview(commentView)
            commentView.animate(speed: videoComment.video.commentSpeed, delay: comment.startAt)
        }
    }
}

extension GenerateViewController {
    
    func request(id: String) {
        let sourceUrl = "http://vtv-tool.vibbidi.com:3030/greeting/get/\(id)"
        log.info("Request: \(sourceUrl)")
        RxAlamofire.requestJSON(.get, sourceUrl)
            .timeout(timeOutTime, scheduler: RxScheduler.shared.apiBackground)
            .map{ (r, json) in
                do {
                    guard let dict = json as? UnboxableDictionary else { throw AppError(code: .unboxFail) }
                    let r: VideoComment = try unbox(dictionary: dict)
                    return r
                } catch {
                    throw AppError(code: .unboxFail)
                }
            }
            .observeOn(RxScheduler.shared.main)
            .subscribe(onNext: { [unowned self] (r: VideoComment) in
                self.videoComment = r
                self.reloadData()
                }, onError: { [unowned self] (error) in
                    self.displayError(error.localizedDescription)
            }).disposed(by: disposeBag)
    }
}
