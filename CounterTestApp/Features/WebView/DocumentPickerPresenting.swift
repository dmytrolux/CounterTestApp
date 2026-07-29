import UIKit
import UniformTypeIdentifiers

@MainActor
protocol DocumentPickerPresenting {
    func presentFileImporter(
        allowsMultipleSelection: Bool,
        completion: @escaping ([URL]?) -> Void
    )
    func presentFileExporter(for fileURL: URL)
}

@MainActor
final class SystemDocumentPickerPresenter: NSObject, DocumentPickerPresenting {
    private enum Mode {
        case importing(completion: ([URL]?) -> Void)
        case exporting(temporaryFileURL: URL)
    }

    private var mode: Mode?

    func presentFileImporter(
        allowsMultipleSelection: Bool,
        completion: @escaping ([URL]?) -> Void
    ) {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.item],
            asCopy: true
        )
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = self
        mode = .importing(completion: completion)
        present(picker, fallback: { completion(nil) })
    }

    func presentFileExporter(for fileURL: URL) {
        let picker = UIDocumentPickerViewController(
            forExporting: [fileURL],
            asCopy: true
        )
        picker.delegate = self
        mode = .exporting(temporaryFileURL: fileURL)
        present(picker) { [weak self] in
            self?.removeTemporaryFile(at: fileURL)
        }
    }

    private func present(_ picker: UIDocumentPickerViewController, fallback: () -> Void) {
        guard let presenter = topViewController() else {
            mode = nil
            fallback()
            return
        }

        presenter.present(picker, animated: true)
    }

    private func topViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController

        return topViewController(from: rootViewController)
    }

    private func topViewController(from viewController: UIViewController?) -> UIViewController? {
        if let presented = viewController?.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigationController = viewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }
        return viewController
    }

    private func finish(with urls: [URL]?) {
        switch mode {
        case let .importing(completion):
            completion(urls)
        case let .exporting(temporaryFileURL):
            removeTemporaryFile(at: temporaryFileURL)
        case nil:
            break
        }
        mode = nil
    }

    private func removeTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}

extension SystemDocumentPickerPresenter: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        finish(with: urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finish(with: nil)
    }
}
