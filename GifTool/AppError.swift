//
//  AppErrorEntity.swift
//  VIBBIDI
//
//  Created by Nah on 11/25/17.
//  Copyright © 2017 glue-th. All rights reserved.
//

import Foundation
import Unbox

extension AppError {
    
    enum Code: Int {
        case unknown = 500 // Abtract error
        case httpAuthFail = 401
        case httpForbidden = 403
        case httpNotFound = 404
        case httpChatInvalid = 429
        case httpMaintenance = 503
        case httpWrongVersion = 505
        case httpDownloadEmptyData = 666
        case cancelUpload = 600
        case unboxFail = 99999
        
        init(rawCode: Int) {
            if let errorCode = Code(rawValue: rawCode) {
                self = errorCode
            } else {
                self = Code.unknown
            }
        }
    }
}

struct AppError: Swift.Error {
    
    let code: Code
    
    let id: String
    let traceId: String
    
    let isUserMessage: Bool
    let message: String
    let detailError: String
    
}

// Init with JSON from server
extension AppError: Unboxable {
    
    public init(unboxer u: Unboxer) throws {
        self.id = try u.unbox(key: "id")
        
        let rawCode: Int = try u.unbox(key: "status_code")
        self.code = Code(rawCode: rawCode)
        
        do {
            self.isUserMessage = try u.unbox(key: "is_user_message")
        } catch {
            self.isUserMessage = false
        }
        
        do {
            self.message = try u.unbox(key: "message")
        } catch {
            self.message = ""
        }
        
        do {
            self.detailError = try u.unbox(key: "detailed_error")
        } catch {
            self.detailError = ""
        }
        
        do {
            self.traceId = try u.unbox(key: "vtrace_id")
        } catch {
            self.traceId = ""
        }
    }
}

// Init with code only
extension AppError {
    
    init(code: Code) {
        self.code = code
        self.id = "vibbidi.error.local"
        self.isUserMessage = false
        self.message = ""
        self.detailError = ""
        self.traceId = ""
    }
}


