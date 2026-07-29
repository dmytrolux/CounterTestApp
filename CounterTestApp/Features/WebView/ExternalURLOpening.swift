import UIKit

@MainActor
protocol ExternalURLOpening {
    func open(_ url: URL)
}

struct SystemExternalURLOpener: ExternalURLOpening {
    func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:])
    }
}
