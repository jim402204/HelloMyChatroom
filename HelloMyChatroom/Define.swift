//放通用的定義

import Foundation

// JSON Keys                //跟server 上面定義的有關
let ID_KEY = "id"
let USERNAME_KEY = "UserName"
let MESSAGES_KEY = "Messages"
let MESSAGE_KEY = "Message"
let DEVICETOKEN_KEY = "DeviceToken"
let GROUPNAME_KEY = "GroupName"
let LASTMESSAGE_ID_KEY  = "LastMessageID"
let TYPE_KEY = "Type"
let DATA_KEY = "data"
let RESULT_KEY = "result"

extension Notification.Name {
    
    static let didReceiveRomoteMessage = Notification.Name("didReceiveRomoteMessage")
    //
    //...
    
}
