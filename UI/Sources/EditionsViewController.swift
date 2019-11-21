//
//  EditionsViewController.swift
//  Editions Example App
//
//  Created by Luis Ángel San Martín Rodríguez on 04/11/2019.
//

import UIKit

import RichieSDK

class EditionsViewController: UIViewController {
    private let editions: Editions
    
    private var editionsUUIDs: [UUID] = []
    
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
        
        self.editions.updateFeed { success in
            self.editions.editionProvider?.allEditions(callback: { editionsUUIDs in
                self.editionsUUIDs = editionsUUIDs
                self.collectionView.reloadData()
            })
            
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.reloadData()
        }
    }
}

private extension EditionsViewController {
    func cellForEdition(_ editionId: UUID) -> CollectionViewCell? {
        guard let index = self.editionsUUIDs.firstIndex(of: editionId) else {
            return nil
        }
        
        return self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! CollectionViewCell?
    }
    
    func populateCell(editionId: UUID, cell: CollectionViewCell?, downloadProgress: Float = -1, processing: Bool = false) {
        guard let cell = cell else {
            return
        }
        
        guard let displayInfo = self.editions.editionDisplayInfoProvider?.displayInfoForEdition(editionId: editionId) else {
            return
        }
        
        let coverUrl = self.editions.editionCoverUrlProvider?.coverUrlForEdition(editionId: editionId, boundingBoxSize: self.coverBoundingBox())
        
        let processing = processing || (downloadProgress < 0 && self.activeDownloads[editionId] != nil)
        
        let stateString: String
        if self.editions.downloadedEditionsProvider?.downloadedEditions.contains(editionId) ?? false {
            stateString = "Downloaded"
            
            self.editions.editionsDiskUsageProvider?.diskUsageByDownloadedEdition(editionId: editionId
                , callback: { totalBytes in
                    let spaceOnDiskMB = totalBytes / 1024 / 1024
                    
                    DispatchQueue.main.async {
                        cell.populate(title: displayInfo.title, state: "Downloaded \(spaceOnDiskMB)MB", downloadProgress: downloadProgress, processing: processing, coverUrl: coverUrl)
                    }
            })
        } else {
            stateString = "Not downloaded"
        }
        
        cell.populate(title: displayInfo.title, state: stateString, downloadProgress: downloadProgress, processing: processing, coverUrl: coverUrl)
    }
    
    func updateCellForEdition(_ editionId: UUID) {
        self.populateCell(editionId: editionId, cell: self.cellForEdition(editionId))
    }
    
    func presentEdition(_ editionId: UUID) {
        let cell = self.cellForEdition(editionId)
        self.editions.editionPresenter?.openEdition(editionId: editionId,
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
            let uuid = self.editionsUUIDs[indexPath.item]
            
            self.editions.downloadedEditionsManager?.deleteEdition(editionId: uuid, completion: {
                self.updateCellForEdition(uuid)
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
        return self.editionsUUIDs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditionCell", for: indexPath) as! CollectionViewCell
        
        let uuid = self.editionsUUIDs[indexPath.item]

        self.populateCell(editionId: uuid, cell: cell, downloadProgress: -1, processing: false)
        
        return cell
    }
}

extension EditionsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let uuid = self.editionsUUIDs[indexPath.item]
        
        if self.editions.downloadedEditionsProvider?.downloadedEditions.contains(uuid) ?? false {
            self.presentEdition(uuid)
        } else {
            if let existingDownload = self.activeDownloads[uuid] {
                existingDownload.cancel()
                self.activeDownloads.removeValue(forKey: uuid)
                self.updateCellForEdition(uuid)
            } else {
                self.activeDownloads[uuid] = self.editions.editionPresenter?.downloadEdition(editionId: uuid, downloadProgressListener: self)
                self.updateCellForEdition(uuid)
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
        
        return CGSize(width: width, height: width * 1.8)
    }
}

extension EditionsViewController: DownloadProgressListener {
    func editionWillStartDownload(editionId: UUID) {
        self.updateCellForEdition(editionId)
    }
    
    func editionDownloadProgress(editionId: UUID, progress: Float, isBeingPreparedForPresentation: Bool) {
        self.populateCell(editionId: editionId, cell: self.cellForEdition(editionId), downloadProgress: progress, processing: isBeingPreparedForPresentation)
    }
    
    func editionDidDownload(editionId: UUID) {
        self.activeDownloads.removeValue(forKey: editionId)
        self.updateCellForEdition(editionId)
        
        if (self.activeDownloads.values.count == 0) {
            DispatchQueue.main.async {
                self.presentEdition(editionId)
            }
        }
    }
    
    func editionDidFailDownload(editionId: UUID, error: Error?) {
        self.showToast(message: "Error downloading edition: \(error?.localizedDescription ?? "unknown error")")
        self.activeDownloads.removeValue(forKey: editionId)
        self.updateCellForEdition(editionId)
    }
}
