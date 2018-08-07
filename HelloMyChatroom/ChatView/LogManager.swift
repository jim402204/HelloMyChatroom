

import Foundation
import SQLite

class LogManager {
    
    var messageIDs = [Int64]()   //messageIDs 計算用id 可能為插入時的表格row id
    
    static let LOG_TABLE_NAME = "log"
    static let MESSAGEID_KEY = "MessageID"
    
    //SQLite support
    var db : Connection!
    
    var logTable = Table(LOG_TABLE_NAME)
    
    var messageColumn = Expression<String>(MESSAGE_KEY)   //從server來
    var typeColumn = Expression<Int64>(TYPE_KEY)      //ios 5以下32bit 以上64bit
    var usernameColumn = Expression<String>(USERNAME_KEY)
    var idColumn = Expression<Int64>(ID_KEY)
    
    var midColumn = Expression<Int64>(MESSAGEID_KEY) //自定義 管理用
    
    var totalCount : Int {
        return messageIDs.count
    }
    
    init() {
        //假設 server有全部紀錄 直接撈盡cache
        //Prepare DB filename/path.
        
        let filemanager = FileManager.default
        guard let casheURL = filemanager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                assertionFailure("Fail to get Cashe folder path.")
                return  }
        
        let finalFullPAth = casheURL.appendingPathComponent("log.sqlite").path
        var isNewDB = false //check if this is the first time?
        if !filemanager.fileExists(atPath: finalFullPAth) {
            isNewDB = true  //新的表
        }
        
        // Preapre connection for DB
        do{
            db = try Connection(finalFullPAth)  //打開或創建 db
        }catch{
            assertionFailure("Open DB Fail")
            return
        }
        
        // Create table at the first time.
        if isNewDB {
            
            do{
                //產生sqlite 指令
                let command = logTable.create { (builder) in
                    
                    builder.column(midColumn, primaryKey: true)
                    builder.column(messageColumn)
                    builder.column(typeColumn)
                    builder.column(usernameColumn)
                    builder.column(idColumn)
                }
                try db.run(command) //執行指令
            }catch{
               assertionFailure("Fail to create DB")
            }
            
        } else {
            // SELECT * FROM "log".
            
            do {
                for message in try db.prepare(logTable){ //類似array的 Sequence
                    messageIDs.append(message[midColumn]) //這是下面的自訂函數
                }
            }catch{
                assertionFailure("Fail ti execute preare command: \(error)")
            }
            print("There are total \(messageIDs.count) messages in DB.")
        }
        
    }
    
    
    
    func append(message :[String:Any])  {
        
        let messageText = message[MESSAGE_KEY] as? String ?? ""
        let type = message[TYPE_KEY] as? Int64 ?? 0
        let username = message[USERNAME_KEY]as? String ?? ""
        let id = message[ID_KEY]as? Int64 ?? 0   //default values
        
        let command = logTable.insert(messageColumn <- messageText,
                                      typeColumn <- type,
                                      usernameColumn <- username,
                                      idColumn <- id
                                      )     //<- sqlite.swift 自定義的運算子
        do{
            let messageID = try db.run(command)  //retrun the insert’s rowid.
            messageIDs.append(messageID)
        }catch{
            assertionFailure("Fail to insert a message \(error) ")
        }
    }
    
    func getMessage(at:Int) -> [String:Any]? {
        
        guard at >= 0 && at < messageIDs.count else {
            assertionFailure("Invalid icdex")
            return nil
        }
        
        let targetMesageID = messageIDs[at]
        
        // Select * From "log" Where mid == xxxx   //可能不只一個
        let results = logTable.filter(midColumn == targetMesageID) //ex:Ｗhere id = 1
        
        // Pick the first one.
        do{
            //pluck針對一筆或多筆 中的第一筆
            guard let message = try db.pluck(results) else {
                assertionFailure("Fail to get the only result.")
                return nil }
            
            return [MESSAGE_KEY: message[messageColumn],
                    TYPE_KEY: Int(message[typeColumn]),
                    USERNAME_KEY: message[usernameColumn],
                    ID_KEY: Int(message[idColumn]),
            ]
        }catch{
            assertionFailure("Fail ti get target message: \(error)")
        }
        return nil
    }
    ////////////////////////////////////////////////////////////////////////
    
    // Photo Cash Support.
    func loadImage(_ filename:String) -> UIImage? {        //檔名 找資源轉路徑
        
        let fileURL = urlFor(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func saveImage(_ filename:String , data:Data){
        
        let fileURL = urlFor(filename)
        do{
            try data.write(to: fileURL)                 //暫存的 byte array 寫到指定資源
        }catch{
            assertionFailure("Fail to write data to file \(error)")
        }
    }
    
    private func urlFor(_ filename:String) -> URL{
       guard let cashURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        assertionFailure("Fail to get cashes url.") //實體機上 沒有效果
        abort()    //時機閃退                    //這要幹嘛
        }
        let hashFilename = String(format: "%ld", filename.hashValue)
        return cashURL.appendingPathComponent(hashFilename)   //取得路徑後 產生 對應命名的cashURL
        
        //透過hashFilename 來取得對應的url => cashURL.appendingPathComponent
    }
    
}
