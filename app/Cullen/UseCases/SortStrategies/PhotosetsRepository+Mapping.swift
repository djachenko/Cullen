//
//  PhotosetsRepository+Mapping.swift
//  Cullen
//

extension PhotosetsRepository {
    // Сортировка по полю фотосета требует всех разом — тянем параллельно и
    // раскладываем по id, чтобы ключ доставался за константу.
    func photosets(ids: [PhotosetId]) async throws -> [PhotosetId: Photoset] {
        try await withThrowingTaskGroup(of: Photoset.self) { group in
            for id in ids {
                group.addTask { try await self.getPhotoset(id: id) }
            }

            var result: [PhotosetId: Photoset] = [:]

            for try await photoset in group {
                result[photoset.id] = photoset
            }

            return result
        }
    }
}
