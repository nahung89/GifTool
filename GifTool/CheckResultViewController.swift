//
//  CheckResultViewController.swift
//  GifTool
//
//  Created by Nah on 12/21/17.
//  Copyright © 2017 glue-th. All rights reserved.
//

import Foundation
import UIKit
import RxAlamofire
import RxSwift
import Unbox
import Alamofire

class CheckResultViewController: UIViewController {
    
    @IBOutlet weak var exportLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var queue: [String] = []
    private var gifs: [Gif] = []
    
    private var request: Disposable?
    
    private var downloadRequest: Alamofire.DownloadRequest?
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getGifs()
    }
    
    
    func downloadFiles() {
        guard !queue.isEmpty else { return }
        
        let path = queue.removeFirst()
        
        guard let loadUrl = URL(string: path) else {
            exportLabel.text = "Error. Invalid Url: \(path)"
            downloadFiles()
            return
        }
        
        guard let saveUrl = createCheckDirectory()?.appendingPathComponent(loadUrl.lastPathComponent) else {
            exportLabel.text = "Error. Can't find cache directory"
            downloadFiles()
            return
        }
        
        if FileManager.default.fileExists(atPath: saveUrl.path) {
            downloadFiles()
            return
        }
        
        request(loadURL: loadUrl, saveURL: saveUrl)
    }
    
    func createQueue(_ gifs: [Gif]) {
        var videoPaths: [String] = []
        
        for gif in gifs {
            videoPaths.append(gif.gifPath)
            videoPaths.append(gif.previewPath)
            videoPaths.append(gif.filePath)
        }
        
        queue = videoPaths
        
        downloadFiles()
    }
    
    @IBAction func run() {
        guard queue.isEmpty || downloadRequest == nil else { return }
        getGifs()
    }
}

extension CheckResultViewController {
    
    func getGifs() {
        let sourceUrl = "https://v4-searchapi.vibbidi.com/sgifs"
        log.info("Request: \(sourceUrl)")
        
        request?.dispose()
        
        request = RxAlamofire.requestJSON(.get, sourceUrl)
            .timeout(timeOutTime, scheduler: RxScheduler.shared.apiBackground)
            .map{ (r, json) in
                do {
                    guard let dict = json as? UnboxableDictionary else { throw AppError(code: .unboxFail) }
                    let r: Gifs = try unbox(dictionary: dict)
                    return r.gifs
                } catch {
                    throw AppError(code: .unboxFail)
                }
            }
            .observeOn(RxScheduler.shared.main)
            .subscribe(onNext: { [unowned self] (r: [Gif]) in
                self.gifs = r
                self.createQueue(self.gifs)
                }, onError: { [unowned self] (error) in
                    self.displayError(error.localizedDescription)
            })
        
        request?.disposed(by: disposeBag)
    }
    
    func request(loadURL: URL, saveURL: URL) {
        log.info("Load: \(loadURL)")
        log.info("Save: \(saveURL)")
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (saveURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        downloadRequest?.cancel()
        
        downloadRequest = Alamofire.download(loadURL, to: destination)
            .downloadProgress{ progress in
                DispatchQueue.main.async { [weak self] in
                    self?.exportLabel.text = "Downloading video: \(progress.fractionCompleted)..."
                    self?.progressView.progress = Float(progress.fractionCompleted)
                }
            }
            .response { response in
                if let err = response.error {
                    DispatchQueue.main.async { [weak self] in
                        self?.exportLabel.text = "Error. Download fail: \(err.localizedDescription)"
                        log.error("Error: \(err)")
                        self?.downloadFiles()
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.exportLabel.text = "Download Completed."
                        self?.downloadFiles()
                    }
                }
        }
        
        downloadRequest?.resume()
    }
    
    func createCheckDirectory() -> URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let url = documentDirectoryUrl.appendingPathComponent("Check", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: url.path)
            } catch {
                log.error("Error: \(error)")
                return nil
            }
        }
        return url
    }
}
