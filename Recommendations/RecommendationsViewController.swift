//
//  ViewController.swift
//  Recommendations
//

import UIKit
import OHHTTPStubs

struct RootObject: Codable {
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
    
    static let recommendationsFileName = "recommendations.json"
    
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
        
        loadRecommendationsFromStorage()
        
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
                let rootObject = try jsonDecoder.decode(RootObject.self, from: receivedData)
                self.recommendations = self.filteredAndSortedRecommendationsFrom(rootObject)
                self.saveRecommendationsToStorage()
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
        cell.activityIndicator.hidesWhenStopped = true
        cell.activityIndicator.startAnimating()
        
        DispatchQueue.global().async {
            if let url = URL(string: recommendation.imageURL) {
                let data = try? Data(contentsOf: url)

                if let imageData = data {
                    let image = UIImage(data: imageData)
                    DispatchQueue.main.async {
                        cell.recommendationImageView?.image = image
                        cell.activityIndicator.stopAnimating()
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
    
    /// Filters and sorts an array of Recommendations to create the top ten.
    /// Filters out already-owned, previously-skipped, and unreleasedSorts and filters  titles.
    /// Sorts in descending order by rating.
    /// - Parameter rootObject: a root object parsed from JSON
    /// - Returns: A filtered and sorted top ten list of Recommendations
    private func filteredAndSortedRecommendationsFrom(_ rootObject: RootObject) -> [Recommendation] {
        let filteredByReleased = rootObject.titles.filter { $0.isReleased }
        let filteredBySkipped = filteredByReleased.filter { !rootObject.skipped.contains($0.title) }
        let filteredByOwned = filteredBySkipped.filter { !rootObject.titlesOwned.contains($0.title) }
        let sorted = filteredByOwned.sorted { $0.rating ?? 0.0 > $1.rating ?? 0.0 }
        
        let topTen = Array(sorted.prefix(10))
        
        return topTen
    }
    
    /// Attempts to load an aray of Recomendations from the documents directory and
    /// uses it as the recommendations property
    private func loadRecommendationsFromStorage() {
        let jsonDecoder = JSONDecoder()
        if var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            url.appendPathComponent(RecommendationsViewController.recommendationsFileName)
            do {
                let data = try Data(contentsOf: url)
                let object = try jsonDecoder.decode(Array<Recommendation>.self, from: data)
                self.recommendations = object
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    /// Attempts to save the current recommendations property to the documents directory
    private func saveRecommendationsToStorage() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recommendations) {
            if var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                url.appendPathComponent(RecommendationsViewController.recommendationsFileName)
                do {
                    try encoded.write(to: url)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
