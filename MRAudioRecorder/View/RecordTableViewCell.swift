//
//  RecordTableViewCell.swift
//  MRAudioRecorder
//
//  Created by Marco Ricca on 13/03/23.
//

import AVFAudio
import UIKit

/// Custom table view cell used for displaying recording info
class RecordTableViewCell: UITableViewCell {
    @IBOutlet var recTitle: UILabel!
    @IBOutlet var recDuration: UILabel!
    @IBOutlet var recDate: UILabel!
    @IBOutlet var playStopButton: UIButton!

    static let reuseIdentifier = "RecordTableViewCell"

    public var updateRecNameActionHandler: (() -> Void)?
    public var playStopActionHandler: (() -> Void)?

    public var recording: Recording?

    override func prepareForReuse() {
        recTitle.text = nil
        recDuration.text = nil
        recDate.text = nil

        if let recording = recording {
            updateUIAfterStopPlaying(recording: recording)
        }
        recording = nil
    }

    // MARK: - Public functions

    /// Sets all necessary customizations for all UI elements present in this Table Cell
    public func setupCellUI(recording: Recording) {
        self.recording = recording

        recTitle.text = recording.title
        recTitle.isUserInteractionEnabled = true
        recTitle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateRecTitle)))

        recDuration.text = recording.duration?.stringFromTimeInterval()

        recDate.text = Utils.getPrintableDateTime(recording.captureDate)

        playStopButton.addTarget(self, action: #selector(playStopRecording), for: .touchUpInside)
    }

    /// Updates the necessary UI elements after the audio player is stopped
    /// - Parameter recording: to stop to reproduce
    public func updateUIAfterStopPlaying(recording: Recording) {
        playStopButton.setImage(Icons.play_fill, for: .normal)
        recDuration.text = recording.duration?.stringFromTimeInterval()
    }

    // MARK: - Private functions

    /// When recTitle is touched, this function calls 'updateRecNameActionHandler' callback to do some actions
    @objc private func updateRecTitle() {
        RecordingManager.shared.audioRecorder == nil ? updateRecNameActionHandler?() : nil
    }

    /// When playStopButton is touched, this function calls 'playStopActionHandler' callback to do some actions
    @objc private func playStopRecording() {
        RecordingManager.shared.audioRecorder == nil ? playStopActionHandler?() : nil
    }
}
