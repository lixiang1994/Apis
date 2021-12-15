//
//  URLMatcher.swift
//  ┌─┐      ┌───────┐ ┌───────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ │      │ └─────┐ │ └─────┐
//  │ │      │ ┌─────┘ │ ┌─────┘
//  │ └─────┐│ └─────┐ │ └─────┐
//  └───────┘└───────┘ └───────┘
//
//  Created by lee on 2021/11/30.
//  Copyright © 2021 lee. All rights reserved.
//

import Foundation

/// URLMatcher provides a way to match URLs against a list of specified patterns.
///
/// URLMatcher extracts the pattern and the values from the URL if possible.
class URLMatcher {
    typealias URLPattern = String
    typealias URLValueConverter = (_ pathComponents: [String], _ index: Int) -> Any?

    static let defaultURLValueConverters: [String: URLValueConverter] = [
        "string": { pathComponents, index in
            return pathComponents[index]
        },
        "int": { pathComponents, index in
            return Int(pathComponents[index])
        },
        "float": { pathComponents, index in
            return Float(pathComponents[index])
        },
        "uuid": { pathComponents, index in
            return UUID(uuidString: pathComponents[index])
        },
        "path": { pathComponents, index in
            return pathComponents[index..<pathComponents.count].joined(separator: "/")
        }
    ]

    var valueConverters: [String: URLValueConverter] = URLMatcher.defaultURLValueConverters
    
    /// Returns a matching URL pattern and placeholder values from the specified URL and patterns.
    /// It returns `nil` if the given URL is not contained in the URL patterns.
    ///
    /// For example:
    ///
    ///     let result = matcher.match("myapp://user/123", from: ["myapp://user/<int:id>"])
    ///
    /// The value of the `URLPattern` from an example above is `"myapp://user/<int:id>"` and the
    /// value of the `values` is `["id": 123]`.
    ///
    /// - parameter url: The placeholder-filled URL.
    /// - parameter from: The array of URL patterns.
    ///
    /// - returns: A `URLMatchComponents` struct that holds the URL pattern string, a dictionary of
    ///            the URL placeholder values.
    func match(_ url: URLConvertible, from candidates: [URLPattern]) -> URLMatchResult? {
        let url = self.normalizeURL(url)
        let scheme = url.value?.scheme
        let stringPathComponents = self.stringPathComponents(from :url)
        
        for candidate in candidates {
            guard scheme == candidate.value?.scheme else { continue }
            if let result = self.match(stringPathComponents, with: candidate) {
                return result
            }
        }
        
        return nil
    }
    
    func match(_ stringPathComponents: [String], with candidate: URLPattern) -> URLMatchResult? {
        let normalizedCandidate = self.normalizeURL(candidate).stringValue
        let candidatePathComponents = self.pathComponents(from: normalizedCandidate)
        guard self.ensurePathComponentsCount(stringPathComponents, candidatePathComponents) else {
            return nil
        }
        
        var urlValues: [String: Any] = [:]
        
        let pairCount = min(stringPathComponents.count, candidatePathComponents.count)
        for index in 0 ..< pairCount {
            let result = self.matchStringPathComponent(
                at: index,
                from: stringPathComponents,
                with: candidatePathComponents
            )
            
            switch result {
            case let .matches(placeholderValue):
                if let (key, value) = placeholderValue {
                    urlValues[key] = value
                }
                
            case .notMatches:
                return nil
            }
        }
        
        return URLMatchResult(pattern: candidate, values: urlValues)
    }
    
    private func normalizeURL(_ dirtyURL: URLConvertible) -> URLConvertible {
        guard dirtyURL.value != nil else { return dirtyURL }
        var urlString = dirtyURL.stringValue
        urlString = urlString.components(separatedBy: "?")[0].components(separatedBy: "#")[0]
        urlString = self.replaceRegex(":/{3,}", "://", urlString)
        urlString = self.replaceRegex("(?<!:)/{2,}", "/", urlString)
        urlString = self.replaceRegex("(?<!:|:/)/+$", "", urlString)
        return urlString
    }
    
    private func replaceRegex(_ pattern: String, _ repl: String, _ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return string }
        let range = NSMakeRange(0, string.count)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: repl)
    }
    
    private func ensurePathComponentsCount(
        _ stringPathComponents: [String],
        _ candidatePathComponents: [URLPathComponent]
    ) -> Bool {
        let hasSameNumberOfComponents = (stringPathComponents.count == candidatePathComponents.count)
        let containsPathPlaceholderComponent = candidatePathComponents.contains {
            if case let .placeholder(type, _) = $0, type == "path" {
                return true
            } else {
                return false
            }
        }
        return hasSameNumberOfComponents || (containsPathPlaceholderComponent && stringPathComponents.count > candidatePathComponents.count)
    }
    
    private func stringPathComponents(from url: URLConvertible) -> [String] {
        return url.stringValue.components(separatedBy: "/").lazy
            .filter { !$0.isEmpty }
            .filter { !$0.hasSuffix(":") }
    }
    
    private func pathComponents(from url: URLPattern) -> [URLPathComponent] {
        return stringPathComponents(from: url).map(URLPathComponent.init)
    }
    
    private func matchStringPathComponent(
        at index: Int,
        from stringPathComponents: [String],
        with candidatePathComponents: [URLPathComponent]
    ) -> URLPathComponentMatchResult {
        let stringPathComponent = stringPathComponents[index]
        let urlPathComponent = candidatePathComponents[index]
        
        switch urlPathComponent {
        case let .plain(value):
            guard stringPathComponent == value else { return .notMatches }
            return .matches(nil)
            
        case let .placeholder(type, key):
            guard let type = type, let converter = self.valueConverters[type] else {
                return .matches((key, stringPathComponent))
            }
            if let value = converter(stringPathComponents, index) {
                return .matches((key, value))
                
            } else {
                return .notMatches
            }
        }
    }
}


/// Represents an URL match result.
struct URLMatchResult {
    /// The url pattern that was matched.
    let pattern: String

    /// The values extracted from the URL placeholder.
    let values: [String: Any]
}

enum URLPathComponentMatchResult {
    case matches((key: String, value: Any)?)
    case notMatches
}
