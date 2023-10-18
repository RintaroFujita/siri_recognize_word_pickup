import UIKit
import Speech
import AVKit
import Foundation

class ViewController: UIViewController, AVAudioPlayerDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet weak var txtViewTranscipt: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var audioFileNameLabel: UILabel!

    var audioPlayer: AVAudioPlayer!
    var audioFiles: [URL] = []
    var currentAudioIndex = 0
    let delayDuration: TimeInterval = 1.0
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))

    override func viewDidLoad() {
        super.viewDidLoad()
        loadAudioFiles()
        // AVAudioSessionの設定
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Error setting AVAudioSession: \(error)")
        }
        speechRecognizer?.delegate = self
    }

    func loadAudioFiles() {
        if let audioDirectoryURL = Bundle.main.resourceURL?.appendingPathComponent("finrand2_5sec") {
            do {
                let audioFileURLs = try FileManager.default.contentsOfDirectory(at: audioDirectoryURL, includingPropertiesForKeys: nil, options: [])
                audioFiles = audioFileURLs.filter { $0.pathExtension == "wav" }
            } catch {
                print("Error loading audio files: \(error)")
            }
        }
    }

    func requestSpeechAuth() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
                if self.currentAudioIndex < self.audioFiles.count {
                    let audioFileURL = self.audioFiles[self.currentAudioIndex]
                    do {
                        let audio = try AVAudioPlayer(contentsOf: audioFileURL)
                        self.audioPlayer = audio
                        self.audioPlayer.play()
                        self.audioPlayer.delegate = self
                    } catch {
                        print("Error: \(error)")
                    }
                    let recognizer = SFSpeechRecognizer()
                    let request = SFSpeechURLRecognitionRequest(url: audioFileURL)

                    recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
                        if let err = error {
                            print("There was an error: \(err)")
                        } else {
                            if let recognizedText = result?.bestTranscription.formattedString {
                                // 認識された文字列を画面に表示
                                self.txtViewTranscipt.text = recognizedText
                                print("Recognized Text: \(recognizedText)")
                            }
                            // オーディオファイル名をprint
                            print("Now Playing: \(audioFileURL.lastPathComponent)")
                        }
                    })
                    self.updateAudioFileNameLabel(name: audioFileURL.lastPathComponent)
                } else {
                    print("All audio files have been played.")
                }
            }
        }
    }

    @IBAction func playBtnPressed(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.requestSpeechAuth()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.activityIndicator.stopAnimating()
        self.currentAudioIndex += 1
        if self.currentAudioIndex < self.audioFiles.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayDuration) {
                self.requestSpeechAuth()
            }
        } else {
            print("All audio files have been played.")
        }
    }

    func updateAudioFileNameLabel(name: String) {
        DispatchQueue.main.async {
            if let audioFileNameLabel = self.audioFileNameLabel {
                audioFileNameLabel.text = "Now Playing: \(name)"
            }
        }
    }
}

