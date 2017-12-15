//
//  RxScheduler.swift
//  VIBBIDI
//
//  Created by 安保元靖 on 2016/11/14.
//  Copyright © 2016年 glue-th. All rights reserved.
//

import RxSwift
import RxCocoa

/**
 RxSwiftで同期・非同期・並列処理をするためのシングルトン
 - main: 同期処理
 - serialBackground: 非同期処理
 - concurrentBackground: 並列処理
 */
struct RxScheduler {
    static let shared = RxScheduler()
    
    let main: SerialDispatchQueueScheduler
    let serialBackground: SerialDispatchQueueScheduler
    let concurrentBackground: ImmediateSchedulerType
    let apiBackground: ConcurrentDispatchQueueScheduler
    
    init() {
        main = MainScheduler.instance
        serialBackground = SerialDispatchQueueScheduler.init(qos: .default)
        apiBackground = ConcurrentDispatchQueueScheduler.init(qos: .background)
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 5
        operationQueue.qualityOfService = QualityOfService.userInitiated
        concurrentBackground = OperationQueueScheduler(operationQueue: operationQueue)
    }
}

