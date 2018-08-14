//
//  TrackResponse.swift
//  TuneSearch
//
//  Created by David Lindsay on 8/10/18.
//  Copyright © 2018 Tapinfuse. All rights reserved.
//

import Foundation

struct TrackResponse: Decodable {
    var resultCount: Int
    var results: [Track]
}
