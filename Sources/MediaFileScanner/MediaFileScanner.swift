// The Swift Programming Language
// https://docs.swift.org/swift-book

import Combine
import Foundation

import FileScanAbstraction

public final class FileScannerService: FileScannerProtocol {
    let queue = DispatchQueue(label: "com.filescanner.callbackQueue_\(UUID().uuidString)", attributes: .concurrent)
    
    public func scanForMediaFiles(path: URL, extensions: [String]) -> AsyncStream<Result<URL, FileScannerError>> {
        AsyncStream { continuation in
            self.scanForFiles(path, extensions) { result in
                _ = result.mapError {
                    continuation.yield(.failure($0))
                    return $0
                }
                .map { continuation.yield(.success($0)) }
            }
            continuation.finish()
        }
    }

    private func scanForFiles(
        _ path: URL,
        _ extensions: [String],
        _ completion: @Sendable @escaping (Result<URL, FileScannerError>) -> Void) {
        Task {
            let enumerator = FileManager.default.enumerator(
                at: path,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) { url, error in
                print("Found file at \(url) with error: \(error.localizedDescription)")
                return true
            }
            
            guard let enumerator = enumerator else {
                completion(.failure(.fileEnumeratorFailed))
                return
            }
            
            for case let fileURL as URL in enumerator {
                if extensions.contains(fileURL.pathExtension.lowercased()) {
                    completion(.success(fileURL))
                }
            }
        }
    }
}

