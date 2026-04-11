//
//  PhotosetsRepository.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation


protocol PhotosetsRepository {
    func getPhotosets() async throws -> [Photoset]
}

struct PhotosetModel {
    let id: Int
    let name: String
    let created: Int
    let cover_index: Int?
    let photos: [String]
    
    var coverUrl: String? {
        cover_index.map { photos[$0] }
    }

}

final class MockPhotosetsRepository {
//    private static let mocks2 = {
//        PhotosetModel.items.map {
//            let approved = Int.random(in: 0...$0.photos.count)
//            let rejected = Int.random(in: 0...$0.photos.count - approved)
//
//            return Photoset(
//                id: PhotosetId(),
//                name: $0.name,
//                remotePath: "https://vk.com/album-100568944_\($0.id)",
//                syncStatus: .synced,
//                lastSyncDate: Date(),
//                createdAt: Date(timeIntervalSince1970: TimeInterval($0.created)),
//                coverImageURL: $0.coverUrl.flatMap { URL(string: $0) },
//                photosCount: $0.photos.count,
//                approvedCount: approved,
//                rejectedCount: rejected,
//                photos: $0.photos.compactMap {
//                    URL(string: $0)
//                },
//            )
//        }
//    }()

//    private static let mockPhotosets: [Photoset] = [
//        Photoset(
//            id: PhotosetId(),
//            name: "Wedding at Lake Como",
//            remotePath: "/photosets/wedding-como",
//            syncStatus: .synced,
//            lastSyncDate: Date().addingTimeInterval(-3600),
//            createdAt: Date().addingTimeInterval(-86400 * 7),
//            coverImageURL: URL(string: "https://images.unsplash.com/photo-1519741497674-611481863552?w=800"),
//            photosCount: 342,
//            approvedCount: 128,
//            rejectedCount: 89
//        ),
//        Photoset(
//            id: PhotosetId(),
//            name: "Corporate Event - Tech Summit 2024",
//            remotePath: "/photosets/tech-summit",
//            syncStatus: .pending,
//            lastSyncDate: Date().addingTimeInterval(-1800),
//            createdAt: Date().addingTimeInterval(-86400 * 3),
//            coverImageURL: URL(string: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800"),
//            photosCount: 156,
//            approvedCount: 42,
//            rejectedCount: 18
//        ),
//        Photoset(
//            id: PhotosetId(),
//            name: "Fashion Editorial - Spring Collection",
//            remotePath: "/photosets/spring-fashion",
//            syncStatus: .synced,
//            lastSyncDate: Date().addingTimeInterval(-7200),
//            createdAt: Date().addingTimeInterval(-86400 * 14),
//            coverImageURL: URL(string: "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800"),
//            photosCount: 289,
//            approvedCount: 234,
//            rejectedCount: 55
//        ),
//        Photoset(
//            id: PhotosetId(),
//            name: "Architecture Tour - Barcelona",
//            remotePath: "/photosets/barcelona-arch",
//            syncStatus: .error,
//            lastSyncDate: Date().addingTimeInterval(-14400),
//            createdAt: Date().addingTimeInterval(-86400 * 2),
//            coverImageURL: URL(string: "https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800"),
//            photosCount: 412,
//            approvedCount: 89,
//            rejectedCount: 34
//        ),
//        Photoset(
//            id: PhotosetId(),
//            name: "Product Photography - Watches",
//            remotePath: "/photosets/watches",
//            syncStatus: .synced,
//            lastSyncDate: Date().addingTimeInterval(-28800),
//            createdAt: Date().addingTimeInterval(-86400 * 21),
//            coverImageURL: URL(string: "https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=800"),
//            photosCount: 67,
//            approvedCount: 67,
//            rejectedCount: 0
//        ),
//        Photoset(
//            id: PhotosetId(),
//            name: "Street Photography - Tokyo Nights",
//            remotePath: "/photosets/tokyo-streets",
//            syncStatus: .synced,
//            lastSyncDate: Date().addingTimeInterval(-43200),
//            createdAt: Date().addingTimeInterval(-86400 * 5),
//            coverImageURL: URL(string: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800"),
//            photosCount: 523,
//            approvedCount: 178,
//            rejectedCount: 145
//        ),
//        Photoset(
//            id: PhotosetId(),
//            name: "Nature & Wildlife - Safari",
//            remotePath: "/photosets/safari",
//            syncStatus: .pending,
//            lastSyncDate: nil,
//            createdAt: Date().addingTimeInterval(-86400),
//            coverImageURL: URL(string: "https://images.unsplash.com/photo-1516426122078-c23e76319801?w=800"),
//            photosCount: 892,
//            approvedCount: 0,
//            rejectedCount: 0
//        )
//    ]
}

extension MockPhotosetsRepository: PhotosetsRepository {
    func getPhotosets() async throws -> [Photoset] {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

//        return MockPhotosetsRepository.mocks2
        return []
    }
}
