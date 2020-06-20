//
//  AnswerCell.swift
//  Chatbot
//
//  Created by Suganya Pongiyanasamy on 14/06/20.
//  Copyright © 2020 Suganya Pongiyanasamy. All rights reserved.
//

import UIKit

class AnswerCell: UITableViewCell {
    
    static let reuseIdentifier = "AnswerCellIdentifier"
    
    @IBOutlet weak var textlabel : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configCell(with answer:AnswerDetails?) {
        textlabel.text = answer?.answer
    }

}
