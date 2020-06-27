/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UserNotifications
import CoreData

class NotificationService: UNNotificationServiceExtension {
  
  lazy private var persistentContainer: NSPersistentContainer = {
    let groupName = "group.com.raywenderlich.PushNotifications"
    let url = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: groupName)!
      .appendingPathComponent("PushNotifications.sqlite")
    
    let container = NSPersistentContainer(name: "PushNotifications")
    
    container.persistentStoreDescriptions = [
      NSPersistentStoreDescription(url: url)
    ]
    
    container.loadPersistentStores(completionHandler: { _, error in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    
    return container
  }()
  
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?
  
  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    
    if let bestAttemptContent = bestAttemptContent {
      bestAttemptContent.title = ROT13.shared.decrypt(bestAttemptContent.title)
      bestAttemptContent.body = ROT13.shared.decrypt(bestAttemptContent.body)

      if let urlPath = request.content.userInfo["media-url"] as? String,
        let url = URL(string: ROT13.shared.decrypt(urlPath)) {
        
        let destination = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(url.lastPathComponent)
        
        do {
          let data = try Data(contentsOf: url)
          try data.write(to: destination)
          
          let attachment = try UNNotificationAttachment(identifier: "",
                                                        url: destination)
          
          bestAttemptContent.attachments = [attachment]
        } catch {
          // Nothing to do here.
        }
      }
      
      if let incr = bestAttemptContent.badge as? Int {
        switch incr {
        case 0:
          UserDefaults.extensions.badge = 0
          bestAttemptContent.badge = 0
        default:
          let current = UserDefaults.extensions.badge
          let new = current + incr

          UserDefaults.extensions.badge = new
          bestAttemptContent.badge = NSNumber(value: new)
        }
      }
      
      contentHandler(bestAttemptContent)
    }
  }
  
  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
  
}
