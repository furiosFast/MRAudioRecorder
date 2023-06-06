//
//  ViewController.swift
//  MRAudioRecorder
//
//  Created by Marco Ricca on 13/03/23.
//

import AVFAudio
import UIKit

/// The View Controller which is presented at app startup and which allows the recording and playback of audio files
class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var emptyStateViewContainer: UIView!
    @IBOutlet var emptyStateImage: UIImageView!
    @IBOutlet var emptyStateTitle: UILabel!
    @IBOutlet var emptyStateMessage: UILabel!

    @IBOutlet var tableView: UITableView!

    @IBOutlet var footerViewContainer: UIView!
    @IBOutlet var footerViewTitle: UILabel!
    @IBOutlet var footerViewTimer: UILabel!
    @IBOutlet var footerViewButton: RecordButton!

    private var displaylink: CADisplayLink?
    private var indexPathWithPlayTappedButton: IndexPath?
    private var cellWithPlayTappedButton: RecordTableViewCell?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        askMicrophonePermission()

        displaylink = CADisplayLink(target: self, selector: #selector(updateMeters))
        displaylink?.isPaused = true
        displaylink?.add(to: .main, forMode: .default)
    }

    // MARK: - TableView

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return RecordingManager.shared.recordings.count
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! RecordTableViewCell
        if cellWithPlayTappedButton != nil, cellWithPlayTappedButton == cell, let indexPathWithPlayTappedButton = indexPathWithPlayTappedButton, indexPathWithPlayTappedButton == indexPath {
            if let audioPlayer = RecordingManager.shared.audioPlayer, audioPlayer.isPlaying {
                cell.recDuration.text = audioPlayer.currentTime.stringFromTimeInterval()
                cell.playStopButton.setImage(Icons.stop_fill, for: .normal)
                
                displaylink?.isPaused = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! RecordTableViewCell
        if cellWithPlayTappedButton != nil, cellWithPlayTappedButton == cell, let indexPathWithPlayTappedButton = indexPathWithPlayTappedButton, indexPathWithPlayTappedButton == indexPath {
            if let audioPlayer = RecordingManager.shared.audioPlayer, audioPlayer.isPlaying {
                displaylink?.isPaused = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordTableViewCell.reuseIdentifier, for: indexPath) as! RecordTableViewCell
        let rec = RecordingManager.shared.recordings[indexPath.row]
        cell.selectionStyle = .none
        cell.setupCellUI(recording: rec)
        cell.updateRecNameActionHandler = {
            self.updateRecordingTitle(indexPath)
        }
        cell.playStopActionHandler = {
            self.playStopRecording(cell: cell, rec: rec, indexPath: indexPath)
        }
        return cell
    }

    /// Used to add actions when a table view cell is swiped, in this case for deleting a recording
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cell = tableView.cellForRow(at: indexPath) as! RecordTableViewCell
        if let audioPlayer = RecordingManager.shared.audioPlayer, audioPlayer.isPlaying, cellWithPlayTappedButton != nil, cellWithPlayTappedButton == cell, indexPathWithPlayTappedButton != nil, indexPathWithPlayTappedButton == indexPath {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { _, _, completionHandler in
            self.deleteRecording(indexPath) { success in
                completionHandler(success)
            }
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = Icons.trash_fill

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: - Private functions

    /// Sets all necessary customizations for all UI elements present in this View Controller.
    /// The button for record audio is initially disabled.
    private func setupUI() {
        title = Utils.loc("YUOR_RECORDINGS")

        emptyStateImage.image = Icons.waveform_circle_fill
        emptyStateTitle.text = Utils.loc("NO_RECENT_RECORDING_TITLE")
        emptyStateMessage.text = Utils.loc("NO_RECENT_RECORDING_MESSAGE")

        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = RecordingManager.shared.recordings.isEmpty

        footerViewTitle.isHidden = true
        footerViewTitle.text = Utils.loc("RECORDING")

        footerViewTimer.isHidden = true
        footerViewTimer.text = "00:00"

        footerViewButton.delegate = self
        footerViewButton.alpha = 0.6
        footerViewButton.isUserInteractionEnabled = false
    }

    /// Asks to the user the permission for accessing to device microphone.
    /// If the permission is allowed by the user, the recording button is now enabled.
    func askMicrophonePermission() {
        RecordingManager.shared.askMicrophonePermission { [self] allowed in
            DispatchQueue.main.async { [self] in
                if !allowed {
                    showAlert(title: Utils.loc("WARNING"), message: Utils.loc("MICROPHONE_PERMS_DENIED"), buttons: [Utils.loc("OK"): .cancel]) { _ in }
                } else {
                    footerViewButton.alpha = 1.0
                    footerViewButton.isUserInteractionEnabled = true
                }
            }
        }
    }

    /// This function starts to play audio file associated to a 'RecordTableViewCell'.
    /// First of all it checks if the AVAudioPlayer (present inside RecordManager singleton) is nil:
    /// - if no: it calls the 'prepareAudioPlayer' inside 'RecordManager' and after that, if all is Ok, the CADisplayLink is resumed, disables the red record button and in the end starts to play audio. The cell reference where the Play Button was touched (and his IndexPath) are added to this view controller
    /// - if yes: the current playing audio is running and if this function is called from:
    ///     - same cell: CADisplayLink is paused, the cell UI elements are updated and the red record button is enabled
    ///     - another cell: the old cell (the cell added previously to the reference of this view controller) UI elements are updated, CADisplayLink is paused and this function is called recursively
    /// - Parameters:
    ///   - cell: cell where user tap on 'play' button
    ///   - rec: the Registration obj associated at the cell
    private func playStopRecording(cell: RecordTableViewCell, rec: Recording, indexPath: IndexPath) {
        if RecordingManager.shared.audioPlayer == nil {
            RecordingManager.shared.prepareAudioPlayer(recording: rec) { [self] audioPlayer in
                if let audioPlayer = audioPlayer {
                    displaylink?.isPaused = false

                    self.cellWithPlayTappedButton = cell
                    self.indexPathWithPlayTappedButton = IndexPath(row: indexPath.row, section: 0)

                    footerViewButton.alpha = 0.6
                    footerViewButton.isUserInteractionEnabled = false

                    RecordingManager.shared.playAudio()
                    audioPlayer.delegate = self
                    cell.playStopButton.setImage(Icons.stop_fill, for: .normal)
                    Utils.vibrate(style: .heavy)
                }
            }
        } else {
            RecordingManager.shared.stopAudio()

            if let cellWithPlayTappedButton = cellWithPlayTappedButton, tableView.indexPath(for: cellWithPlayTappedButton) == indexPathWithPlayTappedButton, cellWithPlayTappedButton != cell, indexPathWithPlayTappedButton != indexPath {
                cellWithPlayTappedButton.updateUIAfterStopPlaying(recording: cellWithPlayTappedButton.recording!)
                displaylink?.isPaused = true
                playStopRecording(cell: cell, rec: rec, indexPath: indexPath)
            } else {
                cell.updateUIAfterStopPlaying(recording: rec)
                updateAfterStopPlaying()
            }
        }
    }

    /// Updates the name of a recording obj
    /// - Parameter indexPath: indexPath of the cell containing the touched recording title
    private func updateRecordingTitle(_ indexPath: IndexPath) {
        let rec = RecordingManager.shared.recordings[indexPath.row]

        showPrompt(title: Utils.loc("WARNING"),
                   message: Utils.loc("ALERT_RENAME_RECORDING"),
                   textFieldPlaceholder: Utils.loc("ENTER_FILENAME"),
                   textFieldText: rec.title ?? "",
                   okButtonString: Utils.loc("OK"),
                   cancelButtonString: Utils.loc("CANCEL")) { newText in
            if !newText.isEmpty {
                RecordingManager.shared.renameRecording(newName: newText, index: indexPath.row)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }

    /// Deletes a recording obj
    /// - Parameter indexPath: indexPath of the cell swiped for deletinfg recordings
    private func deleteRecording(_ indexPath: IndexPath, completionHandler: @escaping (_ success: Bool) -> Void) {
        let rec = RecordingManager.shared.recordings[indexPath.row]
        RecordingManager.shared.deleteRecording(recording: rec) { [self] success in
            if success {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.isHidden = RecordingManager.shared.recordings.isEmpty
            }

            completionHandler(success)
        }
    }

    /// Live update of the registration time when the app is recording
    /// Live update of the current audio time when the app is playing audio
    @objc func updateMeters() {
        if let audioRecorder = RecordingManager.shared.audioRecorder, audioRecorder.isRecording {
            audioRecorder.updateMeters()
            footerViewTimer.text = audioRecorder.currentTime.stringFromTimeInterval()
        } else if let audioPlayer = RecordingManager.shared.audioPlayer, audioPlayer.isPlaying {
            if let cellWithPlayTappedButton = cellWithPlayTappedButton, tableView.indexPath(for: cellWithPlayTappedButton) == indexPathWithPlayTappedButton {
                audioPlayer.updateMeters()
                cellWithPlayTappedButton.recDuration.text = audioPlayer.currentTime.stringFromTimeInterval()
            }
        }
    }

    /// Updates the necessary UI elements after stopping to record a new audio file
    /// - Parameter success: true if the recording is successfully stopped, false otherwise
    private func updateUIAfterStopRecording(success: Bool) {
        if success {
            tableView.reloadData()
            tableView.isHidden = RecordingManager.shared.recordings.isEmpty
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }

        footerViewTitle.isHidden = true
        footerViewTimer.isHidden = true

        displaylink?.isPaused = true
    }

    /// Updates the necessary UI elements after stopping to play an audio, it pauses CADisplayLink updates and removes the cell references and its indexPath
    private func updateAfterStopPlaying() {
        displaylink?.isPaused = true
        cellWithPlayTappedButton = nil
        indexPathWithPlayTappedButton = nil

        footerViewButton.alpha = 1.0
        footerViewButton.isUserInteractionEnabled = true

        Utils.vibrate(style: .heavy)
    }
}

// MARK: - RecordButtonDelegate

extension HomeViewController: RecordButtonDelegate {
    /// This function starts to record a new audio file.
    /// First of all it checks if the 'isRecording' parameter is true or not:
    /// - if true: it checks if the AVAudioRecorder (present inside RecordManager singleton) is nil:
    ///     - If yes: the audioRecorder is nil, it calls the 'prepareAudioRecorder' inside 'RecordManager' and after that, if all is Ok, the CADisplayLink is resumed, showing the footer labels and in the end it starts to play audio.
    ///     - if no: the current recording session is stopped.
    /// - if false: the current recording session is stopped.
    /// - Parameter isRecording: true if the button is in recording 'state' (red square), false otherwise
    func tapButton(isRecording: Bool) {
        if isRecording {
            if RecordingManager.shared.audioRecorder == nil {
                RecordingManager.shared.prepareAudioRecorder { [self] audioRecorder in
                    if let audioRecorder = audioRecorder {
                        displaylink?.isPaused = false

                        RecordingManager.shared.startRecording()
                        audioRecorder.delegate = self

                        footerViewTitle.isHidden = false
                        footerViewTimer.isHidden = false
                    } else {
                        footerViewButton.endRecording()
                    }
                }
            } else if RecordingManager.shared.audioRecorder!.isRecording {
                RecordingManager.shared.stopRecording(success: true)
            }
        } else {
            RecordingManager.shared.stopRecording(success: true)
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension HomeViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            updateUIAfterStopRecording(success: false)
        } else {
            updateUIAfterStopRecording(success: true)
        }
    }

    func audioRecorderEncodeErrorDidOccur(_: AVAudioRecorder, error: Error?) {
        debugPrint("Error while recording audio \(error!.localizedDescription)")
        updateUIAfterStopRecording(success: false)
    }
}

// MARK: - AVAudioPlayerDelegate

extension HomeViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        if let cellWithPlayTappedButton = cellWithPlayTappedButton, tableView.indexPath(for: cellWithPlayTappedButton) == indexPathWithPlayTappedButton, let rec = cellWithPlayTappedButton.recording {
            RecordingManager.shared.stopAudio()

            cellWithPlayTappedButton.updateUIAfterStopPlaying(recording: rec)
            updateAfterStopPlaying()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_: AVAudioPlayer, error: Error?) {
        debugPrint("Error while playing audio \(error!.localizedDescription)")
        if let cellWithPlayTappedButton = cellWithPlayTappedButton, tableView.indexPath(for: cellWithPlayTappedButton) == indexPathWithPlayTappedButton, let rec = cellWithPlayTappedButton.recording {
            RecordingManager.shared.stopAudio()

            cellWithPlayTappedButton.updateUIAfterStopPlaying(recording: rec)
            updateAfterStopPlaying()
        }
    }
}
