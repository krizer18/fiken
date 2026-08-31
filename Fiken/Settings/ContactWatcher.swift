import UIKit

/// Reports whether a finger is on the glass, anywhere in the app.
///
/// "Go dark" needs to know about contact across every screen, and each screen
/// handles its own touches. A gesture recogniser on the window sees all of them
/// without taking any — it never leaves `.possible`, so nothing downstream
/// changes behaviour because it is there.
final class ContactWatcher {
    static let shared = ContactWatcher()

    var onChange: ((Bool) -> Void)?

    private var recognizer: PassiveRecognizer?

    func attach() {
        guard recognizer == nil else { return }
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let recognizer = PassiveRecognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.onChange = { [weak self] touching in self?.onChange?(touching) }
        window.addGestureRecognizer(recognizer)
        self.recognizer = recognizer
    }
}

final class PassiveRecognizer: UIGestureRecognizer {
    var onChange: ((Bool) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) { report(event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) { report(event) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { report(event) }

    private func report(_ event: UIEvent) {
        let live = (event.allTouches ?? []).filter { $0.phase != .ended && $0.phase != .cancelled }
        onChange?(!live.isEmpty)
    }
}
