//
//  ViewController.swift
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

class ListSourceController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emojiStatusLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    let sourceUrl = "http://vtv-tool.vibbidi.com:3030/greeting/getList"
    let emojisUrl = "https://api4.vibbidi.com/v5.0/emojis"
    
    var videos: [Video] = []
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        request()
        preloadGifs()
    }
}

extension ListSourceController {
    
    func request() {
        RxAlamofire.requestJSON(.get, sourceUrl)
            .timeout(timeOutTime, scheduler: RxScheduler.shared.apiBackground)
            .map{ (r, json) in
                do {
                    guard let dict = json as? UnboxableDictionary else { throw AppError(code: .unboxFail) }
                    let r: Videos = try unbox(dictionary: dict)
                    return r.videos
                } catch {
                    throw AppError(code: .unboxFail)
                }
            }
            .observeOn(RxScheduler.shared.main)
            .subscribe(onNext: { [unowned self] (r: [Video]) in
                self.videos = r
                self.tableView.reloadData()
                }, onError: { [unowned self] (error) in
                    self.displayError(error)
           }).disposed(by: disposeBag)
    }
    
    func preloadGifs() {
        emojiStatusLabel.text = "Loading Emojis..."
        RxAlamofire.requestJSON(.get, emojisUrl)
            .timeout(timeOutTime, scheduler: RxScheduler.shared.apiBackground)
            .map{ (r, json) in
                do {
                    guard let dict = json as? UnboxableDictionary else { throw AppError(code: .unboxFail) }
                    let u = Unboxer(dictionary: dict)
                    let r: [EmojiCategory] = try u.unbox(key: "categories") as [EmojiCategory]
                    return r
                } catch {
                    throw AppError(code: .unboxFail)
                }
            }
            .observeOn(RxScheduler.shared.main)
            .subscribe(onNext: { [unowned self] (r: [EmojiCategory]) in
                var emojis:[Emoji] = []
                for one in r {
                    emojis += one.emojis
                }
                self.download(emojis: emojis)
                }, onError: { [unowned self] (error) in
                    self.displayError(error)
            }).disposed(by: disposeBag)
    }
    
    func download(emojis: [Emoji]) {
        var urls: [URL] = []
        for emoji in emojis {
            guard let url = URL(string: emoji.path) else {
                log.error("Fail to load url: \(emoji.path)")
                continue
            }
            urls.append(url)
        }
        
        progressView.progress = 0
        
        let imageFetcher = ImagePrefetcher(urls: urls, options: [.downloadPriority(1.0)], progressBlock: { (skipped, failed, completed) in
            DispatchQueue.main.async {
                self.progressView.progress = Float(skipped.count + completed.count) / Float(urls.count)
                self.emojiStatusLabel.text = "Downloading Emojis: \(skipped.count + completed.count)/\(urls.count)"
            }
        }) { (skipped, failed, completed) in
            DispatchQueue.main.async {
                self.progressView.progress = Float(skipped.count + completed.count) / Float(urls.count)
                self.emojiStatusLabel.text = "Emoji downloaded. \(skipped.count + completed.count)/\(urls.count). Failed: \(failed.count)"
            }
        }
            
        imageFetcher.maxConcurrentDownloads = 10
        imageFetcher.start()
    
//        for url in urls {
//            KingfisherManager.shared.retrieveImage(with: url, options: [.downloadPriority(1.0)], progressBlock: nil, completionHandler: { (image, error, cache, url) in
//                if let _ = image, error == nil {
//                    completed += 1
//                    log.info("Complete: \(completed / Float(urls.count) * 100)%")
//                } else {
//                    log.error("Fail to load url: \(url.logable) - \(error.logable)")
//                }
//                DispatchQueue.main.async {
//                    self.progressView.progress = completed / Float(urls.count)
//                    self.navigationItem.title = "Loading Emojis: \(self.progressView.progress * 100)%"
//                }
//            })
//        }
    }
}

extension ListSourceController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? PreviewSourceCell else {
            return UITableViewCell()
        }
        cell.set(data: videos[indexPath.row])
        return cell
    }
}

class PreviewSourceCell: UITableViewCell {
    
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var compiledBtn: UIButton!
    @IBOutlet var completedBtn: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func set(data: Video) {
        contentLabel.text =
        """
        id: \(data.id)
        title: \(data.title) - artist: \(data.artist) - cat: \(data.category)
        start: \(data.start) - end: \(data.end) - speed: \(data.commentSpeed)
        """
        
        compiledBtn.backgroundColor = data.isComplied ? .green : .red
        completedBtn.backgroundColor = data.isComplied ? .green : .red
    }
}



