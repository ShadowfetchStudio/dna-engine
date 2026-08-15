import Foundation

enum ProductMetadata {
    static let parserVersion = "3.0"
    static let privateVaultVersion = "1"

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Local"
    }

    static var displayVersion: String { "\(version) (\(build))" }

    static var knowledgeVersion: String {
        KnowledgeBase.shared.version
    }
}
