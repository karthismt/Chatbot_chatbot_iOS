//
//  DataManager.swift
//  Chatbot
//
//  Created by Suganya Pongiyanasamy on 12/06/20.
//  Copyright © 2020 Suganya Pongiyanasamy. All rights reserved.
//

import Foundation
import SQLite3

enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

class DataManager: NSObject {
    
    static var manager: DataManager!
    private let dbPointer: OpaquePointer?
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    static func initDB() {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chatbot.sqlite")
        let isDBExist = FileManager.default.fileExists(atPath: fileURL.path)
        do {
            try DataManager.setupDBConnection(path: fileURL.path)
            if !isDBExist {
                manager.createRequiredTables()
            }
        } catch {
            fatalError("Unable to open database.")
        }
    }
    
    static func setupDBConnection(path: String) throws {
        var db: OpaquePointer?
        
        // 1
        if sqlite3_open(path, &db) == SQLITE_OK {
            // 2
            manager = DataManager(dbPointer: db)
            
        } else {
            // 3
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
        
    }
    
    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
}


////: ## Create Table

protocol SQLTable {
    static var createStatement: String { get }
}

extension Contact: SQLTable {
    static var createStatement: String {
        return """
        CREATE TABLE Contact(
        Id INT PRIMARY KEY NOT NULL,
        Name CHAR(255),
        MobileNo CHAR(255),
        EmailId CHAR(255),
        Address CHAR(255),
        Website CHAR(255)
        );
        """
    }
}

extension QuestionDetail: SQLTable {
    static var createStatement: String {
        return """
        CREATE TABLE QuestionMaster(
        Id INT PRIMARY KEY NOT NULL,
        Desc CHAR(255),
        ParentId CHAR(255),
        ContactId CHAR(255),
        LevelId CHAR(255),
        isHeader INT
        );
        """
    }
}

extension DataManager {
    
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        return statement
    }
}

extension DataManager {
    
    func createRequiredTables() {
        do {
            try DataManager.manager.createTable(table: Contact.self)
            try DataManager.manager.createTable(table: QuestionDetail.self)
        } catch {
            print(DataManager.manager.errorMessage)
        }
    }
    
    func createTable(table: SQLTable.Type) throws {
        // 1
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        // 2
        defer {
            sqlite3_finalize(createTableStatement)
        }
        // 3
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
}


//: ## Insert
extension DataManager {
    
    func downloadData(completion:@escaping  (_ success:Bool) -> Void) {
        
        let group = DispatchGroup()
        var dict = [String:[Dictionary<String,Any>]]()
        group.enter()
        downloadChatDetails(with: "http://karthiapi-001-site1.ftempurl.com/Questions/GetAllContactDetails", key: "ContactInfromation") { (dataArray) in
            dict["conatct"] = dataArray
            group.leave()
        }
        
        group.enter()
        downloadChatDetails(with: "http://karthiapi-001-site1.ftempurl.com/Questions/GetAllQuestionDetails", key: "QuestionMaster") { (dataArray) in
            dict["question"] = dataArray
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            do {
                try self.deleteAll()
            } catch {
                return
            }
            if let contact = dict["conatct"] {
                self.insertContactData(dataArray: contact)
            }
            
            if let question = dict["question"] {
                self.updateDBWithQuestionData(dataArray: question)
            }
            completion(true)
        }
    }
    
