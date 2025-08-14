import Foundation
import Combine

enum RSSError: LocalizedError, Equatable {
    case invalidURL
    case invalidFeedFormat
    case networkError(Error)
    case parsingError(String)
    case connectionTimeout
    case serverError(Int)
    case emptyResponse
    case unsupportedEncoding
    
    static func == (lhs: RSSError, rhs: RSSError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidFeedFormat, .invalidFeedFormat),
             (.connectionTimeout, .connectionTimeout),
             (.emptyResponse, .emptyResponse),
             (.unsupportedEncoding, .unsupportedEncoding):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        case (.parsingError(let lhsMessage), .parsingError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Please check the URL and try again"
        case .invalidFeedFormat:
            return "This RSS feed format is not supported"
        case .networkError(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "No internet connection available"
                case .timedOut:
                    return "Request timed out. Check your connection and try again"
                case .cannotFindHost:
                    return "Cannot reach the server. Check the URL"
                case .cannotConnectToHost:
                    return "Cannot connect to the server"
                case .badURL:
                    return "Invalid URL format"
                case .cancelled:
                    return "Request was cancelled"
                default:
                    return "Network error: \(error.localizedDescription)"
                }
            }
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Could not read RSS feed: \(message)"
        case .connectionTimeout:
            return "Connection timed out. Check your internet and try again"
        case .serverError(let code):
            switch code {
            case 404:
                return "RSS feed not found (404). Check the URL"
            case 403:
                return "Access denied to RSS feed (403)"
            case 500...599:
                return "Server error (\(code)). Try again later"
            default:
                return "Server returned error (\(code))"
            }
        case .emptyResponse:
            return "RSS feed is empty or invalid"
        case .unsupportedEncoding:
            return "RSS feed encoding is not supported"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Verify the URL starts with http:// or https://"
        case .invalidFeedFormat:
            return "Try a different RSS feed URL"
        case .networkError(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "Connect to WiFi or cellular data"
                case .timedOut, .cannotConnectToHost:
                    return "Check your internet connection and try again"
                case .cannotFindHost:
                    return "Verify the URL is correct"
                default:
                    return "Check your internet connection"
                }
            }
            return "Check your internet connection"
        case .connectionTimeout:
            return "Try again with a stable internet connection"
        case .serverError:
            return "Wait a moment and try again"
        case .emptyResponse:
            return "Verify this is a valid RSS feed URL"
        case .unsupportedEncoding:
            return "Contact the feed provider about encoding issues"
        default:
            return nil
        }
    }
}

struct RSSItem {
    let title: String
    let link: String?
    let description: String?
    let pubDate: Date?
    let author: String?
    let guid: String?
}

struct RSSChannel {
    let title: String
    let link: String?
    let description: String?
    let items: [RSSItem]
}

class RSSService: NSObject {
    static let shared = RSSService()
    
    private let session: URLSession
    
