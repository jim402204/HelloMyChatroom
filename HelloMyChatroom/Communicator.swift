

import Foundation
import Alamofire    //跟網路相關

typealias DoneHandler = (_ error:Error?,_ result:[String: Any]?) ->Void
//通用                        //回傳 字典（因為三方外掛會幫弄好成字典）

typealias DownloadDoneHandler = (_ error:Error?,_ result:Data?) ->Void
//另外用

let GROUPNAME = "CP101"
let MY_NAME = "jim"

//  通訊元件常會用單例模式
class Communicator {
    
    
    //連接某個測試用的server   //為了切換測試站 與 正式站
    
    // Constants
    #if DEBUG               //自定義 編譯分支 （要設定DEBUG=多少）
    static let BASEURL = "http://class.softarts.cc/PushMessage/"  //假想正式網站
    #else
    static let BASEURL = "http://class.softarts.cc/PushMessage/"    //假想測試網站
    #endif
    
    let UPDATEDEVICETOKEN_URL = BASEURL + "updateDeviceToken.php"
    let RETRIVE_MESSAGES_URL = BASEURL + "retriveMessages2.php"
    let SEND_MESSAGE_URL = BASEURL + "sendMessage.php"
    let SEND_PHOTOMESSAGE_URL = BASEURL + "sendPhotoMessage.php"
    let PHOTO_BASE_URL = BASEURL + "photos/"
    
    // Singleton instance.
    static let shared = Communicator()
    
    private init(){
        
    }
    
    //Variables  // 保存 Token
    var accessToken = ""  //假如有跟伺服器取得的通訊代碼，可以儲存在這
    
    //送出deviceToken給伺服器
    func updateDeviceToken(_ deviceToken:String , doneHandler: @escaping DoneHandler) {
        
        let parameters = [GROUPNAME_KEY : GROUPNAME,
                          USERNAME_KEY : MY_NAME,
                          DEVICETOKEN_KEY : deviceToken]        //字典
        
        doPost(UPDATEDEVICETOKEN_URL, parameters: parameters , doneHandler: doneHandler)    //網路的通訊幾乎是非同步
    }
    
    func sendTextMessage(_ message:String , doneHandler: @escaping DoneHandler) {
        
        let parameters = [GROUPNAME_KEY : GROUPNAME,
                          USERNAME_KEY : MY_NAME,
                          MESSAGE_KEY : message]        //沒有s key

        doPost(SEND_MESSAGE_URL, parameters: parameters , doneHandler: doneHandler)
    }
    
    func retrieveMessage(_ fromID:Int , doneHandler: @escaping DoneHandler) {
        //編號大於fromID才給我
//        let parameters = [GROUPNAME_KEY : GROUPNAME,
//                          LASTMESSAGE_ID_KEY : fromID] as [String : Any] Any 文字跟圖片
        
        let parameters: [String : Any] = [GROUPNAME_KEY : GROUPNAME,
                                          LASTMESSAGE_ID_KEY : fromID]

        doPost(RETRIVE_MESSAGES_URL, parameters: parameters , doneHandler: doneHandler)
    }
    
    
    
    
    func downloadPhoto(_ filename:String, doneHandler: @escaping DownloadDoneHandler)  {
        
        let finalURLString = PHOTO_BASE_URL + filename
        Alamofire.request(finalURLString).responseData { (respone) in   //可直接取json
            
            switch respone.result{
            case .success(let data):
                print("Download OK: \(data)")
                doneHandler(nil,data)
            case .failure(let error):
                print("Download Fail: \(error)")
                doneHandler(error,nil)
            }
            
        }
    }
    
    func sendPhotoMessage(_ data:Data , doneHandler: @escaping DoneHandler) {
        
        let parameters = [GROUPNAME_KEY : GROUPNAME,
                          USERNAME_KEY : MY_NAME]
    
        doPost(SEND_PHOTOMESSAGE_URL,
               parameters: parameters,
               data: data,
               doneHandler: doneHandler)
    }
    
