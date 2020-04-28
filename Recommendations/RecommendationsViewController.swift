//
//  ViewController.swift
//  Recommendations
//

import UIKit
import OHHTTPStubs

struct Root: Codable {
    var titles: [Recommendation]
    var skipped: [String]
    var titlesOwned: [String]
    
    enum CodingKeys: String, CodingKey {
        case titles
        case skipped
        case titlesOwned = "titles_owned"
    }
}

struct Recommendation: Codable {
    let imageURL: String
    let title: String
    let tagline: String
    let rating: Float?
    let isReleased: Bool
    
    enum CodingKeys: String, CodingKey {
        case imageURL = "image"
        case title
        case tagline
        case rating
        case isReleased = "is_released"
    }
}

class RecommendationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var recommendations = [Recommendation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ---------------------------------------------------
        // -------- <DO NOT MODIFY INSIDE THIS BLOCK> --------
        // stub the network response with our local ratings.json file
        let stub = Stub()
        stub.registerStub()
        // -------- </DO NOT MODIFY INSIDE THIS BLOCK> -------
        // ---------------------------------------------------
        
        tableView.register(UINib(nibName: "RecommendationTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        // NOTE: please maintain the stubbed url we use here and the usage of
        // a URLSession dataTask to ensure our stubbed response continues to
        // work; however, feel free to reorganize/rewrite/refactor as needed
        guard let url = URL(string: Stub.stubbedURL_doNotChange) else { fatalError() }
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let receivedData = data else { return }
            
            let jsonDecoder = JSONDecoder()
            
            do {
                let root = try jsonDecoder.decode(Root.self, from: receivedData)
                
                let filteredRecommendations = self.filteredAndSortedRecommendationsFrom(root)
                
                self.recommendations = filteredRecommendations
            } catch let error {
                fatalError(error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        });

        task.resume()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecommendationTableViewCell
                
        let recommendation = recommendations[indexPath.row]

        cell.titleLabel.text = recommendation.title
        cell.taglineLabel.text = recommendation.tagline
        cell.ratingLabel.text = "Rating: \(recommendation.rating ?? 0.0)"
        
        DispatchQueue.global().async {
            if let url = URL(string: recommendation.imageURL) {
                let data = try? Data(contentsOf: url)

                if let imageData = data {
                    let image = UIImage(data: imageData)
                    DispatchQueue.main.async {
                        cell.recommendationImageView?.image = image
                    }
                }
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recommendations.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    private func filteredAndSortedRecommendationsFrom(_ root: Root) -> [Recommendation] {
        let filteredByReleased = root.titles.filter { $0.isReleased }
        let filteredBySkipped = filteredByReleased.filter { !root.skipped.contains($0.title) }
        let filteredByOwned = filteredBySkipped.filter { !root.titlesOwned.contains($0.title) }
        let sorted = filteredByOwned.sorted { $0.rating ?? 0.0 > $1.rating ?? 0.0 }
        
        let topTen = Array(sorted.prefix(10))
        
        return topTen
        
    }
}
