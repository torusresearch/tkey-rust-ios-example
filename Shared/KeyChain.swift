//
//  KeyChain.swift
//  tkey_ios
//
//  Created by CW Lee on 13/12/2022.
//

import Foundation

import Security

class KeychainInterface {

    enum KeychainError: Error {
        // Attempted read for an item that does not exist.
        case itemNotFound

        // Attempted save to override an existing item.
        // Use update instead of save to update existing items
        case duplicateItem

        // A read of an item in any format other than Data
        case invalidItemFormat

        // Any operation result status than errSecSuccess
        case unexpectedStatus(OSStatus)
    }

    static func syncShare( threshold_key: ThresholdKey, share_index: String?, curve_n: String ) throws {
         let key_detail = try! threshold_key.get_key_details()

         if  key_detail.required_shares > 0 {
         // get share from keychain
             let share = try! readPassword(service: "tkey_ios", account: key_detail.pub_key.compressed)
             let shareStore = try! ShareStore(json: String(data: share, encoding: .utf8)!)
             try! threshold_key.input_share_store(shareStore: shareStore, curve_n: curve_n)

         } else {
         // save/update keychain
         var index = share_index
         if index == nil {
             let indexes = try! threshold_key.get_shares_indexes()
             if indexes[0] == "1" { index = indexes[1] } else { index = indexes[0] }
         }

         // TODO: get right index for device share
         // let share = try! threshold_key.output_share(shareIndex: index!, shareType: "hex", curve_n: curve_n)
         let share = try threshold_key.output_share_store(shareIndex: index!, polyId: nil, curve_n: curve_n)
         let share_str = try! share.toJsonString()

         do {
             try save( password: share_str.data(using: .utf8)!, service: "tkey_ios", account: key_detail.pub_key.compressed )
         } catch KeychainError.duplicateItem {
             try! update(password: share_str.data(using: .utf8)!, service: "tkey_ios", account: key_detail.pub_key.compressed )
         }
         }
     }

    static func getAllAccounts() throws -> [[String: Any]] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "tkey_ios" as AnyObject,
                kSecMatchLimit as String: kSecMatchLimitAll,
                kSecReturnAttributes as String: true
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess {
                return result as! [[String: Any]]
            } else {
                // Handle the error
                throw KeychainError.unexpectedStatus(status)
            }
        }

    static func save(password: Data, service: String, account: String) throws {

        let query: [String: AnyObject] = [
            // kSecAttrService,  kSecAttrAccount, and kSecClass
            // uniquely identify the item to save in Keychain
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword,

            // kSecValueData is the item value to save
            kSecValueData as String: password as AnyObject
        ]

        // SecItemAdd attempts to add the item identified by
        // the query to keychain
        let status = SecItemAdd(
            query as CFDictionary,
            nil
        )

        // errSecDuplicateItem is a special case where the
        // item identified by the query already exists. Throw
        // duplicateItem so the client can determine whether
        // or not to handle this as an error
        if status == errSecDuplicateItem {
            throw KeychainError.duplicateItem
        }

        // Any status other than errSecSuccess indicates the
        // save operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func update(password: Data, service: String, account: String) throws {
        let query: [String: AnyObject] = [
            // kSecAttrService,  kSecAttrAccount, and kSecClass
            // uniquely identify the item to update in Keychain
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword
        ]

        // attributes is passed to SecItemUpdate with
        // kSecValueData as the updated item value
        let attributes: [String: AnyObject] = [
            kSecValueData as String: password as AnyObject
        ]

        // SecItemUpdate attempts to update the item identified
        // by query, overriding the previous value
        let status = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        // errSecItemNotFound is a special status indicating the
        // item to update does not exist. Throw itemNotFound so
        // the client can determine whether or not to handle
        // this as an error
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        // Any status other than errSecSuccess indicates the
        // update operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func readPassword(service: String, account: String) throws -> Data {
        let query: [String: AnyObject] = [
            // kSecAttrService,  kSecAttrAccount, and kSecClass
            // uniquely identify the item to read in Keychain
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword,

            // kSecMatchLimitOne indicates keychain should read
            // only the most recent item matching this query
            kSecMatchLimit as String: kSecMatchLimitOne,

            // kSecReturnData is set to kCFBooleanTrue in order
            // to retrieve the data for the item
            kSecReturnData as String: kCFBooleanTrue
        ]

        // SecItemCopyMatching will attempt to copy the item
        // identified by query to the reference itemCopy
        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &itemCopy
        )

        // errSecItemNotFound is a special status indicating the
        // read item does not exist. Throw itemNotFound so the
        // client can determine whether or not to handle
        // this case
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        // Any status other than errSecSuccess indicates the
        // read operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        // This implementation of KeychainInterface requires all
        // items to be saved and read as Data. Otherwise,
        // invalidItemFormat is thrown
        guard let password = itemCopy as? Data else {
            throw KeychainError.invalidItemFormat
        }

        return password
    }

    static func deletePassword(service: String, account: String) throws {
        let query: [String: AnyObject] = [
            // kSecAttrService,  kSecAttrAccount, and kSecClass
            // uniquely identify the item to delete in Keychain
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword
        ]

        // SecItemDelete attempts to perform a delete operation
        // for the item identified by query. The status indicates
        // if the operation succeeded or failed.
        let status = SecItemDelete(query as CFDictionary)

        // Any status other than errSecSuccess indicates the
        // delete operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
