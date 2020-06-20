//
//  QuestionCell.swift
//  Chatbot
//
//  Created by Suganya Pongiyanasamy on 14/06/20.
//  Copyright © 2020 Suganya Pongiyanasamy. All rights reserved.
//

import UIKit

class QuestionCell: UITableViewCell {
    
    static let reuseIdentifier = "QuestionCellIdentifier"

    @IBOutlet weak var textlabel : UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configCell(with question:QuestionDetail?) {
        textlabel.text = question?.title
    }
}
