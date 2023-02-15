Adding a contact to the user's address book on Apple platforms using [the prescribed method](https://developer.apple.com/documentation/contacts/requesting_authorization_to_access_contacts) requires jumping through a lot of hoops. You have to:

- add `NSContactsUsageDescription` to your `info.plist`
- add an entitlement to your app
- ask the user for authorization (requires an in-app popup)
- if you want to modify the `note` field of the contact, you need to [get permission from Apple using an online form](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_contacts_notes) to be able to add a special `com.apple.developer.contacts.notes` entitlement to your app; Apple may take up to two weeks to respond just to reject you

**For one-off contact additions, there's a simpler way that requires none of that.** The idea is basic: you create a contact, save it in [vCard format](https://en.wikipedia.org/wiki/VCard), and then ask the operating system to open the vCard file in the Contacts app. When the Contacts app opens, it will ask the user if they really want to add the contact. This requires no entitlements (even if you're using the `note` field), no authorization, and even works in a sandboxed app.

## The Code

The code should be easily modifiable to work on iOS. Conveniently, the `Contacts` framework includes a method for serializing contacts into vCard format. You start by creating a `CNMutableContact` and filling it with your arbitrary data:

```swift
let contact = CNMutableContact()

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
```

Then you can serialize the contact using `CNContactVCardSerialization` and save it to a temporary file:

```swift
let data = try? CNContactVCardSerialization.data(with: [contact])
let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("contact.vcf")
try? data?.write(to: fileURL)
```

Finally, it's just a matter of using `NSWorkspace` to open it in the Contacts app:

```swift
if let contactsURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.AddressBook") {
    NSWorkspace.shared.open([fileURL], withApplicationAt: contactsURL, configuration: NSWorkspace.OpenConfiguration()) {
        (app, error) in
        if let error = error {
            print("Had a problem trying to open the Contacts app.")
            // your error handling here!
        }
    }
}
```

I hardcoded `com.apple.AddressBook` as the app to open the vCard here, which is Apple's Contacts app. You should probably not specify the exact address book app incase the user has a different default.

It works, but you might say, what about that `note` field? If you add a `note` property to your `CNMutableContact` you will notice it is silently dropped when the contact is added to the address book. This has nothing to do with the `note` special entitlement. It turns out `CNContactVCardSerialization` does not have support for either images or the note field. You can easily add both of these back. [A Stack Overflow post provides some code showing how to do so.](https://stackoverflow.com/a/70172455/281461)

## Security Loophole?

When working on a new version of my macOS app [Restaurants](https://apps.apple.com/us/app/restaurants/id941109837?mt=12), I came across the `note` field entitlement requirement. I submitted a request to Apple using their online form to have access to the entitlement and a week later I was rejected for my request being too vague. Fair enough, it's their sandbox, and they have the right to reject me for being too vague. But waiting so long to get an answer was frustrating and adding contacts requires a lot of ceremony. Frustrated, I went down the road of this alternative method for adding contacts.

It seems strange to me that you need authorization through Apple's prescribed method just to add contacts but there is this "side way" using a vCard file that doesn't require any authorization or entitlements. I'm not saying it's a security vulnerability. It's more of a loophole. If Apple really want developers to have to be authorized to do anything with Contacts, this shouldn't exist. 

I filed a security report with Apple thinking maybe they had looked over something so obvious. But I didn't get a bounty. Instead, they closed it, and marked it as "expected behavior." I basically expected as much. It seems like too obvious a thing to really be an oversight, but perhaps adding contacts should not require so many hoops to jump through using Apple's way. 

However, a key difference between the two ways of adding contacts, is that an authorized app has access to the contacts database, whereas this method using a temporary file simply opens the Contacts app, which is then in full control of the situation. It's a lot safer. Any risk is mitigated by the Contacts app. But from a user perspective they look quite similar. In the authorization case, the user gets a pop-up within your app. In the example above, the user gets a pop-up within the Contacts app. The downside, is it does take the user out of your app. But if this is a rarely used feature of your app, maybe it's worth it, to not have to deal with the frustration!