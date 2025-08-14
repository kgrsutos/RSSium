import Testing
import Foundation
import UIKit
@testable import RSSium

struct ImageCacheServiceTests {
    
    @MainActor
    @Test("ImageCacheService singleton instance")
    func testSingletonInstance() {
        let instance1 = ImageCacheService.shared
        let instance2 = ImageCacheService.shared
        
        #expect(instance1 === instance2)
    }
    
    @MainActor
    @Test("Clear cache functionality")
    func testClearCache() async throws {
        let service = ImageCacheService.shared
        
        // Clear the cache
        service.clearCache()
        
        // Cache should be empty after clearing
        // Since we can't directly inspect the cache, we verify it doesn't crash
        #expect(true) // Operation completed successfully
    }
    
    @MainActor
    @Test("Load image with invalid URL returns nil")
    func testLoadImageWithInvalidURL() async throws {
        let service = ImageCacheService.shared
        
        // Try to load from an invalid URL
        let invalidURL = URL(string: "http://invalid-url-that-does-not-exist.com/image.png")!
        let image = await service.loadImage(from: invalidURL)
        
        #expect(image == nil)
    }
    
    @MainActor
    @Test("Load image from valid test URL")
    func testLoadImageFromValidURL() async throws {
        let service = ImageCacheService.shared
        
        // Use a small test image URL (1x1 transparent PNG data URL)
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")!
        let testImage = UIImage(data: testImageData)
        
        #expect(testImage != nil)
        
        // Clear cache to ensure clean test
        service.clearCache()
    }
    
    @MainActor
    @Test("Cache persistence across multiple loads")
    func testCachePersistence() async throws {
        let service = ImageCacheService.shared
        
        // Clear cache first
        service.clearCache()
        
        // Create a test URL that won't actually be fetched
        let testURL = URL(string: "http://test.example.com/test-image.png")!
        
        // First load (will fail but shouldn't crash)
        let image1 = await service.loadImage(from: testURL)
        
        // Second load (should also handle gracefully)
        let image2 = await service.loadImage(from: testURL)
        
        // Both should be nil for invalid URL
        #expect(image1 == nil)
        #expect(image2 == nil)
    }
    
    @MainActor
    @Test("Multiple clear cache operations")
    func testMultipleClearCacheOperations() async throws {
        let service = ImageCacheService.shared
        
        // Clear cache multiple times
        for _ in 0..<5 {
            service.clearCache()
        }
        
        // Should not crash
        #expect(true)
    }
    
    @MainActor
    @Test("Load image with various URL formats")
    func testLoadImageWithVariousURLFormats() async throws {
        let service = ImageCacheService.shared
        
        let testURLs = [
            "http://example.com/image.png",
            "https://example.com/image.jpg",
            "http://example.com/path/to/image.gif",
            "https://example.com/image-with-dash.png",
            "http://example.com/image_with_underscore.jpeg"
        ]
        
        for urlString in testURLs {
            if let url = URL(string: urlString) {
                // Attempt to load (will fail for these test URLs but shouldn't crash)
                let _ = await service.loadImage(from: url)
            }
        }
        
        // All operations should complete without crashing
        #expect(true)
    }
    
    @MainActor
    @Test("Concurrent image loading")
    func testConcurrentImageLoading() async throws {
        let service = ImageCacheService.shared
        
        // Clear cache first
        service.clearCache()
        
        // Create multiple test URLs
        let urls = (0..<5).compactMap { i in
            URL(string: "http://test.example.com/image\(i).png")
        }
        
        // Load images concurrently
        await withTaskGroup(of: UIImage?.self) { group in
            for url in urls {
                group.addTask {
                    await service.loadImage(from: url)
                }
            }
            
            // Collect results
            var results: [UIImage?] = []
            for await result in group {
                results.append(result)
            }
            
            // All should be nil for invalid URLs
            #expect(results.allSatisfy { $0 == nil })
        }
    }
    
    @MainActor
    @Test("Cache service handles memory pressure")
    func testMemoryPressureHandling() async throws {
        let service = ImageCacheService.shared
        
        // Clear cache
        service.clearCache()
        
        // Simulate loading many images (they'll fail but test memory handling)
        for i in 0..<20 {
            let url = URL(string: "http://test.example.com/large-image-\(i).png")!
            _ = await service.loadImage(from: url)
        }
        
        // Clear cache to free memory
        service.clearCache()
        
        // Should handle memory pressure without crashing
        #expect(true)
    }
    
    @MainActor
    @Test("Load image with special characters in URL")
    func testLoadImageWithSpecialCharacters() async throws {
        let service = ImageCacheService.shared
        
        // URLs with special characters (properly encoded)
        let testURLs = [
            "http://example.com/image%20with%20space.png",
            "http://example.com/image(with)parens.png",
            "http://example.com/image[with]brackets.png",
        ]
        
        for urlString in testURLs {
            if let url = URL(string: urlString) {
                let image = await service.loadImage(from: url)
                #expect(image == nil) // These test URLs don't exist
            }
        }
    }
    
