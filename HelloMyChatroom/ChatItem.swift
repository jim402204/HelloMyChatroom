
import UIKit //範圍比 基本的上 能用ＵＩ

struct ChatItem {
    var message: String
    let type: ChatItemType
    let username : String
    let id: Int
    // Optional variables.
    var image: UIImage?
    var fromSelf = false    //分別 對話者你 跟 我
    
    
}

enum ChatItemType: Int {
    case text = 0
    case photo = 1
}
