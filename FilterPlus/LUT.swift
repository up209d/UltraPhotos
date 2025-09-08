//
//  LUT.swift
//  UltraPhotos
//
//  Created by Duc Duong on 8/9/2025.
//

import Cocoa

struct ViewThumbnailItem {
    let key: String
    let image: NSImage
}

class LUTSelectionViewController: NSViewController {
    private var splitView: NSSplitView!
    private var scrollView: NSScrollView!
    private var collectionView: NSCollectionView!
    
    private var itemRatio: Float!

    var invalidateLayoutWorkItem: DispatchWorkItem?
    
    var onSelected: ((_ path: String) -> Void)?
    var onDeselected: ((_ path: String) -> Void)?
    
    var lutThumbnails: [ViewThumbnailItem] = [] {
        didSet { collectionView?.reloadData() }
    }

    init(splitView: NSSplitView, scrollView: NSScrollView, collectionView: NSCollectionView, itemRatio: Float) {
        self.splitView = splitView
        self.scrollView = scrollView
        self.collectionView = collectionView
        self.itemRatio = itemRatio
        super.init(nibName: nil, bundle: nil)
        
        splitView.delegate = self
        
        collectionView.register(
            LUTThumbnail.self,
            forItemWithIdentifier: LUTThumbnail.identifier
        )
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LUTSelectionViewController: NSSplitViewDelegate {
    func splitViewDidResizeSubviews(_ notification: Notification) {
    invalidateLayoutWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.collectionView.collectionViewLayout?.invalidateLayout()
        }
        invalidateLayoutWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
}

extension LUTSelectionViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return lutThumbnails.count
    }
}

extension LUTSelectionViewController: NSCollectionViewDelegate {
    // Configure for CollectionView
    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: LUTThumbnail.identifier,
            for: indexPath
        ) as! LUTThumbnail
        item.setKey(lutThumbnails[indexPath.item].key)
        item.setImage(lutThumbnails[indexPath.item].image)
        item.setLabel(URL(string: lutThumbnails[indexPath.item].key)!.lastPathComponent)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        for indexPath in indexPaths {
            if let item = collectionView.item(at: indexPath) as? LUTThumbnail {
                item.setSelected(selected: true)
                onSelected?(lutThumbnails[indexPath.item].key)
            }
            
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        for indexPath in indexPaths {
            if let item = collectionView.item(at: indexPath) as? LUTThumbnail {
                item.setSelected(selected: false)
                onDeselected?(lutThumbnails[indexPath.item].key)
            }
        }
    }
}

extension LUTSelectionViewController: NSCollectionViewDelegateFlowLayout {
    // Configure for CollectionView Flow Layout
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> NSSize
    {
        let ratio = CGFloat(self.itemRatio)
        let boundWidth = max(collectionView.bounds.width, 120)
        return NSSize(width: boundWidth, height: boundWidth / ratio)
    }
}
