@testable import Hub
import XCTest

class HubCacheTests: XCTestCase {
    var downloadDestination: URL!
    let repo = "coreml-projects/Llama-2-7b-chat-coreml"
    var hubApi: HubAPI!
    
    override func setUp() {
        super.setUp()
        downloadDestination = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appending(component: "huggingface-cache-tests-\(UUID().uuidString)")
        hubApi = HubAPI(downloadBase: downloadDestination)
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: downloadDestination)
    }
    
    func getFileCreationDate(at path: URL) throws -> Date {
        let attrs = try FileManager.default.attributesOfItem(atPath: path.path)
        return attrs[.creationDate] as! Date
    }
    
    func getRepoPath() -> URL {
        return downloadDestination.appending(path: "models/\(repo)")
    }
    
    func getFilePath(_ filename: String) -> URL {
        return getRepoPath().appending(path: filename)
    }

    func testCacheHitAndMiss() async throws {
        let configPath = getFilePath("config.json")
        
        // First download
        _ = try await hubApi.snapshot(from: repo, matching: "config.json")
        let firstDownloadDate = try getFileCreationDate(at: configPath)
        
        // Second download should use cache (file creation date shouldn't change)
        _ = try await hubApi.snapshot(from: repo, matching: "config.json")
        let secondDownloadDate = try getFileCreationDate(at: configPath)
        
        XCTAssertEqual(firstDownloadDate, secondDownloadDate, 
            "Second download should use cache (creation dates should match)")
        
        // Delete downloaded file to force re-download
        try FileManager.default.removeItem(at: configPath)
        
        // Third download should create a new file
        _ = try await hubApi.snapshot(from: repo, matching: "config.json")
        let thirdDownloadDate = try getFileCreationDate(at: configPath)
        
        XCTAssertGreaterThan(thirdDownloadDate, secondDownloadDate, 
            "After cache invalidation, should download new file")
    }
    
    func testConcurrentDownloads() async throws {
        // Start multiple concurrent downloads of the same file
        async let download1 = hubApi.snapshot(from: repo, matching: "config.json")
        async let download2 = hubApi.snapshot(from: repo, matching: "config.json")
        async let download3 = hubApi.snapshot(from: repo, matching: "config.json")
        
        // Wait for all downloads to complete
        let results = try await [download1, download2, download3]
        
        // All results should point to same path
        XCTAssertEqual(
            Set(results.map { $0.path }),
            Set([getRepoPath().path]),
            "All concurrent downloads should resolve to the same location"
        )
    }
}