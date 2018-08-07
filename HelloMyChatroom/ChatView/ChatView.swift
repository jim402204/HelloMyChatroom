

import UIKit

class ChatView: UIScrollView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    // Constants
    let padding : CGFloat = 20.0        //間隔距離
    // Variables
    var lastBubbleViewY:CGFloat = 0.0      //CGFloat 是ＵＩ座標計算用的（省去轉換）  裡面還是Double
    var allItems = [ChatItem]()             //所有的聊天記錄資料
    
    func add(chatItem:ChatItem) {
        
        // Create and add bubble view
        let bubbleView = ChatBubbleView(item: chatItem,
                maxChatViewWidth: self.frame.width, offsetY: lastBubbleViewY + padding)
        
        self.addSubview(bubbleView)
        
        //Adjust variables.
        lastBubbleViewY = bubbleView.frame.maxY     //下緣的y
        self.contentSize = CGSize(width: self.frame.width, height: lastBubbleViewY)
        
        //Keep chat item
        allItems.append(chatItem)
        
        //Scroll to bottom
        let leftBottomReect = CGRect(x: 0, y: lastBubbleViewY - 1, width: 1, height: 1)
        scrollRectToVisible(leftBottomReect, animated: true)    //自動捲動到 左下角(內)（1x1的小方塊）
    }
    
}

class ChatBubbleView: UIView {
    
    //Varibles and subviews
    var imageView: UIImageView?
    var textLable: UILabel?
    var backgroundImageView: UIImageView?
    var currentY: CGFloat = 0.0
    
    // Constant from chat view.
    let item:ChatItem
    var fullWidth: CGFloat
    let offsetY: CGFloat
    
    // Constant for dispaly.
    let sizePaddingRate: CGFloat = 0.02     //Rate 百分比
    let maxBubbleWidthRate: CGFloat = 0.7
    let contentMargin: CGFloat = 10.0       //距離    //內容內縮的距離
    let bubbleTailWidth: CGFloat = 10.0
    let textFontSize: CGFloat = 16.0
    
    init(item:ChatItem , maxChatViewWidth:CGFloat , offsetY: CGFloat){
        self.item = item
        self.fullWidth = maxChatViewWidth
        self.offsetY = offsetY
        super.init(frame: CGRect.zero)
        
        //step1: Decide a basic frame.
        self.frame = caculateBasicFrame()       //臨時的大小
        
        //step2: Decide imageview's frame
        prepareImageView()
        
        //step3: text lable's frame
        prepareTextLabel()
        
        //step4: Decide Final Size of bubble view.
        decideFinalSize()
        
        //step5: Decide Bubble view background.
        prepareBackgroundImageView()
        
    }
    
    required init?(coder aDecoder: NSCoder) {   //空殼用不到
        fatalError("init(coder:) has not been implemented")
    }
    
    private func caculateBasicFrame() -> CGRect{
        let sidePadding = fullWidth * sizePaddingRate           //與邊緣的距離
        let maxBubbleViewWidth = fullWidth * maxBubbleWidthRate //一個與寬的比例
        let offsetX :CGFloat
        
        if item.fromSelf  {
            offsetX = fullWidth - sidePadding - maxBubbleViewWidth//右邊訊息的起始點
        } else {    //From Others
            offsetX = sidePadding               //左邊訊息 邊緣距離
        }
        
        return CGRect(x: offsetX, y: offsetY, width: maxBubbleViewWidth, height: 10.0)
    }
    
