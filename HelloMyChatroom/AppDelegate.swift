

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?         //大小會變

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Ask user's permission.
        let center = UNUserNotificationCenter.current()//幾乎都是單例模式
        
        center.requestAuthorization(options: [.alert,.badge,.sound]) { (grant, error) in
            // 文字訊息 左上角的小圖題（標數字(多少未讀)）發出聲音
            if let error = error {
                print("requestAuthorization is nil\(error)")
            }
            print("User grant the permission: " + (grant ? "Yes":"No"))
        }
        //Ask devices token  推播要用
        application.registerForRemoteNotifications() //網路 發出註冊。//註冊devices token
        
        //這好像只會詢問第一次
        
        return true
    }//取得授權
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {    //NSdata 資料型態
        
        //convert deviceToken to String.            //一個byte一個byte轉成字串
//        let deviceTokenString = deviceToken.map { (byte) -> String in
//            return String(format: "%02x", byte )
//        }.joined()                  //array join成字串
        
        let deviceTokenString = deviceToken.map {
            String(format: "%02x", $0 )                 //這樣一定是closure
        }.joined()
        print("deviceTokenString \(deviceTokenString)")     //deviceToken 32byte
        
        Communicator.shared.updateDeviceToken(deviceTokenString) { (error, result) in
            
            if let error = error{
                print("updateDeviceToken fail: \(error)")
                return
            }else if let result = result{
                print("updateDeviceToken OK: \(result)")       //下載
            }
        }
        
    }//註冊成功
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }//註冊失敗
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {//收到通知（網路）
        
        print("didReceiveRemoteNotification\(userInfo)") //通知  pas plor 機制？
        
        NotificationCenter.default.post(name: .didReceiveRomoteMessage, object: nil)//發通知（本地）
        
    }
    
    
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        //Resign 放棄 辭職。Active 在前景的狀態。 將進入背景。 用來存檔的動作
        // 如果電話來時 會放棄前景（進入聽電話狀態） 但不會進去背景。電話完後回到 之前的前景
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //進入了背景
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        //將回到前景
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        //回到前景
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        //當正在用的狀態。被終止 會在這通知（前景）        在背景沒有用
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

