//
//  ViewController.swift
//  TVDemoApp
//
//  Created by Shawn Spencer on 11/5/15.
//  Copyright © 2015 Shawn Spencer. All rights reserved.
//

import UIKit


let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD = "flickr.photos.search"
let API_KEY = "PUT_YOUR_FLICKR_API_KEY_HERE"

class ViewController: UIViewController {

    @IBOutlet weak var flickImageView: UIImageView!
    @IBOutlet weak var flickTitleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        downloadAndDisplayImage()
    }

    func downloadAndDisplayImage() {

        var parameters = [
            "method": METHOD,
            "api_key": API_KEY,
            "extras": "url_m",
            "safe_search": "3", // 1 = safe, 2 = moderate, 3 = restricted (un-authed calls only see safe results)
            "format": "json",
            "nojsoncallback": "1"
        ]

        parameters["text"] = "baby animals"

        let urlSession = NSURLSession.sharedSession()

        let urlString = getUrlStringWithParameters(parameters)
        let urlRequest = NSURLRequest(URL: NSURL(string: urlString)!)

        let task = urlSession.dataTaskWithRequest(urlRequest) {
            (data : NSData?, response : NSURLResponse?, error : NSError?) in

            if error != nil {
                print("there was an error: \(error)")
            } else if let data = data {
                print("no error")

                // We can cast this to a dictionary, because Flickr's documentation shows that the JSON data resulting from this method is wrapped in curly braces

                let resultJsonData = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)

                if resultJsonData == nil {
                    print("resultJsonData is nil")
                }

                guard let resultJsonContainer = resultJsonData as? [String : AnyObject] else {
                    print("resultJsonContainer is invalid")
                    return
                }

                // Get the photos dictionary out of the parsed JSON data
                if let photosDictionary = resultJsonContainer["photos"] as? [String : AnyObject] {

                    // Determine the number of photos
                    let numPhotos : Int
                    if let totalPhotosVal = photosDictionary["total"] as? String {
                        numPhotos = (totalPhotosVal as NSString).integerValue
                    } else {
                        numPhotos = 0
                    }

                    // If there are photos, pick one out of the array
                    if numPhotos > 0 {

                        if let photosArray = photosDictionary["photo"] as? [[String : AnyObject]] {

                            let randomArrayIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let photoMetaData = photosArray[randomArrayIndex]

                            if let photoTitleString = photoMetaData["title"] as? String,
                                let photoUrlString = photoMetaData["url_m"] as? String {

                                    if let imageData = NSData(contentsOfURL: NSURL(string: photoUrlString)!) {

                                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                            // do our updates on the main thread
                                            // make these updates minimal

                                            print("Found image at url: \(photoUrlString)")
                                            self.flickTitleLabel.text = photoTitleString
                                            self.flickImageView.image = UIImage(data: imageData)
                                        })
                                    } else {
                                        print("Could not download image at url: \(photoUrlString)")
                                    }
                            }//unwrap title and url optionals

                        }//unwrap photosArray optional

                    } else {
                        print("Search resulted in 0 photos")

                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            // do our updates on the main thread
                            // make these updates minimal
                            
                            self.flickTitleLabel.text = "Search returned 0 results"
                            self.flickImageView.image = nil
                        })
                    }
                }//unwrap photosDictionary optional
                
            }//no data task error
            
        }//end of url data task completion handler
        
        task.resume()
    }

    func getUrlStringWithParameters(parameters: [String: AnyObject]) -> String {
        // Construct a URL that uses the Flickr photos search method:
        // flickr.photos.search

        var urlString = BASE_URL

        var first = true
        for (key, value) in parameters {
            if first {
                urlString += "?"
                first = false
            } else {
                urlString += "&"
            }

            urlString += key + "=" + value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        }

        if let searchString = parameters["text"] as? String {
            print("search string: \(searchString)")
            print("      escaped: \(searchString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)")
        }
        print("resulting url:")
        print(urlString)

        return urlString
    }

}

