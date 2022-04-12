//
//  Table with Collection.swift
//  BridgeScore
//
//  Created by Marc Shearer on 24/02/2022.
//

import UIKit

// MARK: - Table View Section Header with CollectionView ============================================ -

public class TableViewSectionHeaderWithCollectionView: UITableViewHeaderFooterView {
    public var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        self.contentView.addSubview(collectionView, anchored: .all)
        self.contentView.bringSubviewToFront(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func dequeue<D: UICollectionViewDataSource & UICollectionViewDelegate>(_ dataSourceDelegate : D, tableView: UITableView, withIdentifier identifier: String, tag: Int) -> TableViewSectionHeaderWithCollectionView {
        var cell: TableViewSectionHeaderWithCollectionView
        cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! TableViewSectionHeaderWithCollectionView
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate, tag: tag)
        return cell
    }
    
    private func setCollectionViewDataSourceDelegate
    <D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, tag: Int) {
        TableViewCellWithCollectionView.setCollectionViewDataSourceDelegate(dataSourceDelegate, collectionView: collectionView, tag: tag)
    }
}


// MARK: - Table View Cell with CollectionView ================================================= -

public class TableViewCellWithCollectionView: UITableViewCell {
    public var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!
           
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        self.contentView.addSubview(collectionView, anchored: .all)
        self.contentView.bringSubviewToFront(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setCollectionViewDataSourceDelegate
    <D: UICollectionViewDataSource & UICollectionViewDelegate>
    (_ dataSourceDelegate: D, tag: Int) {
        TableViewCellWithCollectionView.setCollectionViewDataSourceDelegate(dataSourceDelegate, collectionView: collectionView, tag: tag)
    }
    
    public static func setCollectionViewDataSourceDelegate
    <D: UICollectionViewDataSource & UICollectionViewDelegate>
        (_ dataSourceDelegate: D, collectionView: UICollectionView, tag: Int) {
        
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = tag
        collectionView.reloadData()
    }
}


