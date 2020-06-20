//
//  QuestionDetails.swift
//  Chatbot
//
//  Created by Suganya Pongiyanasamy on 14/06/20.
//  Copyright © 2020 Suganya Pongiyanasamy. All rights reserved.
//

import Foundation

struct QuestionDetail {
    
    var questionId  : Int!
    var title       : String!
    var parentId    : Int!
    var contactId   : Int!
    var levelId     : Int!
    var isHeader    : Bool  = false
    var contactInfo : Contact?
}


