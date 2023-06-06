//
//  Extension.swift
//  MRAudioRecorder
//
//  Created by Marco Ricca on 13/03/23.
//

import UIKit

extension SignedNumeric {
    /// Casts any numeric values to String
    var string: String {
        return String(describing: self)
    }
}

extension UIViewController {
    /// Shows an Alert View
    /// - Parameters:
    ///   - title: Alert View title
    ///   - message: Alert View text
    ///   - buttons: Alert View button text and style
    ///   - callback: callback when an Aler View button is tapped
    func showAlert(title: String, message: String, buttons: [String: UIAlertAction.Style], callback: @escaping (_ buttonClicked: String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for button in buttons {
            alert.addAction(UIAlertAction(title: button.key, style: button.value, handler: { action in
                callback(action.title!)
            }))
        }

        present(alert, animated: true, completion: nil)
    }

    /// Shows an Alert View with a TextField inside
    /// - Parameters:
    ///   - title: Alert View title
    ///   - message: Alert View text
    ///   - textFieldPlaceholder: TextField placeholder
    ///   - textFieldText: TextField text
    ///   - okButtonString: Alert View 'OK' text
    ///   - cancelButtonString: Alert View 'Cancel' text
    ///   - completion: callback when 'OK' Alert View button is tapped. This callback returns the text inside the TextField
    func showPrompt(title: String, message: String, textFieldPlaceholder: String, textFieldText: String, okButtonString: String, cancelButtonString: String, completion: @escaping (_ newText: String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addTextField(configurationHandler: { textfield in
            textfield.placeholder = textFieldPlaceholder
            textfield.text = textFieldText
        })

        let okButton = UIAlertAction(title: okButtonString, style: UIAlertAction.Style.default, handler: { _ in
            let result = alert.textFields![0] as UITextField
            completion(result.text ?? "")
        })

        alert.addAction(okButton)

        let cancelButton = UIAlertAction(title: cancelButtonString, style: UIAlertAction.Style.cancel, handler: nil)
        alert.addAction(cancelButton)
        present(alert, animated: true, completion: nil)
    }
}

extension TimeInterval {
    /// Converts TimeInterval obj to String in 'mm:ss' format
    /// - Returns: minutes and seconds in String format
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)

        let seconds = time % 60
        let minutes = (time / 60) % 60

        return String(format: "%0.2d:%0.2d", minutes, seconds)
    }
}