    func downloadChatDetails(with urlString:String, key:String, completion:@escaping  (_ dataArray: Array<Dictionary<String, Any>>) -> Void) {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, resosne, error) in
            if error == nil {
                do {
                    let json = (try JSONSerialization.jsonObject(with: data!) as? Dictionary<String, AnyObject>)?[key]
                    
                    if json is Dictionary<String, AnyObject> , let data = json as? Dictionary<String, AnyObject> {
                        completion([data])
                        
                    } else if json is Array<Dictionary<String, AnyObject>>, let data = json as? Array<Dictionary<String, AnyObject>> {
                        completion(data)
                    }
                } catch {
                    
                }
                
            }
        }
        task.resume()
    }
    
    
    func insertContactData(dataArray:[Dictionary<String,Any>]) {
        for dict in dataArray {
            let insertContact = """
            INSERT INTO
            Contact (Id, Name, MobileNo, EmailId, Address, Website)
            VALUES (\(dict["id"] ?? ""), '\(dict["name"] ?? "")', '\(dict["phoneNumber"] ?? "")', '\(dict["email"] ?? "")', '\(dict["Address"] ?? "")', '\(dict["website"] ?? "")')
            """
            do {
                try insertData(with: insertContact)
            } catch {
                print("Insertion failed")
            }
        }
    }
    
    func updateDBWithQuestionData(dataArray:[Dictionary<String,Any>]) {
        for dict in dataArray {
            let qId = dict["QID"] ?? ""
            let desc = dict["Desc"] ?? ""
            let parentId =  dict["ParentId"] ?? ""
            var contactId = dict["ContactId"] ?? ""
            contactId = (contactId is NSNull) ? "0" : contactId
            let levelId = dict["LevelId"] ?? ""
            let isHeader = dict["IsHeader"] ?? ""
            
            let insertQuery = """
            INSERT INTO
            QuestionMaster (Id, Desc, ParentId, ContactId, LevelId, isHeader)
            VALUES (\(qId), '\(desc)', \(parentId), \(contactId), \(levelId), \(isHeader))
            """
            do {
                try insertData(with: insertQuery)
            } catch {
                print("Insertion failed")
            }
        }
    }
    
    func insertData(with query:String) throws {
        let insertStatement = try prepareStatement(sql: query)
        defer {
            sqlite3_finalize(insertStatement)
        }
        
        if sqlite3_step(insertStatement) == SQLITE_DONE {
            
        } else {
            throw SQLiteError.Step(message: errorMessage)
        }
    }
    
    func  deleteAll() throws {
        var query = "DELETE FROM QuestionMaster"
        let statement1 = try prepareStatement(sql: query)
        sqlite3_step(statement1)
        sqlite3_finalize(statement1)

        query = "DELETE FROM Contact"
        let statement = try prepareStatement(sql: query)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }
}


//: ## Read
extension DataManager {
    
    static func fetchChatData(For questionId:Int) -> Array<QuestionDetail>? {
        
        let query = """
        SELECT
        QM.Id,
        QM.Desc,
        QM.ParentId,
        QM.isHeader,
        QM.LevelId,
        ifnull(C.Id,0),
        C.Address,
        C.EmailId,
        C.MobileNo,
        C.Name,
        C.Website
        FROM
        QuestionMaster AS QM
        LEFT OUTER JOIN Contact AS C ON C.Id = QM.ContactId
        WHERE
        QM.ParentId = \(questionId)
        ORDER BY
        QM.isHeader DESC, QM.Id
        """
        let dataArray = DataManager.fetchData(with: query)
        var data = Array<QuestionDetail>()
        
        for arr in dataArray {
            var detail = QuestionDetail()
            detail.questionId = arr[0] as? Int ?? 0
            detail.title      = arr[1] as? String ?? ""
            detail.parentId   = Int(arr[2] as? String ?? "0") ?? 0
            detail.isHeader   = ((arr[3] as? Int ?? 0) == 1)
            detail.levelId    = Int(arr[4] as? String ?? "0") ?? 0
            let contactId     = arr[5] as? Int ?? 0
            if contactId > 0 {
                var contact = Contact()
                contact.contactId = contactId
                contact.address  = arr[6] as? String ?? ""
                contact.emailId  = arr[7] as? String ?? ""
                contact.mobileNo = arr[8] as? String ?? ""
                contact.name     = arr[9] as? String ?? ""
                contact.website  = arr[10] as? String ?? ""
                detail.contactInfo = contact
            }
            data.append(detail)
        }
        return data
    }
    
    static private func fetchData(with query:String) ->  Array<Array<Any>> {
        var dataArray = Array<Array<Any>>()
        do {
            let statement = try DataManager.manager.prepareStatement(sql: query)
            defer {
                sqlite3_finalize(statement)
            }
            while (sqlite3_step(statement) == SQLITE_ROW){
               
                var  data = Array<Any>()
                let  column_count = sqlite3_column_count(statement);
                var index : Int32 = 0
                
                while index < column_count {
                   let type = sqlite3_column_type(statement, index);
                    switch type {
                    case 1:
                        data.append(Int(sqlite3_column_int(statement, index)))
                    case 2:
                       data.append(sqlite3_column_double(statement, index))
                    case 3:
                     data.append(String(cString: sqlite3_column_text(statement, index)))
                    case 5:
                       data.append("")
                    default:
                        break
                    }
                    index += 1
                }
                dataArray.append(data)
            }
            return dataArray
        } catch {
            return dataArray
        }
        
    }
    
}

