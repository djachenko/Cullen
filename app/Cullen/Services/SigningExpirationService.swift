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
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: NotificationId.all
        )
    }

    func scheduleNotifications(for expirationDate: Date) async {
        let now = Date()

        for offset in NotificationOffset.all {
            let fireDate = expirationDate.addingTimeInterval(-offset.secondsBefore)

            guard fireDate > now else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Cullen — истекает подпись"
            content.body = offset.body
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: offset.notificationId,
                content: content,
                trigger: trigger
            )

            try? await notificationCenter.add(request)
        }
    }
}

private extension SigningExpirationService {
    enum NotificationOffset {
        case twoDays
        case oneDay

        static let all: [NotificationOffset] = [.twoDays, .oneDay]

        var secondsBefore: TimeInterval {
            switch self {
            case .twoDays:
                2 * 24 * 60 * 60
            case .oneDay:
                1 * 24 * 60 * 60
            }
        }

        var body: String {
            switch self {
            case .twoDays:
                "Через 2 дня сборка перестанет запускаться. Пора пересобрать."
            case .oneDay:
                "Завтра сборка истекает. Последний шанс пересобрать сегодня."
            }
        }

        var notificationId: String {
            switch self {
            case .twoDays:
                NotificationId.twoDaysBefore
            case .oneDay:
                NotificationId.oneDayBefore
            }
        }
    }

    enum NotificationId {
        static let twoDaysBefore = "cullen.signing.expiration.2days"
        static let oneDayBefore = "cullen.signing.expiration.1day"

        static let all: [String] = [twoDaysBefore, oneDayBefore]
    }
}
