

import UIKit
import Photos
import MobileCoreServices


extension ViewController: UITextFieldDelegate {
    
    //MARK: - 按下return鍵觸發，換行就return true 不換行 return false     這是定式
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTextbt(self)
        return false
    }
}

extension ViewController: UIImagePickerControllerDelegate ,UINavigationControllerDelegate{
    
    //MASK: - UIImagePickerController && protpcol Methods
    func lauchPicker(forType: UIImagePickerControllerSourceType)  {
        
        //Check if this is a valid sourse type
        guard  UIImagePickerController.isSourceTypeAvailable(forType) else {
            return print("Invalid sourse type")
        }//有無可用的裝置
        
        let picker = UIImagePickerController()
        //        picker.mediaTypes = ["public.image","public.movie"]
        picker.mediaTypes = [kUTTypeImage as String,kUTTypeMovie as String]
        //CF String 是c語言的
        picker.sourceType = forType
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) { //會帶回來字典 跟使用者的內容
        print("didFinishPickingMediaWithInfo: \(info)")
        //info裡面儲存很多資訊、假如是拍照得到的照片->甚至可以得到亮度...等等攝影資訊
        guard let type = info[UIImagePickerControllerMediaType]as? String else {
            return assertionFailure("Invalid type") }
        
        if type == (kUTTypeImage as String) {
            guard let originalImage = info[UIImagePickerControllerOriginalImage]as? UIImage else{
                return assertionFailure("No Original image.")
            }
            //            print("Original image: \(originalImage.size)")
            //            let pngData = UIImagePNGRepresentation(originalImage)
            //            let jpgData = UIImageJPEGRepresentation(originalImage, 0.8)
            //            print("pngData: \(pngData!.count) bytes, jpgData: \(jpgData!.count) bytes.")
            //
            // Resize originalImage
            guard let resizedImage = originalImage.resize(maxWidthHeight: 1000) else{
                return assertionFailure("Fail to resize.")
            }
            print("resized Image: \(resizedImage.size)")
            let pngData2 = UIImagePNGRepresentation(originalImage)
            
            guard let jpgData2 = UIImageJPEGRepresentation(originalImage, 0.8) else{
                return assertionFailure("Fail to generate JPG file. ")
            }
            print("pngData: \(pngData2!.count) bytes, jpgData: \(jpgData2.count) bytes")
            
            communicator.sendPhotoMessage(jpgData2) { (error, result) in
                if let error = error {
                    print("sendPhotoMessage Fail: \(error)")
                    return
                }else if let result=result{
                    print("sendPhotoMessage OK:\(result)")
                    self.doRefresh()
                }
            }
            
        } else if type == (kUTTypeMovie as String){
            //..
        }
        picker.dismiss(animated: true) //Important !  把picker 收起來
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var chatView: ChatView!
    
    var lastMessageID = 1         //php  不適合用0
    var incomingMessage = [[String:Any]]()      //array 裡放入dictionay //視窗中的內容
    let communicator = Communicator.shared
    let logManager = LogManager()   //資料庫
    
    let retiveLock = NSLock()       //同步鎖
    var shouldRetriveAgain = false  //是否接收下一筆資料的旗標
    
    
    @IBAction func sendTextbt(_ sender: Any) {  //UIbutton 改ＡＮＹ可以放控制器
        
        guard let message = inputTextField.text , !message.isEmpty else {
            return          // =>message.isEmpty == false
        }
        //Dismiss keyboard.
        inputTextField.resignFirstResponder()       //放棄第一個目標。配合UITextFieldDelegate
        
        //Send Text Message
        communicator.sendTextMessage(message) { (error, result) in
            if let error = error {
                print("sendTextMessage Fail: \(error)")
                return
            }else if let result=result{
                print("sendTextMessage OK:\(result)")
                self.doRefresh()       //server 發送推播 不會發給自己 自己刷新抓取
            }
        }
        
    }
    
    @IBAction func sendPhotobt(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Choose photo from:", message: nil, preferredStyle: .alert)
        let library = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            self.lauchPicker(forType: .photoLibrary)
        }
        let camera = UIAlertAction(title: "Camera", style: .default) { (action) in
              self.lauchPicker(forType: .camera)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(library)
        alert.addAction(camera)
        alert.addAction(cancel)
        present(alert,animated: true)
    }
    
    @IBAction func refreshbt(_ sender: UIButton) {//手動刷新
        doRefresh()
    }
    
    
    @objc       //swift4 才有的
    func doRefresh() {
        // Critical section.    *這兩種方式都apply特有 其他swift平台 沒得用*
//        objc_sync_enter(self) //任何物件都可以 這用self  //跟lock很像 會卡死第二個
//        //...
//        objc_sync_exit(self)   //適合用在循序的執行
        //下載聊天內容
        
        //Preare multi-executes.
        guard retiveLock.try() else {  //NSLock 鎖住第一個 lock方法的話 第二個會卡死在這邊
            shouldRetriveAgain = true   //紀錄同時間又有更新 需要再次reflesh
            return
        }//上鎖功能
        
        
        communicator.retrieveMessage(lastMessageID) { (error, result) in
            if let error = error {
                self.unlockRetriveLock()       //要堵住所有出口
                print("sendTextMessage Fail: \(error)")
                return
            }
            guard let result = result else {
                self.unlockRetriveLock()
                return  assertionFailure("Invalid result")  //不該進來這
            }
            guard let messages = result[MESSAGES_KEY]as? [[String:Any]] else{
                //因為 格式是「data,內容＝key valus」
                //MESSAGES_KEY  有帶s的
                self.unlockRetriveLock()
                return print("No message array exist")
            }
            guard messages.count > 0 else{   //有可能 收到的array 是空的
                self.unlockRetriveLock()
                return print("No new message")
            }
            //Get and update last messageID
            if let lastItem = messages.last , let newLastMessageID = lastItem[ID_KEY]as?Int {
                self.lastMessageID = newLastMessageID
                //Save into userddefaults.
                let userDefaults = UserDefaults.standard
                userDefaults.set(newLastMessageID, forKey: LASTMESSAGE_ID_KEY)
                userDefaults.synchronize()          //ios 10 以前 都必須加入
            }
            
            // Save messges into log manager.
            for message in messages{
                self.logManager.append(message: message)
            }
            
            //Handle incoming messages
            self.incomingMessage += messages     //array相加？？？？  串接 ？？
            self.handleIncomingMessage()        //開始 一筆一筆迭代處理
        }
    }//func
    
    //解鎖函數
    func unlockRetriveLock()  {
        
        retiveLock.unlock()
        //Retive again if there is any message received current retrive job
        if shouldRetriveAgain {
            shouldRetriveAgain = false
            doRefresh()
        }
        
    }
    
    
    func handleIncomingMessage(){
        //Get the first one and check if incomingMessage is empty
        guard let item = incomingMessage.first else {   //第一個拿不到 空的資料
            unlockRetriveLock()     //都沒資料了可以解鎖 ＊這邊是最主在的＊
            return
        }
        incomingMessage.removeFirst()       //？？第一筆 處理後清除掉  //好像是輪詢的概念 用過就刪
        let message = item [MESSAGE_KEY] as? String ?? ""   // 我錯誤的地方
//        let type = item [TYPE_KEY]as? Int ?? 0
        let type = ChatItemType(rawValue: item [TYPE_KEY]as? Int ?? 0)
            ?? ChatItemType.text    //預留 預設型別
        let username = item [USERNAME_KEY]as? String ?? ""
        let id = item [ID_KEY]as? Int ?? 0   //default values
        let formSelf = (username == MY_NAME)
        
        let finalMessage = "\(username):\n \(message) id: \(id)"  //文字串接
        
        
        var chatItem = ChatItem(message: finalMessage, type: type, username: username, id: id, image: nil
            , fromSelf: formSelf )
        
        
        if type == .text{   //Text Message  // 0 1 是hardcode 最好轉成enum
            //抓這兩點。在看詳細內容 message 有無職
            //Show test message...
            
            chatView.add(chatItem: chatItem)
            handleIncomingMessage()                 //處理下一則訊息
            
        }else if type == .photo {    //Photo Message
            //Check if we can pick the photo form local cache.
//            let image = self.logManager.loadImage(message)  //下載看看
            
            if let image = self.logManager.loadImage(message){ //message json字串
                chatItem.image = image
                self.chatView.add(chatItem: chatItem)
                self.handleIncomingMessage()    //important
                return   //從本地資料庫撈看看
            }
            
            //Download  Photo and show photo Message.. //本地無圖片要下載
            communicator.downloadPhoto(message) { (error, data) in
                //message 這邊的可能是 server圖片的網址
                if let error = error {
                    print("DownloadPhoto Photo Fail: \(error)")
                    return
                }else if let data = data {
                    chatItem.image = UIImage(data: data)
                    self.chatView.add(chatItem: chatItem)
                    
                    //Save Image.
                    self.logManager.saveImage(message, data: data)
                }
                self.handleIncomingMessage()    //important   //下載時完成處理訊息才 處理下一訊息
                //Alamofire。處理回來是在 前景 不像taskdata 會在背景
            }
            
        }else{
            //
            handleIncomingMessage()
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Ask user's permission to access photos library.
        PHPhotoLibrary.requestAuthorization { (status) in
            print("PHPhotoLibrary.requestAuthorization: \(status.rawValue)")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(doRefresh), name: .didReceiveRomoteMessage, object: nil)
        
        // Load last message
        lastMessageID = UserDefaults.standard.integer(forKey: LASTMESSAGE_ID_KEY)
        //  UserDefaults （int）若沒資料 會拿到０
        if lastMessageID <= 0 { //Workaround for the first time app launth.
            lastMessageID = 1
        }
        #if DEBUG
//            lastMessageID = 1 //Hardcode for test only.
        
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {//從最近20筆 下載
        super.viewDidAppear(animated)
        
        let startIndex : Int = {
            //變數計算的內容 最後回傳
            var result = logManager.totalCount - 20
            if result < 0{
                result = 0
            }
            return result
        }()
        
        for i in 0..<(logManager.totalCount - startIndex) {
            
            guard let message = logManager.getMessage(at: startIndex + i) else {
                assertionFailure("Fail ti get message.")
                continue }
            incomingMessage.append(message)
            //incomingMessage可能是暫存的 給handleIncomingMessage處理
        }
        handleIncomingMessage() //Important!
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

