import Foundation
import Combine

enum RSSError: LocalizedError, Equatable {
    case invalidURL
    case invalidFeedFormat
    case networkError(Error)
    case parsingError(String)
    
    static func == (lhs: RSSError, rhs: RSSError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidFeedFormat, .invalidFeedFormat):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        case (.parsingError(let lhsMessage), .parsingError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .invalidFeedFormat:
            return "The feed format is not supported"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
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
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw RSSError.networkError(URLError(.badServerResponse))
            }
            
            return try await parseFeedData(data)
        } catch let error as RSSError {
            throw error
        } catch {
            throw RSSError.networkError(error)
        }
    }
    
    private func parseFeedData(_ data: Data) async throws -> RSSChannel {
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
        let parser = RSSParser()
        return try parser.parse(data: data)
    }
    
    func validateFeedURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              url.host != nil else {
            return false
        }
        return true
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