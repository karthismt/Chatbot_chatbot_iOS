//
//  ChatViewModel.swift
//  Chatbot
//
//  Created by Suganya Pongiyanasamy on 14/06/20.
//  Copyright © 2020 Suganya Pongiyanasamy. All rights reserved.
//

import Foundation

class  ChatViewModel: NSObject {
    
    var chatHistory = [Any]()
    var currentParentType = 0
    
    override init() {
        super.init()
        NotificationCenter.default.post(name: Notification.Name(rawValue: kShowIndicator), object: nil)
        DataManager.manager.downloadData { (success) in
            NotificationCenter.default.post(name: Notification.Name(rawValue: kHideIndicator), object: nil)
            self.refreshChat()
            NotificationCenter.default.post(name: Notification.Name(rawValue: kReloadView), object: nil)
        }
    }
    
    func getNumberOfRows() -> Int {
        return chatHistory.count
    }
    
    func getItem(at index:Int) -> Any? {
        if chatHistory.indices.contains(index) {
            return chatHistory[index]
        }
        return nil
    }
    
    func canEnableUserInteraction(chat:QuestionDetail?) -> Bool {
        if let chatInfo = chat, !chatInfo.isHeader {
            return (chatInfo.parentId == currentParentType)
        }
        return false
    }
    
    func updateAns(For index:Int) {
        if let item = getItem(at: index) as? QuestionDetail {
            var ans = AnswerDetails()
            ans.questionId = item.questionId
            ans.answer = item.title
            ans.contactInfo = item.contactInfo
            currentParentType = ans.questionId
            updateChat(with: ans)
        }
    }
    
    func updateChat(with ans:AnswerDetails?) {
        if let answer = ans {
            chatHistory.append(answer)
        }
        
        if let qus = getChatData(), qus.count > 0 {
            chatHistory.append(contentsOf: qus)
            
        } else if let contact = (chatHistory.last as? AnswerDetails)?.contactInfo {
            NotificationCenter.default.post(name: Notification.Name(rawValue: kContact), object: nil, userInfo: [kContact:contact])
        }
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: kReloadView)))
    }
    
    func getChatData() -> Array<QuestionDetail>? {
        DataManager.fetchChatData(For:(chatHistory.last as? AnswerDetails)?.questionId ?? currentParentType)
    }
    
    func refreshChat() {
        chatHistory.removeAll()
        updateChat(with: nil)
    }
}
