//
//  EditionsViewController.swift
//  Editions Example App
//
//  Created by Luis Ángel San Martín Rodríguez on 04/11/2019.
//

import UIKit

import RichieEditionsSDK

class EditionsViewController: UIViewController {
    private let editions: Editions
    
    private var allEditions: [Edition] = []
    
    private var activeDownloads: [UUID : Cancelable] = [:]
        
    @IBOutlet var collectionView: UICollectionView!
    
    init(editions: Editions) {
        self.editions = editions
        
        super.init(nibName: "EditionsViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.collectionView.register(UINib(nibName: "CollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "EditionCell")
        
        let longTapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(EditionsViewController.handleLongPress))
        
        self.collectionView.addGestureRecognizer(longTapRecognizer)
        
        self.editions.updateFeed { _ in
            let paginator = self.editions.editionProvider?.editions(productTags: nil, startDate: nil, endDate: nil, pageSize: nil)

            paginator?.next { result in
                switch result {
                case let .success(page):
                    self.allEditions = page.editions

                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                case .failure:
                    print("ooops")
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.reloadData()
        }
    }
}

private extension EditionsViewController {
    func cellForEdition(_ edition: Edition) -> CollectionViewCell? {
        guard let index = self.allEditions.firstIndex(of: edition) else {
            return nil
        }
        
        return self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! CollectionViewCell?
    }
    
    func populateCell(edition: Edition, cell: CollectionViewCell?, downloadProgress: Float = -1, processing: Bool = false) {
        guard let cell = cell else {
            return
        }
        
        cell.getCoverCancelable = self.editions.editionCoverProvider?.coverImageForEdition(edition: edition, boundingBoxSize: coverBoundingBox(), completion: { result in
            switch result {
            case let .success(cover):
                cell.coverImageView.image = cover
            case let .failure(error):
                print("Ooops: \(error.localizedDescription)")
            }
        })
        
        let processing = processing || (downloadProgress < 0 && self.activeDownloads[edition.id] != nil)
        
        let stateString: String
        if self.editions.downloadedEditionsProvider?.downloadedEditions.map({ $0.id }).contains(edition.id) ?? false {
            stateString = "Downloaded"

            self.editions.editionsDiskUsageProvider?.diskUsageByDownloadedEdition(editionId: edition.id, callback: { totalBytes in
                let spaceOnDiskMB = totalBytes / 1024 / 1024

                DispatchQueue.main.async {
                    cell.populate(title: edition.title, state: "Downloaded \(spaceOnDiskMB)MB", downloadProgress: downloadProgress, processing: processing)
                }
            })
        } else {
            stateString = "Not downloaded"
        }
        
        cell.populate(title: edition.title, state: stateString, downloadProgress: downloadProgress, processing: processing)
    }
    
    func updateCellForEdition(_ edition: Edition) {
        self.populateCell(edition: edition, cell: self.cellForEdition(edition))
    }
    
    func presentEdition(_ edition: Edition) {
        let cell = self.cellForEdition(edition)
        self.editions.editionPresenter?.openEdition(edition: edition,
                                                    presenterViewController: self,
                                                    sourceView: cell?.coverImageView,
                                                    sourceImage: cell?.coverImageView.image,
                                                    onFinishedOpening: { error in
            if let error = error {
                switch error {
                case .editionNotDownloaded:
                    self.showToast(message: "Error opening edition: Edition is not downloaded.")
                case .editionNotFound:
                    self.showToast(message: "Error opening edition: Edition not found.")
                case .internalError(let err):
                    self.showToast(message: "Error opening edition: \(err.localizedDescription).")
                @unknown default:
                    assertionFailure("Unknown error: \(error)")
                    Log.error("Unknown error: \(error)")
                    self.showToast(message: "Error opening edition: \(error).")
                }
            }
        })
    }
    
    func showToast(message : String) {
        DispatchQueue.main.async {
            let toastLabel = UILabel(frame: CGRect(x: 10, y: self.view.frame.size.height-100, width: self.view.frame.size.width - 20, height: 100))
            toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toastLabel.textColor = UIColor.white
            toastLabel.textAlignment = .center;
            toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
            toastLabel.text = message
            toastLabel.numberOfLines = 3
            toastLabel.alpha = 1.0
            toastLabel.layer.cornerRadius = 3;
            toastLabel.clipsToBounds  =  true
            self.view.addSubview(toastLabel)
            UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            })
        }
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        let p = gesture.location(in: self.collectionView)

        if let indexPath = self.collectionView.indexPathForItem(at: p) {
            let edition = self.allEditions[indexPath.item]
            
            self.editions.downloadedEditionsManager?.deleteEdition(editionId: edition.id, completion: {
                self.updateCellForEdition(edition)
            })
        } else {
            print("couldn't find index path")
        }
    }
}

extension EditionsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allEditions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditionCell", for: indexPath) as! CollectionViewCell

        let edition = self.allEditions[indexPath.item]

        self.populateCell(edition: edition, cell: cell, downloadProgress: -1, processing: false)

        return cell
    }
}

extension EditionsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let edition = self.allEditions[indexPath.item]
        
        if self.editions.downloadedEditionsProvider?.downloadedEditions.map({ $0.id }).contains(edition.id) ?? false {
            self.presentEdition(edition)
        } else {
            if let existingDownload = self.activeDownloads[edition.id] {
                existingDownload.cancel()
                self.activeDownloads.removeValue(forKey: edition.id)
                self.updateCellForEdition(edition)
            } else {
                self.activeDownloads[edition.id] = self.editions.editionPresenter?.downloadEdition(edition: edition, downloadProgressListener: self)
                self.updateCellForEdition(edition)
            }
        }
    }
}

extension EditionsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.cellSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}

extension EditionsViewController {
    func coverBoundingBox() -> CGSize {
        return self.cellSize()
    }
    
    func cellSize() -> CGSize {
        let numColumns: Int
        let availableWidth = self.collectionView.frame.size.width
        if availableWidth <= 550 {
           numColumns = 2
        } else {
           numColumns = 5
        }
        
        let width = floor((availableWidth - CGFloat((numColumns + 1) * 10)) / CGFloat(numColumns))
        
        return CGSize(width: round(width), height: round(width * 1.8))
    }
}

extension EditionsViewController: DownloadProgressListener {
    func editionWillStartDownload(edition: Edition) {
        self.updateCellForEdition(edition)
    }

    func editionDownloadProgress(edition: Edition, progress: Float, isBeingPreparedForPresentation: Bool) {
        self.populateCell(edition: edition, cell: self.cellForEdition(edition), downloadProgress: progress, processing: isBeingPreparedForPresentation)
    }

    func editionDidDownload(edition: Edition) {
        self.activeDownloads.removeValue(forKey: edition.id)
        self.updateCellForEdition(edition)

        if self.activeDownloads.values.isEmpty {
            DispatchQueue.main.async {
                self.presentEdition(edition)
            }
        }
    }

    func editionDidFailDownload(edition: Edition, error: DownloadError) {
        self.showToast(message: "Error downloading edition: \(error.localizedDescription)")
        self.activeDownloads.removeValue(forKey: edition.id)
        self.updateCellForEdition(edition)
    }
}
