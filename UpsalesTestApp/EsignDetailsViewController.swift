//
//  EsignDetailsViewController.swift
//  UpsalesTestApp
//
//  Created by Jovito Royeca on 29/06/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit

class EsignDetailsViewController: UIViewController {

    // MARK: Variables
    var esign:Esign?
    var esigns:[Esign]?
    var esignRecipients:[EsignRecipient]?
    var esignIndex = 0
    
    // MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: Actions
    @IBAction func closeAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.dataSource = self
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        fetchEsignRecipients()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        flowLayout.itemSize = CGSize(width: collectionView.frame.size.width-10, height: collectionView.frame.size.height)
        flowLayout.minimumInteritemSpacing = CGFloat(5)
        flowLayout.minimumLineSpacing = CGFloat(5)
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 5, 0, 5)
        flowLayout.scrollDirection = .horizontal
        
        collectionView.scrollToItem(at: IndexPath(item: esignIndex, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.reloadData()
        scrollToNearestVisibleCollectionViewCell()
    }
    
    // MARK: Custom methods
    func fetchEsignRecipients() {
        if let recipients = esign!.recipients {
            if let er = recipients.allObjects as? [EsignRecipient] {
                esignRecipients = er.sorted(by: { (item1: EsignRecipient, item2: EsignRecipient) in
                    var d1:NSDate?
                    var d2:NSDate?
                    
                    if let d = item1.sign {
                        d1 = d
                    } else if let d = item1.declineDate {
                        d1 = d
                    }
                    
                    if let d = item2.sign {
                        d2 = d
                    } else if let d = item2.declineDate {
                        d2 = d
                    }
                    
                    if let d1 = d1,
                        let d2 = d2 {
                        return d1.compare(d2 as Date) == .orderedDescending
                    } else {
                        return true
                    }
                })
            }
        }
    }
}

// MARK: UICollectionViewDataSource
extension EsignDetailsViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let esigns = esigns {
            return esigns.count
        }
        
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        if let tableView = cell.viewWithTag(1) as? UITableView {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.reloadData()
        }
        
        return cell
    }
}

// MARK: UICollectionViewDelegate
//extension EsignDetailsViewController : UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        if let esigns = esigns {
//            esign = esigns[indexPath.row]
//        }
//    }
//}