    private override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        super.init()
    }
    
    func fetchAndParseFeed(from urlString: String) async throws -> RSSChannel {
        guard let url = URL(string: urlString) else {
            throw RSSError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RSSError.networkError(URLError(.badServerResponse))
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 400...499:
                throw RSSError.serverError(httpResponse.statusCode)
            case 500...599:
                throw RSSError.serverError(httpResponse.statusCode)
            default:
                throw RSSError.serverError(httpResponse.statusCode)
            }
            
            // Check for empty response
            guard !data.isEmpty else {
                throw RSSError.emptyResponse
            }
            
            return try await parseFeedData(data)
        } catch let error as RSSError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw RSSError.connectionTimeout
            case .notConnectedToInternet:
                throw RSSError.networkError(urlError)
            case .cannotFindHost, .cannotConnectToHost:
                throw RSSError.networkError(urlError)
            default:
                throw RSSError.networkError(urlError)
            }
        } catch {
            throw RSSError.networkError(error)
        }
    }
    
    private func parseFeedData(_ data: Data) async throws -> RSSChannel {
        // Security check: Validate XML data size
        try validateXMLData(data)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let parser = RSSParser()
                do {
                    let channel = try parser.parse(data: data)
                    continuation.resume(returning: channel)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    internal func parseData(_ data: Data) throws -> RSSChannel {
        // Security check: Validate XML data size
        try validateXMLData(data)
        
        let parser = RSSParser()
        return try parser.parse(data: data)
    }
    
    private func validateXMLData(_ data: Data) throws {
        // 1. Check data size (prevent XML bombs)
        let maxDataSize = 50 * 1024 * 1024 // 50MB limit
        if data.count > maxDataSize {
            throw RSSError.invalidFeedFormat
        }
        
        // 2. Basic XML structure validation
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw RSSError.unsupportedEncoding
        }
        
        // 3. Check for suspicious XML content
        if containsSuspiciousXMLContent(xmlString) {
            throw RSSError.invalidFeedFormat
        }
    }
    
    private func containsSuspiciousXMLContent(_ xmlString: String) -> Bool {
        // More refined security checks that don't trigger on legitimate RSS content
        let suspiciousPatterns = [
            "<!ENTITY",          // XML entity definitions (potential XXE attacks)
            "file://",           // File protocol references (outside CDATA)
            "javascript:",       // JavaScript protocol (outside CDATA)
        ]
        
        let lowercaseXML = xmlString.lowercased()
        
        // Check for suspicious patterns, but be more careful about DOCTYPE
        for pattern in suspiciousPatterns {
            if lowercaseXML.contains(pattern.lowercased()) {
                return true
            }
        }
        
        // Only flag DOCTYPE if it's not inside CDATA sections (which are legitimate HTML content)
        if lowercaseXML.contains("<!doctype") {
            // Check if DOCTYPE appears outside CDATA sections
            let cdataPattern = #"<!\[CDATA\[.*?\]\]>"#
            let xmlWithoutCDATA = xmlString.replacingOccurrences(of: cdataPattern, with: "", options: .regularExpression, range: nil)
            if xmlWithoutCDATA.lowercased().contains("<!doctype") {
                return true
            }
        }
        
        // Check for external SYSTEM entities (more specific than just "SYSTEM")
        if lowercaseXML.contains("<!entity") && lowercaseXML.contains("system") {
            return true
        }
        
        // Check for excessive nesting or repetition (potential XML bombs)
        let entityCount = xmlString.components(separatedBy: "&").count - 1
        if entityCount > 100 {
            return true
        }
        
        return false
    }
    
    func validateFeedURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              let host = url.host else {
            return false
        }
        
        // Enhanced security validations
        
        // 1. Prevent access to private/local networks
        if isPrivateOrLocalHost(host) {
            return false
        }
        
        // 2. Prevent access to suspicious domains
        if isSuspiciousDomain(host) {
            return false
        }
        
        // 3. Validate URL length to prevent DoS attacks
        if urlString.count > 2000 {
            return false
        }
        
        // 4. Ensure reasonable port numbers
        if let port = url.port, !isValidPort(port) {
            return false
        }
        
        return true
    }
    
    private func isPrivateOrLocalHost(_ host: String) -> Bool {
        let lowercaseHost = host.lowercased()
        
        // Check for localhost variations
        if ["localhost", "127.0.0.1", "::1"].contains(lowercaseHost) {
            return true
        }
        
        // Check for private IP ranges (simplified check)
        if lowercaseHost.hasPrefix("192.168.") ||
           lowercaseHost.hasPrefix("10.") ||
           lowercaseHost.hasPrefix("172.16.") ||
           lowercaseHost.hasPrefix("172.17.") ||
           lowercaseHost.hasPrefix("172.18.") ||
           lowercaseHost.hasPrefix("172.19.") ||
           lowercaseHost.hasPrefix("172.2") ||
           lowercaseHost.hasPrefix("172.30.") ||
           lowercaseHost.hasPrefix("172.31.") {
            return true
        }
        
        // Check for IPv6 private ranges (simplified)
        if lowercaseHost.hasPrefix("fe80:") || // Link-local
           lowercaseHost.hasPrefix("fc00:") || // Unique local
           lowercaseHost.hasPrefix("fd00:") {  // Unique local
            return true
        }
        
        return false
    }
    
    private func isSuspiciousDomain(_ host: String) -> Bool {
        let lowercaseHost = host.lowercased()
        
        // Block common suspicious patterns
        let suspiciousPatterns = [
            ".onion",           // Tor hidden services
            ".i2p",             // I2P network
            "bit.ly",           // URL shorteners (can hide malicious URLs)
            "tinyurl.com",
            "t.co",
            "goo.gl",
            "ow.ly"
        ]
        
        for pattern in suspiciousPatterns {
            if lowercaseHost.contains(pattern) {
                return true
            }
        }
        
        // Check for excessive subdomains (potential DGA domains)
        let subdomains = host.components(separatedBy: ".")
        if subdomains.count > 5 {
            return true
        }
        
        return false
    }
    
    private func isValidPort(_ port: Int) -> Bool {
        // Allow common HTTP/HTTPS ports and some common RSS feed ports
        let allowedPorts = Set([80, 443, 8080, 8443, 3000, 4000, 5000, 8000, 9000])
        return allowedPorts.contains(port) || (port >= 1024 && port <= 65535)
    }
}

