//
//  CollectionViewCell.swift
//  EditionsSampleApp
//
//  Created by Luis Ángel San Martín Rodríguez on 15/11/2019.
//

import UIKit
import RichieSDK

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var downloadProgress: UIProgressView!
    
    func populate(title: String, state: String, downloadProgress: Float, processing: Bool, coverUrl: URL?) {
        self.coverImageView.loadRemoteImage(url: coverUrl)
        self.titleLabel.text = title
        self.stateLabel.text = state
        
        self.loadingIndicator.isHidden = !processing
        
        self.downloadProgress.isHidden = downloadProgress < 0
        
        if downloadProgress > 0 {
            self.downloadProgress.progress = downloadProgress
        }
    }
}


extension UIImageView {
public func loadRemoteImage(url: URL?) {
    guard let url = url else {
        return
    }
    
    URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in

        if error != nil {
            print(error as Any)
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            let image = UIImage(data: data!)
            self.image = image
        })

    }).resume()
}}
