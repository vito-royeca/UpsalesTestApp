//
//  EsignsViewController.swift
//  UpsalesTestApp
//
//  Created by Jovito Royeca on 28/06/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import MBProgressHUD

class EsignsViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: Variables
    var dataSource: DATASource?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        MBProgressHUD.showAdded(to: view, animated: true)
        UpsalesAPI.sharedInstance.fetchEsigns(completion: { error in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.dataSource = self.getDataSource(nil)
                self.tableView.reloadData()
                
                if let error = error {
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showEsignDetails"?:
            if let dest = segue.destination as? UINavigationController,
                let indexPath = sender as? IndexPath,
                let esigns = dataSource!.all() as? [Esign] {
                
                if let vc = dest.childViewControllers.first as? EsignDetailsViewController {
                    let esign = esigns[indexPath.row]
                    
                    vc.esigns = esigns
                    vc.esign = esign
                    vc.esignIndex = indexPath.row
                }
            }
        default:
            ()
        }
    }

    // MARK: CUstom methods
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var request:NSFetchRequest<NSFetchRequestResult>?
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "Esign")
            request!.sortDescriptors = [NSSortDescriptor(key: "mdate", ascending: false)]
        }
        
        let dataSource = DATASource(tableView: tableView, cellIdentifier: "Cell", fetchRequest: request!, mainContext: UpsalesAPI.sharedInstance.dataStack.mainContext, sectionName: nil, configuration: { cell, item, indexPath in
            if let esign = item as? Esign {
                self.configureCell(cell, withEsign: esign)
            }
        })
        
        return dataSource
    }
    
    func configureCell(_ cell: UITableViewCell, withEsign esign: Esign) {
        if let mdate = esign.mdate,
            let client = esign.client,
            let user = esign.user {
            let formatter = DateFormatter()
            
            if let timeLabel = cell.contentView.viewWithTag(1) as? UILabel {
                var text = ""
                formatter.dateFormat = "HH:mm"
                text = formatter.string(from: mdate as Date)
                
                formatter.dateFormat = "dd MMM"
                text = "\(text)\n\(formatter.string(from: mdate as Date).uppercased())"
                timeLabel.text = text
            }
            
            if let nameLabel = cell.contentView.viewWithTag(2) as? UILabel {
                nameLabel.text = client.name
            }
            
            if let stateLabel = cell.contentView.viewWithTag(3) as? UILabel {
                var color = kUpsalesLightGray
                var text:String? = nil
                
                switch esign.state {
                case 0:
                    text = "Draft"
                case 10:
                    text = "Waiting for sign"
                case 20:
                    text = "Rejected"
                    color = kUpsalesRed
                case 30:
                    text = "Everyone has signed"
                    color = kUpsalesGreen
                case 40:
                    text = "Cancelled"
                    color = kUpsalesRed
                default:
                    ()
                }
                
                stateLabel.textColor = color
                stateLabel.text = text
            }
            
            if let avatarView = cell.contentView.viewWithTag(4) as? UIImageView {
                let width = avatarView.frame.size.width
                avatarView.layer.cornerRadius = width / 2
                avatarView.layer.masksToBounds = true
                avatarView.image = nil
                avatarView.isHidden = false
                
                
                if let email = user.email {
                    let cachesDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                    let avatarPath = "\(cachesDir)/\(user.id).jpg"
                    
                    if FileManager.default.fileExists(atPath: avatarPath) {
                        avatarView.image = UIImage(contentsOfFile: avatarPath)
                    } else {
                        // download the avatar from Gravatar
                        let url = URL(string: "https://www.gravatar.com/avatar/\(md5(email))?s=\(Int(width))&d=404")
                        
                        URLSession.shared.dataTask(with: url!) { (data, response, error) in
                            if let response = response as? HTTPURLResponse {
                                if response.statusCode == 404 {
                                    if let name = user.name {
                                        var initials = ""
                                        
                                        for n in name.components(separatedBy: " ") {
                                            if let initial = n.characters.first {
                                                initials.append(String(initial))
                                            }
                                        }
                                        
                                        DispatchQueue.main.async {
                                            if let label = cell.contentView.viewWithTag(100) {
                                                label.removeFromSuperview()
                                            }
                                            
                                            let label = UILabel(frame: avatarView.frame)
                                            label.tag = 100
                                            label.textAlignment = NSTextAlignment.center
                                            label.backgroundColor = kUpsalesBrightBlue
                                            label.layer.cornerRadius = width / 2
                                            label.layer.masksToBounds = true
                                            label.textColor = UIColor.white
                                            label.font = UIFont(name: "Roboto", size: CGFloat(12))
                                            label.adjustsFontSizeToFitWidth = true
                                            label.text = initials
                                            avatarView.isHidden = true
                                            cell.contentView.addSubview(label)
                                        }
                                    }
                                    
                                } else {
                                    if let data = data {
                                        if !FileManager.default.fileExists(atPath: avatarPath) {
                                            try? data.write(to: URL(fileURLWithPath: avatarPath))
                                        }
                                        
                                        DispatchQueue.main.async {
                                            avatarView.image = UIImage(contentsOfFile: avatarPath)
                                        }
                                    }
                                }
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    func md5(_ string: String) -> String {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate(capacity: 1)
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        
        return hexString
    }

}

// MARK: UITableViewDelegate
extension EsignsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showEsignDetails", sender: indexPath)
    }
}