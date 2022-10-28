//
//  StorageLayer.swift
//  tkey_ios
//
//  Created by David Main.
//

import Foundation

final class StorageLayer {
    private(set) var pointer: OpaquePointer?
    
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    init(enable_logging: Bool, host_url: String, server_time_offset: UInt) throws {
        var errorCode: Int32 = -1
        let urlPointer = UnsafeMutablePointer<Int8>(mutating: (host_url as NSString).utf8String)
        
        let network_interface: (@convention(c) (UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<CChar>?, UnsafeMutablePointer<Int32>?) -> UnsafeMutablePointer<CChar>?)? = {url, data, error_code in
            let sem = DispatchSemaphore.init(value: 0)
            let urlString = String.init(cString: url!)
            let dataString = String.init(cString: data!)
            let url = URL(string: urlString)!
            let session = URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")
            request.addValue("GET, POST", forHTTPHeaderField: "Access-Control-Allow-Methods")
            request.addValue("Content-Type", forHTTPHeaderField: "Access-Control-Allow-Headers")
            
            if urlString.split(separator: "/").last == "bulk_set_stream"
            {
                request.addValue("application/form-data", forHTTPHeaderField: "Content-Type")
                request.httpBody = dataString.data(using: String.Encoding.utf8)
            } else {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = dataString.data(using: String.Encoding.utf8)
            }
            
            var resultPointer = UnsafeMutablePointer<CChar>(nil)
            let task = session.dataTask(with: request) { data, response, error in
                defer { sem.signal() }
                if error != nil {
                    let code: Int32 = 1
                    error_code?.pointee = code
                }
                if let data = data {
                    let resultString: String = String(decoding: data, as: UTF8.self)
                    let result: NSString = NSString(string: resultString)
                    resultPointer = UnsafeMutablePointer<CChar>(mutating: result.utf8String)
                }
            }
            task.resume()
            // This line will wait until the semaphore has been signaled
              // which will be once the data task has completed
            sem.wait()
            return resultPointer
        }
        
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            storage_layer(enable_logging, urlPointer, server_time_offset, network_interface, error)
                })
        guard errorCode == 0 else {
            throw RuntimeError("Error in StorageLayer")
            }
        pointer = result
    }
    
    deinit {
        storage_layer_free(pointer)
    }
}