    private func prepareImageView(){
        guard let image = item.image else {
            return
        }
        // Decide x and y.
        var x = contentMargin
        let y = contentMargin
        if !item.fromSelf {
            x += bubbleTailWidth    //配合圖片 尾巴
        }
        
        // Decide width and hight.
        let displayWidth = min(        //比大小 小的被return
            image.size.width, self.frame.width - 2 * contentMargin - bubbleTailWidth)
        
        let displayRatio = displayWidth / image.size.width  //為了維持等比例
        let displayHeight = image.size.width * displayRatio
        
        // Decide final frame.
        let dispalyFrame = CGRect(x: x, y: y, width: displayWidth, height: displayHeight)
        
        // Create and prepare image view.
        let photoImageView = UIImageView(frame: dispalyFrame)
        self.imageView = photoImageView
        photoImageView.image = image            //可以的話要resize
        photoImageView.layer.cornerRadius  = 5.0
        photoImageView.layer.masksToBounds = true   //角要切掉
        
        self.addSubview(photoImageView)
        currentY = photoImageView.frame.maxY    //為了文字鋪路 或者是後面的顯示
    }
    
    private func prepareTextLabel(){
        
        // Check if we should show text or not
        let text = item.message
        guard !text.isEmpty else{
            return
        }
        
        //Decide x and y
        var x = contentMargin
        let y = currentY + textFontSize/2       // 依照文字大小的一半比例來抓 間隔的距離(參考)
        //currentY 基底
        if !item.fromSelf {
            x += bubbleTailWidth    //配合圖片 尾巴
        }
        
        // Decide width and hight.
        let displayWidth = self.frame.width - 2 * contentMargin - bubbleTailWidth
        
        // Decide final frame of text label
        let displayFrame = CGRect(x: x, y: y, width: displayWidth, height: textFontSize)
        
        //Create and prepare text label
        let label = UILabel(frame: displayFrame)
        self.textLable = label
        label.font = UIFont.systemFont(ofSize: textFontSize)    //字型
        label.numberOfLines = 0 //Important !       //設定為0行 自動調配行數 隨內容而定
        label.text = text
        label.sizeToFit()   //important !          //內容多行時 會自動修正 縮小字型
        currentY = label.frame.maxY
        
        self.addSubview(label)
        currentY = label.frame.maxY
        
    }
    
    private func decideFinalSize(){
        
        var finalWidth: CGFloat = 0.0
        let finalHeight : CGFloat = currentY + contentMargin  //current文字下緣
        // Get width of image view.
        if let imageView = imageView{   //判斷有無nil
            if item.fromSelf{
                finalWidth = imageView.frame.maxX + contentMargin + bubbleTailWidth
            }else{  //From others.
                finalWidth = imageView.frame.maxX + contentMargin
            }
        }
        // Compare with width of text
        if let label = textLable {
            var tmpWidth: CGFloat
            if item.fromSelf {
                tmpWidth = label.frame.maxX + contentMargin + bubbleTailWidth
            }else{  //From others.
                tmpWidth = label.frame.maxX + contentMargin
            }
            finalWidth = max(finalWidth , tmpWidth)
        }
        // Final adjustment for a special case.
        if item.fromSelf && self.frame.width > finalWidth {
            self.frame.origin.x += self.frame.width - finalWidth
        }
        
        self.frame.size = CGSize(width: finalWidth, height: finalHeight)
        
        
    }
    
    
    private func prepareBackgroundImageView(){
        
        let image: UIImage?
        if item.fromSelf{          //insets 對上下左右 4切刀
            let insets = UIEdgeInsets(top: 14, left: 14, bottom: 17, right: 28)
            image = UIImage(named: "fromMe.png")?.resizableImage(withCapInsets: insets)
            //image 這是新的 resizableImage
        }else{  //from others.
            let insets = UIEdgeInsets(top: 14, left: 22, bottom: 17, right: 22)
            image = UIImage(named: "fromOthers.png")?.resizableImage(withCapInsets: insets)
        }
        let frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        let imageView = UIImageView(frame: frame)
        self.backgroundImageView = imageView
        imageView.image = image
        self.addSubview(imageView)  //越晚加入會疊在最上面
        self.sendSubview(toBack: imageView) //把剛剛加入的圖 放到最下層
        
    }
    
    
    
}


