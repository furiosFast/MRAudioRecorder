//
//  Utils.swift
//  MRAudioRecorder
//
//  Created by Marco Ricca on 13/03/23.
//

import UIKit

/// Class that contains some static utility functions
class Utils {
    /// Short function for localizing a string
    /// - Parameter localizedKey: string key to localize
    static func loc(_ localizedKey: String) -> String {
        NSLocalizedString(localizedKey, comment: "")
    }

    /// Used for format date based on DateFormatter
    /// - Parameters:
    ///   - date: true if DateFormatter must contain the date
    ///   - time: true if DateFormatter must contain the time
    /// - Returns: an DateFormatter obj based on user Locale
    static func getLocalizedDateFormatter(date: Bool, time: Bool) -> DateFormatter {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = date ? .short : .none
        dateFormatter.timeStyle = time ? .short : .none
        dateFormatter.locale = Locale.autoupdatingCurrent

        return dateFormatter
    }

    /// Converts Date to String with format based on Locale
    /// - Parameter date: to convert to String with format based on Locale
    /// - Returns: converted Date to String with format based on Locale
    static func getPrintableDateTime(_ date: Date?) -> String {
        if date == nil {
            return ""
        }

        return getLocalizedDateFormatter(date: true, time: true).string(from: date!)
    }

    /// A concrete feedback generator that creates haptics to simulate physical impacts
    /// - Parameter style: style of the vibration
    static func vibrate(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
