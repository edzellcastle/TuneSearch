//
//  HTTPGetRequest.swift
//  TuneSearch
//
//  Created by David Lindsay on 5/22/17.
//  Copyright © 2017 Tapinfuse. All rights reserved.
//

import Foundation

class HTTPGetRequest : URLSession {
    var session: URLSession? = nil
    var request: NSMutableURLRequest? = nil
    var url: URL? = nil
    
    init(httpEndPointString: String) {

        if let encoded = httpEndPointString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
            let url = URL(string: encoded)
        {
            self.url = url
            self.request = NSMutableURLRequest(url: url)
            self.request?.httpMethod = "GET"
            let config = URLSessionConfiguration.default
            self.session = URLSession(configuration: config)
        }
    }
}
