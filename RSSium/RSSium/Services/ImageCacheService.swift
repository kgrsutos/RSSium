import Foundation
import SwiftUI
import Combine

// MARK: - Image Cache Service
@MainActor
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, CachedImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let session: URLSession
    
    private init() {
        // Configure cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Setup cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure URLSession with aggressive caching
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,  // 10MB memory cache
            diskCapacity: 50 * 1024 * 1024,    // 50MB disk cache
            diskPath: "ImageCache"
        )
        session = URLSession(configuration: configuration)
        
        // Clean old cache on startup
        Task {
            await cleanOldCache()
        }
    }
    
    func loadImage(from url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        
        // Check memory cache
        if let cached = cache.object(forKey: key) {
            return cached.image
        }
        
        // Check disk cache
        if let diskImage = loadFromDisk(url: url) {
            // Store in memory cache
            cache.setObject(CachedImage(image: diskImage), forKey: key, cost: diskImage.pngData()?.count ?? 0)
            return diskImage
        }
        
        // Download image
        do {
            let (data, _) = try await session.data(from: url)
            if let image = UIImage(data: data) {
                // Save to caches
                await saveToDisk(image: image, url: url)
                cache.setObject(CachedImage(image: image), forKey: key, cost: data.count)
                return image
            }
        } catch {
            print("Failed to load image from \(url): \(error)")
        }
        
        return nil
    }
    
    private func loadFromDisk(url: URL) -> UIImage? {
        let filename = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveToDisk(image: UIImage, url: URL) async {
        let filename = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = image.pngData() {
            try? data.write(to: fileURL)
        }
    }
    
    private func cleanOldCache() async {
        let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        let now = Date()
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }
        
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let creationDate = attributes[.creationDate] as? Date,
               now.timeIntervalSince(creationDate) > maxAge {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// MARK: - Cached Image Wrapper
private class CachedImage {
    let image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
}

// MARK: - AsyncImage with Cache
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url, image == nil else { return }
        
        isLoading = true
        image = await ImageCacheService.shared.loadImage(from: url)
        isLoading = false
    }
}