    private func handlerJSONResponse(_ response: DataResponse<Any> //套件的自訂型別 才能用下面的sw
        ,doneHandler: DoneHandler){
        //這邊 只有判斷 回傳結果是否符合 server的傳輸格式 解json在其他步驟中
        
        switch response.result{     //這邊sever回傳的是json物件 而非字串
        case .success(let json):  //屬性 get取用         //請求成功 但參數不見得正確
            print("Get Respond: \(json)")
            //Check if server result is true of false
            //是否回傳的資料符合dictionary格式
            guard let finalJSON = json as? [String: Any] else{
                //fail due to  invalid json
                let error = NSError(domain: "Server respone is not dictionary", code: -1, userInfo: nil)
                doneHandler(error,nil)
                return
            }
            //是否回傳的資料有"result"這個屬性，且能轉型為Bool
            guard let serverResult = finalJSON[RESULT_KEY]as? Bool else {
                //fail due to  invalid json
                let error = NSError(domain: "Server respone don't include result field", code: -1, userInfo: nil)
                doneHandler(error,nil)
                return
            }
            if serverResult{
                //Real success!
                doneHandler(nil,finalJSON)
            }else{
                //Server result fail!
                let error = NSError(domain: "Server respone result fail.", code: -1, userInfo: nil)
                doneHandler(error,finalJSON)
            }
        case .failure(let error):
            print("Fail with Error: \(error)")
            doneHandler(error,nil)
        }
        
        
    }
    
    
    
    private func doPost(_ urlString:String,parameters:[String: Any],doneHandler: @escaping DoneHandler){
        //簡單來說 把json object 序列化成 byte array = data 再由data編碼為字串
        
        //JSONSerialization 可以把josn轉成 字典  (反了)
        //Prepare "data={....}" content
        let jsonData = try! JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)         //先做資料(model)做序列化
        
        let jsonString = String(data: jsonData , encoding: .utf8)! //轉成json字串
        let finalParamemter = [DATA_KEY: jsonString]  //配合server 傳遞dictionary
        //////////////////////////////////////////////////////////////////////
        
        //finalParamemter 是要client端 跟 server一樣
        //URLEncoding.default  jsonEncode.deault //nil 參數可刪？
        //要收的是什麼選擇不同的response..
        Alamofire.request(urlString, method: .post , parameters: finalParamemter, encoding: URLEncoding.default ).responseJSON { (response) in
            
            self.handlerJSONResponse(response, doneHandler: doneHandler)

            //.....
        }
        
    }
    
    
    private func doPost(_ urlString:String,
                        parameters:[String: Any],
                        data:Data,
                        doneHandler: @escaping DoneHandler){
        
        let jsonData = try! JSONSerialization.data(withJSONObject: parameters,       options: .prettyPrinted)   //序列化
        
        Alamofire.upload(multipartFormData: { (formData) in //這個格式可以傳 多段合再一起
            //append fileURL 是基本取得檔。data 都是暫存檔會吃暫存記憶體 太多cash
            formData.append(jsonData, withName: DATA_KEY)
            formData.append(data, withName: "fileToUpload", fileName: "image.jpg", mimeType: "image/jpg")                   //主要名稱看的是fileToUpload
            //mimeType WWW定義的規格  （樣子）主type/sub type（http）
            
        }, to: urlString, method: .post) { (encodingResult) in
            
            switch encodingResult{
            //                case .success(let request,let streamingFromDisk, let streamFileURL):
            case .success(let request, _, _):
                print("Encode OK")
                request.responseJSON(completionHandler: { (respone) in
                    //...
                    self.handlerJSONResponse(respone, doneHandler: doneHandler)
                    
                })
            case .failure(let error):
                print("Encoding Fail: \(error)")
                doneHandler(error,nil)
            }
            
            
            
        }   //http head 有時候也會用  第一個closure 是設定multi   第二個closure 編碼的結果
        //條server設定 原50M 可以往上設 200Ｍ
    }
    
    
    
    
    
}
