// TEMPLATE ONLY — this file is not part of any Xcode target and does nothing
// on its own. After creating the "Notification Service Extension" target in
// Xcode (File → New → Target → Notification Service Extension, named
// "NotificationService"), copy this entire content into the
// NotificationService.swift file Xcode generates inside that new target's
// folder, replacing its default stub content. Then delete this file.

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // FCM places the image URL under "fcm_options" -> "image" in the
        // notification payload's userInfo when the backend's Admin SDK call
        // sets `notification.imageUrl` (see backend/routes/notifications.js).
        guard let imageUrlString = imageUrl(from: request.content.userInfo),
              let url = URL(string: imageUrlString) else {
            contentHandler(bestAttemptContent)
            return
        }

        downloadImage(from: url) { attachment in
            if let attachment = attachment {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }

    // Called just before the extension's ~30-second time budget runs out —
    // must deliver *something* now, even without the image, or the
    // notification is dropped entirely.
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func imageUrl(from userInfo: [AnyHashable: Any]) -> String? {
        if let fcmOptions = userInfo["fcm_options"] as? [AnyHashable: Any],
           let url = fcmOptions["image"] as? String {
            return url
        }
        // Some payload shapes place it directly under "image" — fall back to that.
        return userInfo["image"] as? String
    }

    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { downloadedUrl, response, error in
            guard let downloadedUrl = downloadedUrl, error == nil else {
                completion(nil)
                return
            }

            // UNNotificationAttachment needs a proper file extension to infer
            // the correct content type.
            let fileExtension = (response?.suggestedFilename as NSString?)?.pathExtension ?? url.pathExtension
            let fileName = UUID().uuidString + "." + (fileExtension.isEmpty ? "jpg" : fileExtension)
            let localUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try FileManager.default.moveItem(at: downloadedUrl, to: localUrl)
                let attachment = try UNNotificationAttachment(identifier: fileName, url: localUrl, options: nil)
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}