// MARK: UITableViewDataSource
extension EsignDetailsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 4
        
        if let esign = esign {
            if let recipients = esign.recipients {
                rows += recipients.allObjects.count
            }
        }
        
        return rows
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        let formatter = DateFormatter()
        
        switch indexPath.row {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")
            if let accountLabel = cell?.contentView.viewWithTag(1) as? UILabel {
               accountLabel.text = esign!.client!.name
            }
            if let dateLabel = cell?.contentView.viewWithTag(2) as? UILabel {
                formatter.dateFormat = "dd MMMM YYYY-HH:mm"
                dateLabel.text = formatter.string(from: esign!.mdate! as Date).lowercased()
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "SequenceCell")
            // remove existing views in cell
            for label in cell!.contentView.subviews {
                label.removeFromSuperview()
            }
            
            if let esignRecipients = esignRecipients {
                let count = esignRecipients.count
                let width = CGFloat(26)
                let barWidth = width / 2
                
                let totalWidth = width * CGFloat(count)
                let totalBarWidth = barWidth * CGFloat(count - 1)
                let groupWidth = totalWidth + totalBarWidth
                
                var x = (cell!.contentView.frame.size.width - groupWidth) / 2
                let y = (cell!.contentView.frame.size.height - width) / 2
                let barY = (cell!.contentView.frame.size.height - 2) / 2
                var index = 0
                
                for recipient in esignRecipients {
                    var initials = ""
                    var labelColor:UIColor?
                    var barColor:UIColor?
                    
                    if let fstname = recipient.fstname{
                        if let initial = fstname.characters.first {
                            initials.append(String(initial))
                        }
                    }
                    if let sndname = recipient.sndname {
                        if let initial = sndname.characters.first {
                            initials.append(String(initial))
                        }
                    }
                    
                    if let _ = recipient.sign {
                        labelColor = kUpsalesGreen
                        barColor = kUpsalesGreen
                    } else if let _ = recipient.declineDate {
                        labelColor = kUpsalesRed
                        barColor = kUpsalesLightGray
                    } else {
                        labelColor = kUpsalesLightGray
                        barColor = kUpsalesLightGray
                    }
                    
                    DispatchQueue.main.async {
                        let label = UILabel(frame: CGRect(x: x, y: y, width: width, height: width))
                        label.textAlignment = NSTextAlignment.center
                        label.backgroundColor = labelColor
                        label.layer.cornerRadius = width / 2
                        label.layer.masksToBounds = true
                        label.textColor = UIColor.white
                        label.font = UIFont(name: "Roboto", size: CGFloat(12))
                        label.adjustsFontSizeToFitWidth = true
                        label.text = initials
                        
                        cell!.contentView.addSubview(label)
                        x += width
                        index += 1
                        
                        if count > 1 && index < count {
                            let bar = UIView(frame: CGRect(x: x, y: barY, width: barWidth, height: 2))
                            bar.backgroundColor = barColor
                            cell!.contentView.addSubview(bar)
                            x += barWidth
                        }
                    }
                    
                }
            }
        
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "ViewDocumentCell")
        case 3:
            cell = tableView.dequeueReusableCell(withIdentifier: "SentByCell")
            if let nameLabel = cell?.contentView.viewWithTag(1) as? UILabel {
                nameLabel.text = esign!.client!.name
            }
            if let dateLabel = cell?.contentView.viewWithTag(2) as? UILabel {
                formatter.dateFormat = "dd MMMM YY-HH:mm"
                dateLabel.text = formatter.string(from: esign!.mdate! as Date)
            }
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "RecipientCell")
            if let esignRecipients = esignRecipients {
                let recipient = esignRecipients[indexPath.row-4]
                
                formatter.dateFormat = "dd MMMM YY-HH:mm"
                
                if let statusIcon = cell?.contentView.viewWithTag(1) as? UIImageView {
                    let width = statusIcon.frame.size.width
                    statusIcon.layer.cornerRadius = width / 2
                    statusIcon.layer.masksToBounds = true
                    
                    var iconImage:UIImage?
                    var tintColor = UIColor.darkGray
                    
                    if let _ = recipient.sign {
                        iconImage = UIImage(named: "edit")
                        tintColor = kUpsalesGreen
                    } else if let _ = recipient.declineDate {
                        iconImage = UIImage(named: "thumbs down")
                        tintColor = kUpsalesRed
                    } else {
                        iconImage = UIImage(named: "time")
                        tintColor = kUpsalesLightGray
                    }
                    
                    if let image = iconImage {
                        let tintedImage = image.withRenderingMode(.alwaysTemplate)
                        statusIcon.image = tintedImage
                        statusIcon.tintColor = tintColor
                    }
                    statusIcon.contentMode = .scaleAspectFit
                }
                
                if let nameLabel = cell?.contentView.viewWithTag(2) as? UILabel {
                    nameLabel.text = "\(recipient.fstname != nil ? recipient.fstname! : "") \(recipient.sndname != nil ? recipient.sndname! : "")"
                }
                
                if let statusLabel = cell?.contentView.viewWithTag(3) as? UILabel {
                    var color = kUpsalesLightGray
                    var text = ""
                    
                    
                    formatter.dateFormat = "dd MMMM HH:mm"
                    if let sign = recipient.sign {
                        text = "Signed \(formatter.string(from: sign as Date).lowercased())"
                        color = kUpsalesGreen
                    } else if let declineDate = recipient.declineDate {
                        text = "Denied  \(formatter.string(from: declineDate as Date).lowercased())"
                        color = kUpsalesRed
                    } else {
                        text = "Waiting for sign"
                        color = kUpsalesLightGray
                    }
                    
                    statusLabel.text = text
                    statusLabel.textColor = color
                }
                
                if let visibleIcon = cell?.contentView.viewWithTag(4) as? UIImageView {
                    visibleIcon.isHidden = recipient.seen
                }
                if let viewedLabel = cell?.contentView.viewWithTag(5) as? UILabel {
                    viewedLabel.isHidden = recipient.seen
                }
            }
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension EsignDetailsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        switch indexPath.row {
        case 0:
            height = 66
        case 1,2:
            height = UITableViewAutomaticDimension
        case 3:
            height = 60
        default:
            height = 80
        }
        
        return height
    }
}

// MARK: UIScrollViewDelegate
extension EsignDetailsViewController : UIScrollViewDelegate {
    func scrollToNearestVisibleCollectionViewCell() {
        let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + (self.collectionView!.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        
        for i in 0..<collectionView.visibleCells.count {
            let cell = collectionView.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
            
            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = collectionView.indexPath(for: cell)!.row
            }
        }

        if closestCellIndex != -1 {
            // update the current esign when the user scrolls sideways
            if let esigns = esigns {
                esign = esigns[closestCellIndex]
                fetchEsignRecipients()
            }
            
            let indexPath = IndexPath(row: closestCellIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            collectionView.reloadItems(at: [indexPath])
        }
    }

//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if scrollView == collectionView {
//            if !decelerate {
//                scrollToNearestVisibleCollectionViewCell()
//            }
//        }
//    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            scrollToNearestVisibleCollectionViewCell()
        }
    }
}

