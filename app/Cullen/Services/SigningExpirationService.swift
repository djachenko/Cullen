//
//  SigningExpirationService.swift
//  Cullen

import Foundation
import UserNotifications

final class SigningExpirationService {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
    }
}

extension SigningExpirationService {
    func scheduleExpirationNotifications() async {
        guard let expirationDate = readExpirationDate() else {
            return
        }

        let granted = await requestPermissionIfNeeded()

        guard granted else {
            return
        }

        await cancelExistingNotifications()
        await scheduleNotifications(for: expirationDate)
    }
}

private extension SigningExpirationService {
    func readExpirationDate() -> Date? {
        guard
            let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
            let data = try? Data(contentsOf: url),
            let raw = String(data: data, encoding: .ascii),
            let xmlStart = raw.range(of: "<?xml"),
            let xmlEnd = raw.range(of: "</plist>")
        else {
            return nil
        }

        let xml = String(raw[xmlStart.lowerBound...xmlEnd.upperBound])

        guard
            let xmlData = xml.data(using: .utf8),
            let plist = try? PropertyListSerialization.propertyList(
                from: xmlData,
                options: [],
                format: nil
            ) as? [String: Any]
        else {
            return nil
        }

        return plist["ExpirationDate"] as? Date
    }

    func requestPermissionIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            let granted = (try? await notificationCenter.requestAuthorization(options: [.alert, .sound])) ?? false
            return granted
        default:
            return false
        }
    }

    func cancelExistingNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func scheduleNotifications(for expirationDate: Date) async {
        let now = Date()
        let daysLeft = Calendar.current.dateComponents([.day], from: now, to: expirationDate).day ?? 0

        for daysBefore in 1...max(1, daysLeft) {
            let fireDate = expirationDate.addingTimeInterval(-TimeInterval(daysBefore * 24 * 60 * 60))

            guard fireDate > now else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Cullen — истекает подпись"
            content.body = daysBefore == 1
                ? "Завтра сборка истекает. Последний шанс пересобрать сегодня."
                : "Через \(daysBefore) дн. сборка перестанет запускаться. Пора пересобрать."
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "cullen.signing.expiration.\(daysBefore)days",
                content: content,
                trigger: trigger
            )

            try? await notificationCenter.add(request)
        }
    }
}

private extension SigningExpirationService {
    enum NotificationId {
        static func identifier(daysBefore: Int) -> String {
            "cullen.signing.expiration.\(daysBefore)days"
        }
    }
}
