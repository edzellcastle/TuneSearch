//
//  DetailViewController.swift
//  TuneSearch
//
//  Created by David Lindsay on 5/22/17.
//  Copyright © 2017 Tapinfuse. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var collectionNameLabel: UILabel!
    @IBOutlet weak var collectionImageView: UIImageView!
    @IBOutlet weak var lyricsTextView: UITextView!
    
    @IBOutlet weak var playButton: UIButton!
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = trackNameLabel {
                label.text = detail.trackName
            }
            if let label = artistNameLabel {
                label.text = detail.artistName
            }
            if let label = collectionNameLabel {
                label.text = detail.collectionName
            }
            if let imageLink = detail.albumImageLarge {
                if let checkedUrl = URL(string: imageLink) {
                    downloadImage(url: checkedUrl)
                }
            }
            if let artistName = detail.artistName, let trackName = detail.trackName{
                let artist = artistName.replacingOccurrences(of: " ", with: "+")
                let track = trackName.replacingOccurrences(of: " ", with: "+")
                let endPoint = "\(wikiaEndpoint)&artist=\(artist)&song=\(track)&fmt=realjson"
                let httpGetRequest = HTTPGetRequest(httpEndPointString: endPoint)
                
                let task = httpGetRequest.session?.dataTask(with: httpGetRequest.request! as URLRequest, completionHandler: {
                    (data, response, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                    } else {
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! NSDictionary
                                let dictionary = json
                                    if let lyrics = dictionary.value(forKey: "lyrics") as! String? {
                                        DispatchQueue.main.async(execute: { self.lyricsTextView.text = lyrics })
                                    }
                            } catch {
                                print("json error: \(error)")
                            }
                        }
                    }
                })
                task?.resume()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadImage(url: URL) {
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() { () -> Void in
                self.collectionImageView.image = UIImage(data: data)
            }
        }
    }

    @IBAction func playButtonAction(_ sender: Any) {
        
       // play the sample
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: TrackData? {
        didSet {
            // Update the view.
            configureView()
        }
    }


}

