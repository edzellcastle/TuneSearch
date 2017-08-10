//
//  MasterViewController.swift
//  TuneSearch
//
//  Created by David Lindsay on 5/22/17.
//  Copyright © 2017 Tapinfuse. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    let searchController = UISearchController(searchResultsController: nil)
    var task: URLSessionDownloadTask!
    var session: URLSession!
    var imageCache = NSCache<NSString, UIImage>()
   
    @IBOutlet var trackTableView: UITableView!
    
    private var persistentContainer = NSPersistentContainer(name: "TuneSearch")

    var moc: NSManagedObjectContext?
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<TrackData> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<TrackData> = TrackData.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "artistName", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        trackTableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.delegate = self
        
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                print("\(error), \(error.localizedDescription)")
            } else {
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("\(fetchError), \(fetchError.localizedDescription)")
                }
            }
        }
        moc = persistentContainer.viewContext
        session = URLSession.shared
        task = URLSessionDownloadTask()
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        imageCache.removeAllObjects()
    }
    
    // Delete Core Data objects and search iTunes for music
    
    func deleteObjectsAndFetchTunesForSearchText(searchText: String, scope: String = "All") {
        imageCache.removeAllObjects()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackData")
        fetchRequest.includesPropertyValues = false
        do {
            let tracks = try moc?.fetch(fetchRequest) as! [TrackData]
            for track in tracks {
                moc?.delete(track)
            }
            try moc?.save()
            search(text: searchText)
        } catch {
            fatalError("Failed to fetch tracks: \(error)")
        }
    }
    
    // Query iTunes for music
    
    func search(text: String) {
        let searchString = text.replacingOccurrences(of: " ", with: "+")
        
        // create the http request
        let musicSearchEndpoint = iTunesSearchEndpoint + searchString
        let httpGetRequest = HTTPGetRequest(httpEndPointString: musicSearchEndpoint)
        
        let task = httpGetRequest.session?.dataTask(with: httpGetRequest.request! as URLRequest, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                do {
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: []) {
                        print(json)
                        if let dictionary = json as? NSDictionary {
                            if let array = dictionary["results"] as? NSArray {
                                for obj in array {
                                    var artist: String
                                    var track: String
                                    var album: String
                                    var collectionID: String
                                    var albumImageString: String
                                    var albumImageLargeString :String
                                    var previewLink: String
                                    if let dict = obj as? NSDictionary {
                                        if let preview = dict.value(forKey: "previewUrl") as! String? {
                                            previewLink = preview
                                        } else {
                                            previewLink = ""
                                        }
                                        if let artistName = dict.value(forKey: "artistName") as! String? {
                                            artist = artistName
                                        } else {
                                            artist = ""
                                        }
                                        if let trackName = dict.value(forKey: "trackName") as! String? {
                                            track = trackName
                                        } else {
                                            track = ""
                                        }
                                        if let albumName = dict.value(forKey: "collectionName") as! String? {
                                            album = albumName
                                        } else {
                                            album = ""
                                        }
                                        if let collectionIdentification = dict.value(forKey: "collectionId") as? NSNumber {
                                            collectionID = collectionIdentification.stringValue
                                        } else {
                                            collectionID = ""
                                        }
                                        if let albumImageStr = dict.value(forKey: "artworkUrl60") as! String? {
                                            albumImageString = albumImageStr
                                        } else {
                                            albumImageString = ""
                                        }
                                        if let albumImageLargeStr = dict.value(forKey: "artworkUrl100") as! String? {
                                            albumImageLargeString = albumImageLargeStr
                                        } else {
                                            albumImageLargeString = ""
                                        }
                                        self.saveTrackData(artistName: artist,
                                                           trackName: track,
                                                           albumName: album,
                                                           collectionID: collectionID,
                                                           albumImageLink: albumImageString,
                                                           albumImageLargeLink: albumImageLargeString,
                                                           previewLink: previewLink)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        task?.resume()
    }
    
    // Create a new TrackData object in the managed object context and save it to the persistent container.
    
    func saveTrackData(artistName: String, trackName: String, albumName: String,
                       collectionID: String,
                       albumImageLink: String,
                       albumImageLargeLink: String,
                       previewLink: String) {
        let trackData = NSEntityDescription.insertNewObject(forEntityName: "TrackData", into: moc!) as! TrackData
        
        trackData.setValue(artistName, forKeyPath: "artistName")
        trackData.setValue(trackName, forKeyPath: "trackName")
        trackData.setValue(albumName, forKeyPath: "collectionName")
        trackData.setValue(collectionID, forKeyPath: "collectionID")
        trackData.setValue(albumImageLink, forKeyPath: "albumImage")
        trackData.setValue(albumImageLargeLink, forKeyPath: "albumImageLarge")
        trackData.setValue(previewLink, forKeyPath: "sampleLink")
        
        do {
            if persistentContainer.viewContext.hasChanges {
                do {
                    try persistentContainer.viewContext.save()
                } catch {
                    print("An error occurred while saving view context: \(error)")
                }
            }
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = trackTableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View
    
    func tableView (tableView: UITableView, heightForHeaderInSection section:Int) -> Float {
        return 20.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let songs = fetchedResultsController.fetchedObjects else { return 0 }
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.reuseIdentifier, for: indexPath) as? TrackTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        
        // Fetch song info
        let SongInfo = fetchedResultsController.object(at: indexPath)
        
        // Fill in the text fields for the cell
        cell.trackNameLabel.text = SongInfo.trackName
        cell.artistNameLabel.text = SongInfo.artistName
        cell.albumNameLabel.text = SongInfo.collectionName
        
        cell.albumImageView?.image = UIImage(named: "placeholder")
        if let collectionID = SongInfo.collectionID {
            
            // Use image in cache if it is available
            if (imageCache.object(forKey: collectionID as NSString)) != nil {
                cell.albumImageView?.image = self.imageCache.object(forKey: collectionID as NSString)
            } else {
                if let artworkUrl = SongInfo.albumImage {
                    if let url = URL(string: artworkUrl) {
                        
                        // Download the artwork images asynchronously
                        task = session.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
                            if let data = try? Data(contentsOf: url) {
                                
                                // Place the image on the user interface using the main thread
                                DispatchQueue.main.async(execute: { () -> Void in
                                    // If the cell is visible, place the image on the UI
                                    if tableView.visibleCells.contains(cell) {
                                        if let img  = UIImage(data: data) {
                                            cell.albumImageView?.image = img
                                            self.imageCache.setObject(img, forKey: collectionID as NSString)
                                        }
                                    }
                                })
                            }
                        })
                        task.resume()
                    }
                }
            }
        }
        return cell
    }
    
    // This function supoports swipe deleting a row.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Fetch a TrackData object
            let trackInfo = fetchedResultsController.object(at: indexPath)
            
            // Delete a TrackData object
            trackInfo.managedObjectContext?.delete(trackInfo)
        }
    }
}

// Use a fetched results controller to manage data from Core Data and update the track table view.

extension MasterViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        trackTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        trackTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                trackTableView.insertRows(at: [indexPath], with: .fade)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                trackTableView.deleteRows(at: [indexPath], with: .fade)
            }
            break
        default:
            break
        }
    }
}

// User clicks on the search button on keyboard, delete all core data objects and search for music.

extension MasterViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        deleteObjectsAndFetchTunesForSearchText(searchText:  searchBar.text!)
    }
}
