////
////  Repository.swift
////  openred
////
////  Created by Norbert Antal on 6/13/23.
////
//
//import Foundation
//
//class UserRepository {
//    enum Key: String, CaseIterable {
//        case name, avatarData
//        func make(for userID: String) -> String {
//            return self.rawValue + "_" + userID
//        }
//    }
//    let userDefaults: UserDefaults
//    // MARK: - Lifecycle
//    init(userDefaults: UserDefaults = .standard) {
//        self.userDefaults = userDefaults
//    }
//    // MARK: - API
//    func storeInfo(forUserID userID: String, name: String, avatarData: Data) {
//        saveValue(forKey: .name, value: name, userID: userID)
//        saveValue(forKey: .avatarData, value: avatarData, userID: userID)
//    }
//    
//    func getUserInfo(forUserID userID: String) -> (name: String?, avatarData: Data?) {
//        let name: String? = readValue(forKey: .name, userID: userID)
//        let avatarData: Data? = readValue(forKey: .avatarData, userID: userID)
//        return (name, avatarData)
//    }
//    
//    func removeUserInfo(forUserID userID: String) {
//        Key
//            .allCases
//            .map { $0.make(for: userID) }
//            .forEach { key in
//                userDefaults.removeObject(forKey: key)
//        }
//    }
//    // MARK: - Private
//    private func saveValue(forKey key: Key, value: Any, userID: String) {
//        userDefaults.set(value, forKey: key)
//    }
//    private func readValue<T>(forKey key: Key, userID: String) -> T? {
//        return userDefaults.value(forKey: key) as? T
//    }
//}
//
