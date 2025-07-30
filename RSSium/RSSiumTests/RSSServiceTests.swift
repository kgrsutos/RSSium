import Testing
import Foundation
@testable import RSSium

struct RSSServiceTests {
    let service = RSSService.shared
    
    @Test("Validate feed URL - valid URLs")
    func testValidFeedURLs() {
        let validURLs = [
            "https://example.com/feed.rss",
            "http://blog.example.com/rss",
            "https://news.site.com/feed/",
            "https://example.com:8080/feed.xml"
        ]
        
        for url in validURLs {
            #expect(service.validateFeedURL(url) == true, "URL should be valid: \(url)")
        }
    }
    
    @Test("Validate feed URL - invalid URLs")
    func testInvalidFeedURLs() {
        let invalidURLs = [
            "",
            "not a url",
            "ftp://example.com/feed",
            "https://",
            "example.com/feed",
            "//example.com/feed"
        ]
        
        for url in invalidURLs {
            #expect(service.validateFeedURL(url) == false, "URL should be invalid: \(url)")
        }
    }
    
    @Test("Parse RSS 2.0 feed")
    func testParseRSS20Feed() async throws {
        let rss20XML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Test Blog</title>
                <link>https://example.com</link>
                <description>A test blog for RSS parsing</description>
                <item>
                    <title>First Post</title>
                    <link>https://example.com/post1</link>
                    <description>This is the first post</description>
                    <pubDate>Mon, 15 Jul 2025 10:00:00 GMT</pubDate>
                    <author>test@example.com</author>
                    <guid>https://example.com/post1</guid>
                </item>
                <item>
                    <title>Second Post</title>
                    <link>https://example.com/post2</link>
                    <description>This is the second post</description>
                    <pubDate>Tue, 16 Jul 2025 12:00:00 GMT</pubDate>
                    <guid>post2-guid</guid>
                </item>
            </channel>
        </rss>
        """
        
        let data = rss20XML.data(using: .utf8)!
        let channel = try service.parseData(data)
        
        #expect(channel.title == "Test Blog")
        #expect(channel.link == "https://example.com")
        #expect(channel.description == "A test blog for RSS parsing")
        #expect(channel.items.count == 2)
        
        let firstItem = channel.items[0]
        #expect(firstItem.title == "First Post")
        #expect(firstItem.link == "https://example.com/post1")
        #expect(firstItem.description == "This is the first post")
        #expect(firstItem.author == "test@example.com")
        #expect(firstItem.guid == "https://example.com/post1")
        #expect(firstItem.pubDate != nil)
        
        let secondItem = channel.items[1]
        #expect(secondItem.title == "Second Post")
        #expect(secondItem.guid == "post2-guid")
    }
    
    @Test("Parse Atom feed")
    func testParseAtomFeed() async throws {
        let atomXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
            <title>Test Atom Feed</title>
            <link href="https://example.com/atom" />
            <subtitle>An Atom feed for testing</subtitle>
            <entry>
                <title>Atom Entry 1</title>
                <link href="https://example.com/atom/entry1" />
                <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
                <updated>2025-07-15T18:30:02Z</updated>
                <summary>Summary of the first entry</summary>
                <author>
                    <name>John Doe</name>
                </author>
            </entry>
            <entry>
                <title>Atom Entry 2</title>
                <link href="https://example.com/atom/entry2" />
                <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6b</id>
                <published>2025-07-16T10:00:00Z</published>
                <content>Full content of the second entry</content>
            </entry>
        </feed>
        """
        
        let data = atomXML.data(using: .utf8)!
        let channel = try service.parseData(data)
        
        #expect(channel.title == "Test Atom Feed")
        #expect(channel.link == "https://example.com/atom")
        #expect(channel.description == "An Atom feed for testing")
        #expect(channel.items.count == 2)
        
        let firstItem = channel.items[0]
        #expect(firstItem.title == "Atom Entry 1")
        #expect(firstItem.link == "https://example.com/atom/entry1")
        #expect(firstItem.description == "Summary of the first entry")
        #expect(firstItem.author == "John Doe")
        #expect(firstItem.guid == "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a")
        #expect(firstItem.pubDate != nil)
        
        let secondItem = channel.items[1]
        #expect(secondItem.title == "Atom Entry 2")
        #expect(secondItem.description == "Full content of the second entry")
    }
    
    @Test("Parse feed with missing optional fields")
    func testParseFeedWithMissingFields() async throws {
        let minimalXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Minimal Feed</title>
                <item>
                    <title>Minimal Item</title>
                </item>
            </channel>
        </rss>
        """
        
        let data = minimalXML.data(using: .utf8)!
        let channel = try service.parseData(data)
        
        #expect(channel.title == "Minimal Feed")
        #expect(channel.link == nil)
        #expect(channel.description == nil)
        #expect(channel.items.count == 1)
        
        let item = channel.items[0]
        #expect(item.title == "Minimal Item")
        #expect(item.link == nil)
        #expect(item.description == nil)
        #expect(item.pubDate == nil)
        #expect(item.author == nil)
    }
    
    @Test("Parse invalid XML throws error")
    func testParseInvalidXML() async throws {
        let invalidXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Broken Feed</title>
                <item>
                    <title>Unclosed tag
                </item>
            </channel>
        </rss>
        """
        
        let data = invalidXML.data(using: .utf8)!
        
        #expect(throws: RSSError.self) {
            _ = try service.parseData(data)
        }
    }
    
    @Test("Parse empty feed throws error")
    func testParseEmptyFeed() async throws {
        let emptyXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
            </channel>
        </rss>
        """
        
        let data = emptyXML.data(using: .utf8)!
        
        #expect(throws: RSSError.invalidFeedFormat) {
            _ = try service.parseData(data)
        }
    }
    
    @Test("Parse various date formats")
    func testParseDateFormats() async throws {
        let xmlWithDates = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Date Test Feed</title>
                <item>
                    <title>RFC822 Date</title>
                    <pubDate>Wed, 15 Jul 2025 14:30:00 GMT</pubDate>
                </item>
                <item>
                    <title>RFC822 with timezone</title>
                    <pubDate>Wed, 15 Jul 2025 14:30:00 EST</pubDate>
                </item>
                <item>
                    <title>ISO8601 Date</title>
                    <pubDate>2025-07-15T14:30:00Z</pubDate>
                </item>
                <item>
                    <title>ISO8601 with milliseconds</title>
                    <pubDate>2025-07-15T14:30:00.123Z</pubDate>
                </item>
            </channel>
        </rss>
        """
        
        let data = xmlWithDates.data(using: .utf8)!
        let channel = try service.parseData(data)
        
        #expect(channel.items.count == 4)
        
        for item in channel.items {
            #expect(item.pubDate != nil, "Date should be parsed for item: \(item.title)")
        }
    }
    
    @Test("Handle special characters and CDATA")
    func testSpecialCharactersAndCDATA() async throws {
        let xmlWithSpecialChars = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Special &amp; Characters</title>
                <item>
                    <title>Post with &lt;HTML&gt; tags</title>
                    <description><![CDATA[This contains <b>HTML</b> and special characters: &amp; < > "]]></description>
                </item>
            </channel>
        </rss>
        """
        
        let data = xmlWithSpecialChars.data(using: .utf8)!
        let channel = try service.parseData(data)
        
        #expect(channel.title == "Special & Characters")
        #expect(channel.items.count == 1)
        
        let item = channel.items[0]
        #expect(item.title == "Post with <HTML> tags")
        #expect(item.description?.contains("<b>HTML</b>") == true)
    }
}