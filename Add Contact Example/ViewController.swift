//
//  ViewController.swift
//  Add Contact Example
//
//  MIT License
//
//  Copyright (c) 2023 David Kopec
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Cocoa
import Contacts

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func addContact(sender: AnyObject) {
        // Creating a mutable contact object
        let contact = CNMutableContact()

        if let image = NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: "Open Lock") {
            contact.imageData = image.tiffRepresentation
        }

        contact.contactType = .organization
        contact.organizationName = "Silly Restaurant"

        contact.phoneNumbers = [CNLabeledValue(
                label:CNLabelPhoneNumberMain,
                value:CNPhoneNumber(stringValue:"5555555555"))]

        let address = CNMutablePostalAddress()
        address.street = "31 Silly Way"
        address.city = "Silly Town"
        address.state = "Vermont"
        address.postalCode = "05401"
        address.country = "USA"
        contact.postalAddresses = [CNLabeledValue(label:CNLabelWork, value:address)]
        contact.urlAddresses = [CNLabeledValue(label: "Apple", value: "https://www.apple.com/")]
        contact.note = "This is a note."
        
        // Create a data object from the contact
        // The default CNContactVCardSerialization data method does not support image and note support
        // Here is how to add this: https://stackoverflow.com/a/70172455/281461
        let data = try? CNContactVCardSerialization.data(with: [contact])
        
        // Create a temporary file URL in a valid directory for a sandboxed macOS app
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("contact.vcf")
        
        // Write the VCard data to the file
        try? data?.write(to: fileURL)
        
        // Get the URL for the Contacts app
        if let contactsURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.AddressBook") {
            
            // Open the file in the Contacts app
            NSWorkspace.shared.open([fileURL], withApplicationAt: contactsURL, configuration: NSWorkspace.OpenConfiguration()) {
                    (app, error) in
                    if let error = error {
                        let nsa: NSAlert = NSAlert()
                        nsa.messageText = error.localizedDescription
                        nsa.informativeText = "Had a problem trying to open the Contacts app."
                        nsa.beginSheetModal(for: self.view.window!, completionHandler: { (_) -> Void in
                            return
                        })
                    }
                }
        } else {
            let nsa: NSAlert = NSAlert()
            nsa.messageText = "Is the Contacts app installed?"
            nsa.informativeText = "Could not find the Contacts app with bundle identifier com.apple.AddressBook installed on this system."
            nsa.beginSheetModal(for: view.window!, completionHandler: { (_) -> Void in
                return
            })
        }
    }

}

