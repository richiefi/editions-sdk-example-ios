//
//  CollectionViewCell.swift
//  EditionsSampleApp
//
//  Created by Luis Ángel San Martín Rodríguez on 15/11/2019.
//

import UIKit
import RichieEditionsSDK

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet var coverImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var downloadProgress: UIProgressView!
    
    var getCoverCancelable: Cancelable?
    
    func populate(title: String, state: String, downloadProgress: Float, processing: Bool) {
        self.titleLabel.text = title
        self.stateLabel.text = state
        
        self.loadingIndicator.isHidden = !processing
        
        self.downloadProgress.isHidden = downloadProgress < 0
        
        if downloadProgress > 0 {
            self.downloadProgress.progress = downloadProgress
        }
    }
    
    override func prepareForReuse() {
        self.getCoverCancelable?.cancel()
        self.getCoverCancelable = nil

        self.titleLabel.text = nil
        self.stateLabel.text = nil
        self.coverImageView.image = nil
        
        self.loadingIndicator.isHidden = true
        self.downloadProgress.isHidden = true
    }
}
