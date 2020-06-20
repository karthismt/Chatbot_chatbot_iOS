//
//  ViewController.swift
//  Chatbot
//
//  Created by Suganya Pongiyanasamy on 12/06/20.
//  Copyright © 2020 Suganya Pongiyanasamy. All rights reserved.
//

import UIKit

let kReloadView     = "ReloadView"
let kShowIndicator  = "ShowIndicator"
let kHideIndicator  = "hideIndicator"
let kContact        = "conatct"

class ViewController: UITableViewController {

    let viewModel = ChatViewModel()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chatbot"
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        NotificationCenter.default.addObserver(self, selector: #selector(methodOfReceivedNotification(notification:)), name: NSNotification.Name(rawValue: kReloadView), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(methodOfReceivedNotification(notification:)), name: NSNotification.Name(rawValue: kShowIndicator), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(methodOfReceivedNotification(notification:)), name: NSNotification.Name(rawValue: kHideIndicator), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(methodOfReceivedNotification(notification:)), name: NSNotification.Name(rawValue: kContact), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        switch notification.name.rawValue {
        case kReloadView:
            self.tableView.reloadData()
            let index = (viewModel.getNumberOfRows() > 0) ? (viewModel.getNumberOfRows() - 1) : 0
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
            break
        case kShowIndicator:
            activityIndicator("Loading...")
            break
            
        case kHideIndicator:
            self.effectView.removeFromSuperview()
            break
        case kContact:
            if let conatct = notification.userInfo?[kContact] as? Contact{
                let action = UIAlertAction(title: "Call", style: UIAlertAction.Style.default) { (action) in
                    self.makeCall(to: conatct)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil)
                showAlert(with: "Kindly conatct support team for help", actions: [cancelAction, action])
            }
        default:
            break
        }
    }

    func makeCall(to contact:Contact) {
        if let number = contact.mobileNo, let url = URL(string: "tel://\(number)"),  UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [ : ], completionHandler: nil)
        }
    }
    
    func showAlert(with message:String, actions:[UIAlertAction]) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        for action in actions {
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func activityIndicator(_ title: String) {

        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()

        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 160, height: 46))
        strLabel.text = title
        strLabel.font = .systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)

        effectView.frame = CGRect(x: view.frame.midX - strLabel.frame.width/2, y: view.frame.midY - strLabel.frame.height/2 , width: 160, height: 46)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true

        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.startAnimating()

        effectView.addSubview(activityIndicator)
        effectView.addSubview(strLabel)
        view.addSubview(effectView)
    }

}

extension ViewController  {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getNumberOfRows()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let chat = viewModel.getItem(at: indexPath.row) {
            if chat is QuestionDetail {
                let cell = tableView.dequeueReusableCell(withIdentifier: QuestionCell.reuseIdentifier, for: indexPath) as! QuestionCell
                cell.configCell(with: chat as? QuestionDetail)
                cell.isUserInteractionEnabled = viewModel.canEnableUserInteraction(chat: chat as? QuestionDetail)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: AnswerCell.reuseIdentifier, for: indexPath) as! AnswerCell
                cell.configCell(with: chat as? AnswerDetails)
                cell.isUserInteractionEnabled = false
                return cell
            }
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.updateAns(For: indexPath.row)
    }
}













