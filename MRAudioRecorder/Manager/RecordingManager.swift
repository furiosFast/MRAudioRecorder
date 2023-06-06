//
//  RecordingManager.swift
//  MRAudioRecorder
//
//  Created by Marco Ricca on 14/03/23.
//

import AVFoundation
import UIKit

/// RecordingManager is a singleton class that contains the Recording list and some utils functions for recording and playing the audio file
class RecordingManager: NSObject {
    static let shared = RecordingManager()

    public var recordings: [Recording] = []
    public var audioRecorder: AVAudioRecorder?
    public var audioPlayer: AVAudioPlayer?

    private var recordingSession: AVAudioSession?
    private var totNumOfRecordingMaked = 0

    // MARK: - Public functions

    /// Initilizes the recoding session (AVAudioSession) and asks to the user the permission for using the device microphone
    /// - Parameter completion: it returns true if the user allows permissions for using the device microphone, false otherwise
    public func askMicrophonePermission(completion: @escaping (_ allowed: Bool) -> Void) {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession?.setCategory(.playAndRecord)
            try recordingSession?.setActive(true)
            try recordingSession?.overrideOutputAudioPort(.speaker)
            recordingSession?.requestRecordPermission { allowed in
                completion(allowed)
            }
        } catch {
            completion(false)
        }
    }

    /// Removes the recording from recordings list and from the disk
    /// - Parameters:
    ///   - recording: recording to be removed
    ///   - completion: return true if the item was removed successfully, false otherwise
    public func deleteRecording(recording: Recording, completion: @escaping (_ success: Bool) -> Void) {
        if let fileUrl = recording.fileUrl {
            let fileManager = FileManager.default

            do {
                try fileManager.removeItem(at: fileUrl)
                recordings.removeAll(where: { $0.fileUrl == recording.fileUrl })
                completion(true)
            } catch {
                debugPrint(error.localizedDescription)
                completion(false)
            }
        }
    }

    /// Updates the name of a recording
    /// - Parameters:
    ///   - newName: the new name of the recording
    ///   - index: index of the recording obj inside recording list
    public func renameRecording(newName: String, index: Int) {
        recordings[index].title = newName
    }

    // MARK: - Recording

    /// This function MUST be called before starting to record an audio.
    /// First of all instantiates the public AVAudioRecorder obj with default settings for generating an MPEG4 audio file ('.mp4' extension). If the registration is successful, the recorded audio file is stored in a temporary directory.
    /// - Parameter completion: returns the instantiate AVAudioPlayer, ready for playing audio
    public func prepareAudioRecorder(completion: @escaping (_ audioRecorder: AVAudioRecorder?) -> Void) {
        let fileName = "recording_\(totNumOfRecordingMaked).m4a"
        let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        totNumOfRecordingMaked += 1

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileUrl, settings: settings)
            completion(audioRecorder)
            return
        } catch {
            debugPrint("AVAudioRecorder error: \(error.localizedDescription)")
        }

        completion(nil)
    }

    /// Starts to record an audio
    public func startRecording() {
        audioRecorder?.record()
    }

    /// Stops recording audio and adds a new Recording obj to recording list.
    /// At the end the public AVAudioRecorder is set to nil.
    /// - Parameter success: if the recording is terminated with success, if true a new Recording obj is added to recording list
    public func stopRecording(success: Bool) {
        guard let audioRecorder = audioRecorder else { return }
        let duration = audioRecorder.currentTime

        if success {
            recordings.append(Recording(title: audioRecorder.url.lastPathComponent, captureDate: Date(), duration: duration, fileUrl: audioRecorder.url))
            recordings.sort(by: { $0.captureDate! > $1.captureDate! })
        }

        audioRecorder.stop()
        self.audioRecorder = nil
    }

    // MARK: - Playing

    /// This function MUST be called before playing audio files.
    /// First of all instantiates the public AVAudioPlayer obj with the audio file url (passed via parameter inside a Recording obj).
    /// - Parameters:
    ///   - recording: the recording to be played
    ///   - completion: returns the instantiate AVAudioPlayer, ready for playing the audio
    public func prepareAudioPlayer(recording: Recording, completion: @escaping (_ audioPlayer: AVAudioPlayer?) -> Void) {
        if let fileUrl = recording.fileUrl {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: fileUrl)
                audioPlayer?.isMeteringEnabled = true
                audioPlayer?.prepareToPlay()

                completion(audioPlayer)
                return
            } catch {
                debugPrint("AVAudioPlayer error: \(error.localizedDescription)")
            }
        }

        completion(nil)
    }

    /// Starts to play audio
    public func playAudio() {
        audioPlayer?.stop()
        audioPlayer?.play()
    }

    /// Stops playing the audio and sets the public AVAudioPlayer to nil
    public func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
