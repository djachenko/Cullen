//
//  Photo.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation

typealias PhotoId = String

struct Photo: Identifiable, Hashable {
    let id: PhotoId
    let url: URL
}