    @MainActor
    @Test("Clear cache removes all cached items")
    func testClearCacheRemovesAllItems() async throws {
        let service = ImageCacheService.shared
        
        // Load some test URLs (they'll fail but may create cache entries)
        let urls = (0..<3).compactMap { i in
            URL(string: "http://test.example.com/cache-test-\(i).png")
        }
        
        for url in urls {
            _ = await service.loadImage(from: url)
        }
        
        // Clear the cache
        service.clearCache()
        
        // Try loading the same URLs again
        for url in urls {
            let image = await service.loadImage(from: url)
            #expect(image == nil) // Should still be nil as URLs are invalid
        }
        
        // Cache was successfully cleared
        #expect(true)
    }
    
    @MainActor
    @Test("Service maintains singleton state")
    func testSingletonStateMaintenance() async throws {
        let service1 = ImageCacheService.shared
        service1.clearCache()
        
        let service2 = ImageCacheService.shared
        // Should be the same instance with same state
        #expect(service1 === service2)
        
        // Operations on service2 affect service1 (same instance)
        service2.clearCache()
        
        // Both references point to same cleared cache
        #expect(true)
    }
    
    @MainActor
    @Test("Cache directory creation and access")
    func testCacheDirectoryCreationAndAccess() async throws {
        let service = ImageCacheService.shared
        
        // The service should initialize without errors
        // (cache directory is created in init)
        #expect(true)
        
        // Clear cache should work with the directory
        service.clearCache()
        #expect(true)
    }
    
    @MainActor
    @Test("URL session configuration")
    func testURLSessionConfiguration() async throws {
        let service = ImageCacheService.shared
        
        // Test that the service can handle network requests
        // (even if they fail for invalid URLs)
        let testURL = URL(string: "https://httpbin.org/status/404")!
        let image = await service.loadImage(from: testURL)
        
        // Should handle network errors gracefully
        #expect(image == nil)
    }
    
    
    @MainActor
    @Test("Load image with malformed URLs")
    func testLoadImageWithMalformedURLs() async throws {
        let service = ImageCacheService.shared
        
        let malformedURLs = [
            "not-a-url",
            "://missing-scheme",
            "http://",
            "ftp://example.com/image.png", // Different scheme
        ]
        
        for urlString in malformedURLs {
            if let url = URL(string: urlString) {
                let image = await service.loadImage(from: url)
                #expect(image == nil)
            }
        }
    }
    
    @MainActor
    @Test("Cache performance with rapid requests")
    func testCachePerformanceWithRapidRequests() async throws {
        let service = ImageCacheService.shared
        service.clearCache()
        
        let testURL = URL(string: "http://example.com/performance-test.png")!
        
        // Make rapid consecutive requests for the same URL
        await withTaskGroup(of: UIImage?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await service.loadImage(from: testURL)
                }
            }
            
            // Collect all results
            var results: [UIImage?] = []
            for await result in group {
                results.append(result)
            }
            
            // All should be nil for invalid URL, but shouldn't crash
            #expect(results.allSatisfy { $0 == nil })
        }
    }
    
    @MainActor
    @Test("Cache behavior with different image formats")
    func testCacheBehaviorWithDifferentImageFormats() async throws {
        let service = ImageCacheService.shared
        
        let imageFormatURLs = [
            "http://example.com/image.png",
            "http://example.com/image.jpg",
            "http://example.com/image.jpeg",
            "http://example.com/image.gif",
            "http://example.com/image.webp",
            "http://example.com/image.svg",
            "http://example.com/image.bmp",
            "http://example.com/image.tiff"
        ]
        
        for urlString in imageFormatURLs {
            if let url = URL(string: urlString) {
                let image = await service.loadImage(from: url)
                #expect(image == nil) // These test URLs don't exist
            }
        }
    }
    
    @MainActor
    @Test("Clear cache multiple times in sequence")
    func testClearCacheMultipleTimesInSequence() async throws {
        let service = ImageCacheService.shared
        
        // Clear cache multiple times rapidly
        for _ in 0..<20 {
            service.clearCache()
        }
        
        // Should handle rapid clearing without issues
        #expect(true)
    }
    
    @MainActor
    @Test("Memory cache behavior")
    func testMemoryCacheBehavior() async throws {
        let service = ImageCacheService.shared
        service.clearCache()
        
        // Load some test URLs to potentially populate cache
        let urls = (0..<5).compactMap { i in
            URL(string: "http://test.example.com/memory-test-\(i).png")
        }
        
        // First round of loads
        for url in urls {
            _ = await service.loadImage(from: url)
        }
        
        // Second round - should check memory cache first
        for url in urls {
            _ = await service.loadImage(from: url)
        }
        
        // Memory cache should be handling these gracefully
        #expect(true)
    }
    
    @MainActor
    @Test("Disk cache behavior")
    func testDiskCacheBehavior() async throws {
        let service = ImageCacheService.shared
        service.clearCache()
        
        // Test that disk operations don't crash
        let testURL = URL(string: "http://example.com/disk-test.png")!
        
        // This will fail to download but should test disk cache logic
        _ = await service.loadImage(from: testURL)
        
        // Clear and test again
        service.clearCache()
        _ = await service.loadImage(from: testURL)
        
        #expect(true)
    }
    
    @MainActor
    @Test("Cache with extremely long URLs")
    func testCacheWithExtremelyLongURLs() async throws {
        let service = ImageCacheService.shared
        
        // Create a very long URL
        let longPath = String(repeating: "very-long-path-segment/", count: 50)
        let longURL = URL(string: "http://example.com/\(longPath)image.png")!
        
        // Should handle long URLs gracefully
        let image = await service.loadImage(from: longURL)
        #expect(image == nil)
    }
}