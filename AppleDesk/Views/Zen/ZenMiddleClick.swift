import SwiftUI
import UIKit

/// Rileva il click centrale del mouse (rotellina) senza intercettare il click sinistro.
struct MiddleClickOverlay: UIViewRepresentable {
    let onMiddleClick: () -> Void

    func makeUIView(context: Context) -> MiddleClickView {
        let view = MiddleClickView()
        view.onMiddleClick = onMiddleClick
        return view
    }

    func updateUIView(_ uiView: MiddleClickView, context: Context) {
        uiView.onMiddleClick = onMiddleClick
    }
}

final class MiddleClickView: UIView {
    /// Pulsante centrale mouse: 1 = primario, 2 = secondario, 3 = centrale (rotellina).
    private static let middleButtonMask = UIEvent.ButtonMask.button(3)

    var onMiddleClick: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleMiddleClick(_:)))
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.buttonMaskRequired = Self.middleButtonMask
        addGestureRecognizer(recognizer)
    }

    required init?(coder: NSCoder) { nil }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        if let event, event.buttonMask == Self.middleButtonMask {
            return self
        }
        return nil
    }

    @objc private func handleMiddleClick(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        onMiddleClick?()
    }
}
