//
//  AppDelegate.swift
//  MobilistenSDK
//
//  Created by venkat-12517 on 09/04/23.
//

import UIKit
import CoreData
import UserNotifications
import NotificationCenter
import Mobilisten

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let appKey = "<#Enter App Key#>"
        let accessKey = "<#Enter Access key#>"
        ZohoSalesIQ.initWithAppKey("CrBJ9braUTi6%2BlJlpTCY17FXh3JK8%2FnF3KcARWfLGRE%3D", accessKey: "aibwlL4DebUSXO0jpJylqVAlxEMo9skHl4A99bb5xIkSCh8EGoXPK1tSYazPc8puo5ghqbrG3LytxhbVmVsSl7Epsmt5rlrhY6cM%2BvCZGHeKlHgTAez3IIQJ%2FPIalR2h")
        ZohoSalesIQ.showLauncher(true)
        ZohoSalesIQ.delegate = self
        ZohoSalesIQ.Chat.delegate = self
        ZohoSalesIQ.FAQ.delegate = self
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Push Notification Handling
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format:
                                                                        "%02X", $1)})
        ZohoSalesIQ.enablePush(deviceTokenString, isTestDevice: true,mode: APNSMode.sandbox)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,didReceive
                                response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        if ZohoSalesIQ.isMobilistenNotification(response.notification.request.content.userInfo){
            switch response.actionIdentifier {
            case "Reply":
                ZohoSalesIQ.handleNotificationAction(response.notification.request.content.userInfo, response: (response as? UNTextInputNotificationResponse)?.userText)
                
            default: break
            }
            if response.actionIdentifier == UNNotificationDefaultActionIdentifier{
                ZohoSalesIQ.handleNotificationResponse(response.notification.request.content.userInfo)
            }
        }
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification
                     userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler:
                     @escaping (UIBackgroundFetchResult) -> Void)
    {
        ZohoSalesIQ.processNotificationWithInfo(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didReceive notification:
                     UILocalNotification)
    {
        ZohoSalesIQ.processNotificationWithInfo(notification.userInfo)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,willPresent
                                notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping
                                (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler(UNNotificationPresentationOptions.alert)
        ZohoSalesIQ.processNotificationWithInfo(notification.request.content.userInfo)
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "MobilistenSDK")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func requestNotificationPermissions(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            
            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                center.delegate = self
                if granted {
                    DispatchQueue.main.async {
                        let categoryOptions: UNNotificationCategoryOptions = []
                        let reply = UNTextInputNotificationAction(identifier: "Reply", title:"Reply", options: [], textInputButtonTitle:"Send", textInputPlaceholder: "Message")
                        let chatGrpMsgCategory = UNNotificationCategory(identifier: "GRPCHATMSG", actions: [reply], intentIdentifiers: [], options: categoryOptions)
                        UNUserNotificationCenter.current().setNotificationCategories([chatGrpMsgCategory])
                        application.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            let settings:UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories:nil )
            application.registerUserNotificationSettings(settings)
        }
        if let notificationData = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            ZohoSalesIQ.processNotificationWithInfo(notificationData)
        }
    }

}



extension AppDelegate: ZohoSalesIQDelegate, ZohoSalesIQChatDelegate, ZohoSalesIQFAQDelegate {
    func handleBotTrigger() {
        print("Bot triggered")
    }
    
    func agentsOnline() {
        print("AgentsOnline")
    }
    
    func agentsOffline() {
        print("AgentsOffline")
    }
    
    func supportOpened() {
        print("SupportOpened")
    }
    
    func supportClosed() {
        print("SupportClosed")
    }
    
    func chatViewOpened(id: String?) {
        print("ChatViewOpened : ",id as Any)
    }
    
    func chatViewClosed(id: String?) {
        print("ChatViewClosed : ",id as Any)
    }
    
    func homeViewOpened() {
        print("HomeViewOpened")
    }
    
    func homeViewClosed() {
        print("HomeViewClosed")
    }
    
    func visitorIPBlocked() {
        print("VisitorIPBlocked")
    }
    
    func handleTrigger(name: String, visitorInformation: Mobilisten.SIQVisitor) {
        print("handleTrigger : ", name)
        DataPrintUtils.shared.visitorDetails(visitorInformation)
    }
    
    func chatOpened(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatOpened")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func chatAttended(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatAttended")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func chatMissed(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatMissed")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func chatClosed(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatClosed")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func chatReopened(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatReopened")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func chatRatingRecieved(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatRatingRecieved")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func chatFeedbackRecieved(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatFeedbackRecieved")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func chatQueuePositionChanged(chat: Mobilisten.SIQVisitorChat?) {
        print("ChatQueuePositionChanged")
        DataPrintUtils.shared.chatDetails(chat)
    }
    
    func unreadCountChanged(_ count: Int) {
        print("UnreadCountChanged : ",count)
    }
    
    func shouldOpenURL(_ url: URL, in chat: Mobilisten.SIQVisitorChat?) -> Bool {
        print("ShouldOpenURL : ", url)
        return true
    }
    
    func articleOpened(id: String?) {
        print("ArticleOpened : ",id as Any)
    }
    
    func articleClosed(id: String?) {
        print("ArticleClosed : ",id as Any)
    }
    
    func articleLiked(id: String?) {
        print("ArticleLiked",id as Any)
    }
    
    func articleDisliked(id: String?) {
        print("ArticleDisliked : ",id as Any)
    }
}
