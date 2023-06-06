//
//  MRAudioRecorderTests.swift
//  MRAudioRecorderTests
//
//  Created by Marco Ricca on 21/03/23.
//

@testable import MRAudioRecorder
import XCTest

final class MRAudioRecorderTests: XCTestCase {
    func testRecordingAudioWithStopSuccess() {
        let recordingManager = RecordingManager.shared

        recordingManager.prepareAudioRecorder { audioRecorder in
            XCTAssertEqual(recordingManager.recordings.isEmpty, true, "recording list must be empty before start recording")
            if audioRecorder == nil {
                XCTAssertNotEqual(audioRecorder, nil, "audioRecorder should be not nil before start recording")
            } else {
                recordingManager.startRecording()

                let delayExpectation = XCTestExpectation()
                delayExpectation.isInverted = true
                self.wait(for: [delayExpectation], timeout: 5)

                recordingManager.stopRecording(success: true)
                XCTAssertEqual(recordingManager.recordings.isEmpty, false, "recording list must not be empty")
                XCTAssertEqual(recordingManager.audioRecorder, nil, "audioRecorder should be nil after stop recording")
            }
        }
    }

    func testRecordingAudioWithStopError() {
        let recordingManager = RecordingManager.shared

        recordingManager.prepareAudioRecorder { audioRecorder in
            XCTAssertEqual(recordingManager.recordings.isEmpty, true, "recording list must be empty before start recording")
            if audioRecorder == nil {
                XCTAssertNotEqual(audioRecorder, nil, "audioRecorder should be not nil before start recording")
            } else {
                recordingManager.startRecording()

                let delayExpectation = XCTestExpectation()
                delayExpectation.isInverted = true
                self.wait(for: [delayExpectation], timeout: 5)

                recordingManager.stopRecording(success: false)
                XCTAssertEqual(recordingManager.recordings.isEmpty, true, "recording list must be empty")
                XCTAssertEqual(recordingManager.audioRecorder, nil, "audioRecorder should be nil after stop recording")
            }
        }
    }
}
