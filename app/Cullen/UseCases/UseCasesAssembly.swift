//
//  UseCasesAssembly.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Swinject
import SwinjectAutoregistration


final class UseCasesAssembly: Assembly {
    // One sync per photoset, shared while any screen holds it. Captured by the
    // registration below, so it lives as long as the container does.
    private let photosetSyncs = WeakValueMap<PhotosetId, PhotosetSyncUseCaseImpl>()

    func assemble(container: Container) {
        container.autoregister(FetchPhotosetsUseCase.self, initializer: FetchPhotosetsUseCaseImpl.init)
        container.autoregister(SortPhotosetsUseCase.self, initializer: SortPhotosetsUseCaseImpl.init)
        assembleSortStrategies(container: container)
        container.autoregister(RecordLastOpenedUseCase.self, initializer: RecordLastOpenedUseCaseImpl.init)
        container.autoregister(FetchPhotosetUseCase.self, initializer: FetchPhotosetUseCaseImpl.init)
        container.autoregister(GetPhotosetStatisticsUseCase.self, initializer: GetPhotosetStatisticsUseCaseImpl.init)
        container.autoregister(FetchPhotosUseCase.self, initializer: FetchPhotosUseCaseImpl.init)
        container.autoregister(ExportDecisionsUseCase.self, initializer: ExportDecisionsUseCaseImpl.init)
        container.autoregister(DecisionsStatsUseCase.self, initializer: DecisionsStatsUseCaseImpl.init)
        container.autoregister(ExportLogsUseCase.self, initializer: ExportLogsUseCaseImpl.init)

        container.autoregister(DecisionsUseCaseImpl.init)
            .inObjectScope(.container) // shared state: decisions cache is shared across screens
            .implements(SaveDecisionUseCase.self)
            .implements(LoadDecisionsUseCase.self)

        // PhotosetId comes from the child container (ParaMap), so a screen just
        // asks for PhotosetSyncUseCase and gets the one belonging to its photoset.
        container.register(PhotosetSyncUseCase.self) { resolver in
            self.sync(for: resolver ~> PhotosetId.self, resolver: resolver)
        }

        container.register(ResumeOfflineSyncUseCase.self) { resolver in
            ResumeOfflineSyncUseCaseImpl(
                desiredStore: resolver ~> DesiredSyncStore.self,
                syncProvider: { self.sync(for: $0, resolver: resolver) }
            )
        }
    }
}


private extension UseCasesAssembly {
    typealias Option = PhotosetSortOption

    func assembleSortStrategies(container: Container) {
        let strategy = PhotosetSortStrategy.self

        container.autoregister(strategy, key: Option.recent, initializer: RecentSortStrategy.init)
        container.autoregister(strategy, key: Option.name, initializer: NameSortStrategy.init)
        container.autoregister(strategy, key: Option.progress, initializer: ProgressSortStrategy.init)
        container.autoregister(strategy, key: Option.photoCount, initializer: PhotoCountSortStrategy.init)
        container.autoregister(strategy, key: Option.lastOpened, initializer: LastOpenedSortStrategy.init)
        container.autoregister(strategy, key: Option.syncProgress, initializer: SyncProgressSortStrategy.init)

        // Таблица строится по allCases: незарегистрированная опция роняет резолв
        // на первом открытии ленты, а не молча выпадает из меню сортировки.
        container.register([PhotosetSortOption: PhotosetSortStrategy].self) { resolver in
            let entries = PhotosetSortOption.allCases.map { option -> (PhotosetSortOption, PhotosetSortStrategy) in
                (option, resolver ~> option)
            }

            return Dictionary(uniqueKeysWithValues: entries)
        }
    }

    func sync(for id: PhotosetId, resolver: Resolver) -> PhotosetSyncUseCase {
        photosetSyncs.value(for: id) {
            PhotosetSyncUseCaseImpl(
                photosetId: id,
                downloadService: resolver ~> ImageDownloadService.self,
                cacheService: resolver ~> ImageCacheService.self,
                eventSource: resolver ~> SyncEventSource.self,
                photosetsRepository: resolver ~> PhotosetsRepository.self,
                desiredStore: resolver ~> DesiredSyncStore.self,
                cachedRatioStore: resolver ~> CachedRatioStore.self
            )
        }
    }
}


// Ключ регистрации, а не строковое имя: hash/== ключа берут опцию как есть.
extension PhotosetSortOption: ServiceKeyOption {
    public var description: String {
        rawValue
    }

    public func isEqualTo(_ another: ServiceKeyOption) -> Bool {
        another as? Self == self
    }
}
