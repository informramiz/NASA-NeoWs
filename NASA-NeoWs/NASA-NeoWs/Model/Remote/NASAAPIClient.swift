//
//  NASAAPIClient.swift
//  NASA-NeoWs
//
//  Created by Apple on 16/03/2020.
//  Copyright © 2020 RR Inc. All rights reserved.
//

import Foundation
class NASAAPIClient {
    static let apiKey = "cmPeNpKaH2oeNUfqFhfnWenrwMk6fBe3q9E09fSu"
    
    enum EndPoints {
        static let baseUrl = "https://api.nasa.gov/neo/rest/v1/"
        static let apiKey = "api_key=\(NASAAPIClient.apiKey)"
        case getFeed(startDate: String?, endDate: String?)
        case search(neoReferenceId: Int64)
        
        var stringValue: String {
            switch self {
            case .getFeed(let startDate, let endDate):
                return EndPoints.baseUrl + "feed?&start_date=\(startDate ?? "")&end_date=\(endDate ?? "")&" + EndPoints.apiKey
                case .search(let neoReferenceId):
                    return EndPoints.baseUrl + "neo/\(neoReferenceId)?" + EndPoints.apiKey
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func search(neoReferenceId: Int64,
                      successHandler: @escaping (_ asteriods: [Asteriod]) -> Void,
                      errorHandler: @escaping (_ error: Error) -> Void) -> URLSessionTask {
        return taskForGetRequest(url: EndPoints.search(neoReferenceId: neoReferenceId).url,
                          responseType: Asteriod.self,
                          successHandler: { data in
                            successHandler([data])
                            },errorHandler: errorHandler)
    }
    
    @discardableResult
    class func getAsteriodFeed(startDate: String? = nil, endData: String? = nil,
                               successHandler: @escaping (_ asteriods: Asteriods) -> Void,
                               errorHandler: @escaping (_ error: Error) -> Void) -> URLSessionTask {
        return taskForGetRequest(url: EndPoints.getFeed(startDate: startDate, endDate: endData).url, responseType: Asteriods.self,
                          successHandler: successHandler, errorHandler: errorHandler)
    }
    
    @discardableResult
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type,
                                                          successHandler: @escaping (_ response: ResponseType) -> Void,
                                                          errorHandler: @escaping (_ error: Error) -> Void) -> URLSessionDataTask {
        print("GET: \(url.absoluteString)")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            handleResponse(data: data, error: error, responseType: responseType, successHandler: successHandler, errorHandler: errorHandler)
        }
        task.resume()
        return task
    }
    
    class func handleResponse<ResponseType: Decodable>(data: Data?, error: Error?, responseType: ResponseType.Type,
                                                       successHandler: @escaping (_ response: ResponseType) -> Void,
                                                       errorHandler: @escaping (_ error: Error) -> Void) {
        guard let data = data else {
            onMain {
                errorHandler(error!)
            }
            return
        }
        
        do {
            print("Response: " + String(data: data, encoding: .utf8)!)
            let response = try JSONDecoder().decode(responseType, from: data)
            onMain {
                successHandler(response)
            }
        } catch {
            let parsedError = parseError(data: data)
            onMain {
                errorHandler(parsedError)
            }
        }
    }
    
    private class func parseError(data: Data) -> Error {
        do {
            return try JSONDecoder().decode(ErrorResponse.self, from: data)
        } catch {
            return error
        }
    }
    
    private class func onMain(block: @escaping () -> Void) {
        DispatchQueue.main.async {
            block()
        }
    }
}
