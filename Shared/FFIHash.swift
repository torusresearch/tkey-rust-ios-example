import Foundation


class FFIHash {

    func hash(input: String) -> String {
        
        var errorCode: Int32 = -1
        
        let inputPointer = UnsafeMutablePointer<Int8>(mutating: (input as NSString).utf8String)
        let resultPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            sha256_hash(inputPointer)
        })
        let result = String(validatingUTF8: resultPtr!)!
        let mutable = UnsafeMutablePointer<Int8>(mutating: resultPtr!)
        string_destroy(mutable)
        return result
    }
}
