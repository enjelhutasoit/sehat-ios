//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest

/// Quality gate for string catalogs. It reads every `.xcstrings` file in the
/// repository as JSON, so it needs no bundle, simulator, or UI.
final class StringCatalogTests: XCTestCase {

    func test_repository_containsStringCatalogs() throws {
        XCTAssertFalse(
            try loadCatalogs().isEmpty,
            "No .xcstrings file found. Is the repository root detection broken?"
        )
    }

    func test_everyCatalog_usesEnglishAsSourceLanguage() throws {
        for catalog in try loadCatalogs() {
            XCTAssertEqual(catalog.sourceLanguage, "en", catalog.name)
        }
    }

    func test_everyString_hasATranslatedIndonesianValue() throws {
        for catalog in try loadCatalogs() {
            for (key, entry) in catalog.entries where entry.shouldTranslate {
                let indonesian = entry.localization("id")
                XCTAssertEqual(
                    indonesian?.state, "translated",
                    "\(catalog.name): '\(key)' has no translated 'id' value"
                )
                let value = (indonesian?.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(value.isEmpty, "\(catalog.name): '\(key)' has an empty 'id' value")
            }
        }
    }

    func test_symbolicKeys_haveAnEnglishValue() throws {
        for catalog in try loadCatalogs() {
            for (key, entry) in catalog.entries where Self.isSymbolic(key) {
                let value = (entry.localization("en")?.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(value.isEmpty, "\(catalog.name): symbolic key '\(key)' has no 'en' value")
            }
        }
    }

    func test_indonesianValues_keepTheFormatSpecifiersOfTheEnglishText() throws {
        for catalog in try loadCatalogs() {
            for (key, entry) in catalog.entries where entry.shouldTranslate {
                // A missing 'id' value is reported by the test above.
                guard let indonesian = entry.localization("id")?.value else { continue }
                let english = entry.localization("en")?.value ?? key
                XCTAssertEqual(
                    specifiers(in: indonesian), specifiers(in: english),
                    "\(catalog.name): '\(key)' changes the format specifiers"
                )
            }
        }
    }

    // MARK: - Model

    private struct Localization {
        let state: String?
        let value: String?
    }

    private struct Entry {
        let shouldTranslate: Bool
        private let localizations: [String: Any]

        init(_ raw: [String: Any]) {
            shouldTranslate = (raw["shouldTranslate"] as? Bool) ?? true
            localizations = (raw["localizations"] as? [String: Any]) ?? [:]
        }

        func localization(_ language: String) -> Localization? {
            guard let item = localizations[language] as? [String: Any],
                  let unit = item["stringUnit"] as? [String: Any]
            else { return nil }
            return Localization(state: unit["state"] as? String, value: unit["value"] as? String)
        }
    }

    private struct Catalog {
        let name: String
        let sourceLanguage: String
        let entries: [String: Entry]
    }

    private enum CatalogError: Error {
        case malformed(String)
    }

    // MARK: - Loading

    private func loadCatalogs() throws -> [Catalog] {
        let root = repositoryRoot()
        return try catalogURLs(under: root).map { url in
            let name = url.path.replacingOccurrences(of: root.path + "/", with: "")
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let source = json["sourceLanguage"] as? String,
                  let strings = json["strings"] as? [String: Any]
            else { throw CatalogError.malformed(name) }

            var entries: [String: Entry] = [:]
            for (key, value) in strings {
                guard let raw = value as? [String: Any] else {
                    throw CatalogError.malformed("\(name): \(key)")
                }
                entries[key] = Entry(raw)
            }
            return Catalog(name: name, sourceLanguage: source, entries: entries)
        }
    }

    /// `<repo>/Packages/SehatLocalizationChecks/Tests/SehatLocalizationChecksTests/<this file>`
    private func repositoryRoot(file: StaticString = #filePath) -> URL {
        var url = URL(fileURLWithPath: "\(file)")
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url
    }

    private func catalogURLs(under root: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else { throw CatalogError.malformed(root.path) }

        let skipped: Set<String> = [".build", ".git", ".swiftpm", "DerivedData"]
        var urls: [URL] = []
        for case let url as URL in enumerator {
            if skipped.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            if url.pathExtension == "xcstrings" {
                urls.append(url)
            }
        }
        return urls.sorted { $0.path < $1.path }
    }

    // MARK: - Helpers

    /// Keys like `error.offline` are identifiers, not English text.
    private static func isSymbolic(_ key: String) -> Bool {
        key.range(of: "^[a-z0-9_.]+$", options: .regularExpression) != nil
    }

    private func specifiers(in text: String) -> [String] {
        let pattern = #"%(?:\d+\$)?(?:hh|h|ll|l|q|z|t|j)?[@dDiuUxXoOfFeEgGcCsSaAp]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            XCTFail("Invalid regular expression")
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range)
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } }
            .map { $0.replacingOccurrences(of: #"\d+\$"#, with: "", options: .regularExpression) }
            .sorted()
    }
}
