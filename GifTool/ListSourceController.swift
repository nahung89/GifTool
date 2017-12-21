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

    @IBOutlet weak var emojiStatusLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private let sourceUrl = "http://vtv-tool.vibbidi.com:3030/greeting/getList"
    private let emojisUrl = "https://api4.vibbidi.com/v5.0/emojis"
    
    private var videos: [Video] = []
    private var filterVideos: [Video] = []
    static private(set) var emojis: [Emoji] = []
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        request()
        preloadGifs()
        
        searchBar.rx.text
            .orEmpty
            .throttle(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] (value) in
                if value.isEmpty {
                    self.filterVideos = self.videos
                } else {
                    self.filterVideos = self.videos.filter({ $0.title.contains(value) ||
                        $0.id.contains(value) ||
                        $0.artist.contains(value)
                    })
                }
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        AppDelegate.shared().finishComplileVideo.subscribe(onNext: { (videoId) in
            guard let index = self.videos.index(where: { $0.id == videoId }) else { return }
            self.videos[index].isComplied = true
            if let text = self.searchBar.text, !text.isEmpty {
                self.filterVideos = self.videos.filter({ $0.title.contains(text) ||
                    $0.id.contains(text) ||
                    $0.artist.contains(text)
                })
            } else {
                self.filterVideos = self.videos
            }
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AppDelegate.shared().autoRun {
            autoRun()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == "generate",
            let controller = segue.destination as? GenerateViewController,
            let video = sender as? Video
            else { return }
        controller.set(video: video)
    }
}

extension ListSourceController {
    
    @IBAction func refresh() {
        request()
        preloadGifs()
    }
    
    @IBAction func autoRun() {
        AppDelegate.shared().autoRun = true
        guard let video = self.videos.filter({ $0.isCompleted == true && $0.isComplied != true }).first else { return }
        self.performSegue(withIdentifier: "generate", sender: video)
    }
}

extension ListSourceController {
    
    func request() {
        log.info("Request: \(sourceUrl)")
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
                
                if let text = self.searchBar.text, !text.isEmpty {
                    self.filterVideos = self.videos.filter({ $0.title.contains(text) ||
                        $0.id.contains(text) ||
                        $0.artist.contains(text)
                    })
                } else {
                    self.filterVideos = self.videos
                }
                self.tableView.reloadData()
                self.test()
                }, onError: { [unowned self] (error) in
                    self.displayError(error.localizedDescription)
           }).disposed(by: disposeBag)
    }
    
    func test() {
        guard let video = videos.filter({ $0.id == "645617572865745" }).first else { return }
        self.performSegue(withIdentifier: "generate", sender: video)
    }
    
    func preloadGifs() {
        emojiStatusLabel.text = "Loading Emojis..."
        
        log.info("Request: \(emojisUrl)")
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
                ListSourceController.emojis = emojis
                self.download(emojis: emojis)
                }, onError: { [unowned self] (error) in
                    self.displayError(error.localizedDescription)
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
    }
}

extension ListSourceController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterVideos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? PreviewSourceCell else {
            return UITableViewCell()
        }
        cell.set(data: filterVideos[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = filterVideos[indexPath.row]
        performSegue(withIdentifier: "generate", sender: video)
    }
}




