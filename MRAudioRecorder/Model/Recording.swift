//
//  Recording.swift
//  MRAudioRecorder
//
//  Created by Marco Ricca on 13/03/23.
//

import Foundation

/// Recording class that contains recording info
class Recording {
    var title: String?
    var captureDate: Date?
    var duration: TimeInterval?
    var fileUrl: URL?

    /// Initialize a new Recording obj
    /// - Parameters:
    ///   - title: recording title
    ///   - captureDate: recording date
    ///   - duration: recording duration
    ///   - fileUrl: path where is stored the recording file
    init(title: String, captureDate: Date, duration: TimeInterval, fileUrl: URL) {
        self.title = title
        self.captureDate = captureDate
        self.duration = duration
        self.fileUrl = fileUrl
    }
}