private class RSSParser: NSObject {
    private var channel: RSSChannel?
    private var currentItem: RSSItem?
    private var currentElement: String = ""
    private var currentValue: String = ""
    
    private var channelTitle: String = ""
    private var channelLink: String?
    private var channelDescription: String?
    private var items: [RSSItem] = []
    
    private var itemTitle: String = ""
    private var itemLink: String?
    private var itemDescription: String?
    private var itemPubDate: Date?
    private var itemAuthor: String?
    private var itemGuid: String?
    
    private let dateFormatters: [DateFormatter] = {
        let formatters = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ].map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
        return formatters
    }()
    
    private var isAtomFeed = false
    private var isInEntry = false
    private var isInAuthor = false
    
    func parse(data: Data) throws -> RSSChannel {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if !parser.parse() {
            if let error = parser.parserError {
                throw RSSError.parsingError(error.localizedDescription)
            } else {
                throw RSSError.invalidFeedFormat
            }
        }
        
        guard !channelTitle.isEmpty else {
            throw RSSError.invalidFeedFormat
        }
        
        return RSSChannel(
            title: channelTitle,
            link: channelLink,
            description: channelDescription,
            items: items
        )
    }
    
    private func parseDate(from string: String) -> Date? {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        for formatter in dateFormatters {
            if let date = formatter.date(from: trimmedString) {
                return date
            }
        }
        return nil
    }
}

extension RSSParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()
        currentValue = ""
        
        switch currentElement {
        case "feed":
            isAtomFeed = true
        case "item", "entry":
            isInEntry = true
            itemTitle = ""
            itemLink = nil
            itemDescription = nil
            itemPubDate = nil
            itemAuthor = nil
            itemGuid = nil
        case "link":
            if isAtomFeed, let href = attributeDict["href"] {
                if isInEntry {
                    itemLink = href
                } else {
                    channelLink = href
                }
            }
        case "author":
            if isInEntry {
                isInAuthor = true
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let element = elementName.lowercased()
        
        if isInEntry {
            switch element {
            case "title":
                itemTitle = trimmedValue
            case "link":
                if !isAtomFeed && itemLink == nil {
                    itemLink = trimmedValue
                }
            case "description", "summary", "content":
                if itemDescription == nil {
                    itemDescription = trimmedValue
                }
            case "pubdate", "published", "updated":
                if itemPubDate == nil {
                    itemPubDate = parseDate(from: trimmedValue)
                }
            case "name":
                if isInAuthor && itemAuthor == nil {
                    itemAuthor = trimmedValue
                }
            case "author":
                if isAtomFeed {
                    isInAuthor = false
                } else if itemAuthor == nil {
                    itemAuthor = trimmedValue
                }
            case "creator", "dc:creator":
                if itemAuthor == nil {
                    itemAuthor = trimmedValue
                }
            case "guid", "id":
                if itemGuid == nil {
                    itemGuid = trimmedValue
                }
            case "item", "entry":
                if !itemTitle.isEmpty {
                    let item = RSSItem(
                        title: itemTitle,
                        link: itemLink,
                        description: itemDescription,
                        pubDate: itemPubDate,
                        author: itemAuthor,
                        guid: itemGuid ?? itemLink
                    )
                    items.append(item)
                }
                isInEntry = false
            default:
                break
            }
        } else {
            switch element {
            case "title":
                if channelTitle.isEmpty {
                    channelTitle = trimmedValue
                }
            case "link":
                if !isAtomFeed && channelLink == nil {
                    channelLink = trimmedValue
                }
            case "description", "subtitle":
                if channelDescription == nil {
                    channelDescription = trimmedValue
                }
            default:
                break
            }
        }
        
        currentValue = ""
    }
}