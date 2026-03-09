import Foundation

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var dateOnlyString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

extension Int {
    var displayDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(self) / 1000)
        return date.shortDateString
    }
}

extension String {
    var asDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) { return date }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: self) { return date }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: self)
    }

    var displayDate: String {
        asDate?.shortDateString ?? self
    }
}
