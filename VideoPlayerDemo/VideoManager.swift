//
//  VideoManager.swift
//  VideoPlayerDemo
//
//  Created by Clarissa Calderon on 4/10/23.
//

import Combine
import Foundation

enum Query: String, CaseIterable {
    case nature, animals, people, ocean, food
}

class VideoManager: ObservableObject {
    
    @Published private(set) var videos: [Video] = []
    @Published var selectedQuery: Query = .nature
    
    init() {
        $selectedQuery
            .removeDuplicates()
            .await { query in
                await self.findVideos(topic: query)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .assign(to: &$videos)
    }
    
    func findVideos(topic: Query) async -> [Video] {
        guard let url = URL(string: "https://api.pexels.com/videos/search?query=\(topic)&per_page=10&orientation=portrait"
) else { fatalError("Missing URL") }
        
        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue(Constants.pexelApiKey, forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200  else { fatalError("Error while fetching data") }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedData = try decoder.decode(ResponseBody.self, from: data)
            
            return decodedData.videos
        } catch {
            print("Error fetching data from Pexel: \(error)")
            return []
        }
    }
}

extension Publisher {
    func `await`<T>(_ transform: @escaping (Output) async -> T) -> AnyPublisher<T, Failure> {
        flatMap { value -> Future<T, Failure> in
            Future { promise in
                Task {
                    let result = await transform(value)
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
