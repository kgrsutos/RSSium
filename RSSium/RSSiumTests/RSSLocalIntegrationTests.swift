import Testing
import Foundation
@testable import RSSium

struct RSSLocalIntegrationTests {
    
    let rssService = RSSService.shared
    
    @Test
    func validateFeedURL() {
        #expect(rssService.validateFeedURL("https://example.com/feed.xml"))
        #expect(rssService.validateFeedURL("http://example.com/rss"))
        #expect(!rssService.validateFeedURL("invalid-url"))
        #expect(!rssService.validateFeedURL(""))
        #expect(!rssService.validateFeedURL("ftp://example.com/feed"))
    }
    
    @Test
    func parseRSSXMLFormat() throws {
        let rssXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
        <channel>
            <title>Test Feed</title>
            <link>https://example.com</link>
            <description>Test Description</description>
            <item>
                <title>Test Article</title>
                <link>https://example.com/article1</link>
                <description>Test article content</description>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
            </item>
        </channel>
        </rss>
        """
        
        let data = Data(rssXML.utf8)
        let channel = try rssService.parseData(data)
        
        #expect(channel.title == "Test Feed")
        #expect(channel.link == "https://example.com")
        #expect(channel.description == "Test Description")
        #expect(channel.items.count == 1)
        
        let item = channel.items.first!
        #expect(item.title == "Test Article")
        #expect(item.link == "https://example.com/article1")
        #expect(item.description == "Test article content")
        #expect(item.pubDate != nil)
    }
    
    @Test
    func parseAtomXMLFormat() throws {
        let atomXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
            <title>Test Atom Feed</title>
            <link href="https://example.com"/>
            <id>https://example.com/feed</id>
            <updated>2024-01-01T00:00:00Z</updated>
            <entry>
                <title>Test Atom Entry</title>
                <link href="https://example.com/entry1"/>
                <id>https://example.com/entry1</id>
                <updated>2024-01-01T00:00:00Z</updated>
                <summary>Test entry content</summary>
            </entry>
        </feed>
        """
        
        let data = Data(atomXML.utf8)
        let channel = try rssService.parseData(data)
        
        #expect(channel.title == "Test Atom Feed")
        #expect(channel.link == "https://example.com")
        #expect(channel.items.count == 1)
        
        let item = channel.items.first!
        #expect(item.title == "Test Atom Entry")
        #expect(item.link == "https://example.com/entry1")
        #expect(item.description == "Test entry content")
    }
    
    @Test
    func handleInvalidXML() {
        let invalidXML = "<invalid>not a valid rss feed</invalid>"
        let data = Data(invalidXML.utf8)
        
        #expect(throws: RSSError.self) {
            try rssService.parseData(data)
        }
    }
    
    @Test
    func parseMultipleItems() throws {
        let rssXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
        <channel>
            <title>Multi Item Feed</title>
            <link>https://example.com</link>
            <description>Feed with multiple items</description>
            <item>
                <title>Article 1</title>
                <link>https://example.com/1</link>
                <description>First article</description>
            </item>
            <item>
                <title>Article 2</title>
                <link>https://example.com/2</link>
                <description>Second article</description>
            </item>
            <item>
                <title>Article 3</title>
                <link>https://example.com/3</link>
                <description>Third article</description>
            </item>
        </channel>
        </rss>
        """
        
        let data = Data(rssXML.utf8)
        let channel = try rssService.parseData(data)
        
        #expect(channel.items.count == 3)
        #expect(channel.items[0].title == "Article 1")
        #expect(channel.items[1].title == "Article 2")
        #expect(channel.items[2].title == "Article 3")
    }
}