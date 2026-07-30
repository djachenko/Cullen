//
//  SigningExpirationService.swift
//  Cullen

import Foundation
import UserNotifications

final class SigningExpirationService {
    private let notificationCenter: UNUserNotificationCenter
    private let logger: Logger?

    init(notificationCenter: UNUserNotificationCenter, logger: Logger?) {
        self.notificationCenter = notificationCenter
        self.logger = logger
    }
}

extension SigningExpirationService {
    func scheduleExpirationNotifications() async {
        guard let expirationDate = readExpirationDate() else {
            logger?.notice("no expiration date found in mobileprovision")
            return
        }

        logger?.info("expiration date: \(expirationDate.formatted())")

        let granted = await requestPermissionIfNeeded()

        guard granted else {
            logger?.notice("notification permission denied")
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
            let raw = String(data: data, encoding: .isoLatin1),
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

        return switch settings.authorizationStatus {
            case .authorized, .provisional:
                true
            case .notDetermined:
                (try? await notificationCenter.requestAuthorization(options: [.alert, .sound])) ?? false
            default:
                false
        }
    }

    func cancelExistingNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func scheduleNotifications(for expirationDate: Date) async {
        let now = Date()
        let daysLeft = Calendar.current.dateComponents([.day], from: now, to: expirationDate).day ?? 0

        logger?.info("scheduling notifications for \(daysLeft) days")

        for daysBefore in 1...max(1, daysLeft) {
            let fireDate = expirationDate.addingTimeInterval(-TimeInterval(daysBefore * 24 * 60 * 60))

            guard fireDate > now else {
                logger?.debug("skip day \(daysBefore) — fire date in the past")
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Cullen — истекает подпись"
            content.body = if daysBefore == 1 {
                "Завтра сборка истекает. Последний шанс пересобрать сегодня."
            } else {
                "Через \(daysBefore) дн. сборка перестанет запускаться. Пора пересобрать."
            }
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let notificationId = SigningExpirationService.notificationId(daysBefore: daysBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationId,
                content: content,
                trigger: trigger
            )

            try? await notificationCenter.add(request)
            logger?.debug("scheduled notification \(daysBefore) day(s) before at \(fireDate.formatted())")
        }
    }

    static func notificationId(daysBefore: Int) -> String {
        "cullen.signing.expiration.\(daysBefore)days"
    }
}
