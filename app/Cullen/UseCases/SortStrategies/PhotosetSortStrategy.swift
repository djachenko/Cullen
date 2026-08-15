//
//  PhotosetSortStrategy.swift
//  Cullen
//
//  Domain - одна опция сортировки ленты. Стратегия владеет только своим
//  источником ключа; механика сравнения общая и живёт в Collection.sorted.
//

protocol PhotosetSortStrategy {
    func sorted(ids: [PhotosetId], isAscending: Bool) async throws -> [PhotosetId]
}
