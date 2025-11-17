//
//  ContentView.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/12.
//

import SwiftUI
import CoreData
import UIKit

import CoreImage
import CoreImage.CIFilterBuiltins  // これを入れると型安全に使えます

import Photos

// MARK: - メインViewController
class ViewController: UIViewController, UITextViewDelegate {

    let textView = UITextView()
    var attachments: [NSTextAttachment] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        let attr = NSMutableAttributedString(string: "Tap images below:\n\n")
        for i in 1...3 {
            let image = UIImage(named: "sample\(i)") ?? UIImage(systemName: "photo")!
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = CGRect(x: 0, y: 0, width: 150, height: 150 * image.size.height / image.size.width)
            attachments.append(attachment)
            attr.append(NSAttributedString(attachment: attachment))
            attr.append(NSAttributedString(string: "\n\n"))
        }
        textView.attributedText = attr

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        textView.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: textView)
        var loc = location
        loc.x -= textView.textContainerInset.left
        loc.y -= textView.textContainerInset.top

        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer

        let index = layoutManager.characterIndex(for: loc, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textView.attributedText.length,
              let attachment = textView.attributedText.attribute(.attachment, at: index, effectiveRange: nil) as? NSTextAttachment,
              let tappedIndex = attachments.firstIndex(of: attachment),
              let _ = attachment.image else { return }

        guard let window = view.window else { return }

        // 親ビュー全体のフェードビュー
        let fadeView = UIView(frame: window.bounds)
        fadeView.backgroundColor = .black
        fadeView.alpha = 0
        window.addSubview(fadeView)

        let gallery = GalleryViewController(images: attachments.compactMap { $0.image }, initialIndex: tappedIndex)
        gallery.modalPresentationStyle = .overFullScreen

        // 下スワイプで親ビューのフェードを動かすクロージャ
        gallery.onPanChanged = { translationY in
            // translationY が 0 〜 任意の値で alpha を反転
            let progress = min(1, abs(translationY) / 400)
            fadeView.alpha = 0.5 * (1 - progress) // ← ここで逆転
        }

        gallery.onDismiss = {
            UIView.animate(withDuration: 0.25, animations: {
                fadeView.alpha = 0
            }, completion: { _ in
                fadeView.removeFromSuperview()
            })
        }

        present(gallery, animated: false)
    }

}
extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: textView)
        let index = textView.layoutManager.characterIndex(
            for: location,
            in: textView.textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        // NSTextAttachment の上だけ反応させる
        if let _ = textView.attributedText.attribute(.attachment, at: index, effectiveRange: nil) as? NSTextAttachment {
            return true
        }
        return false
    }
}

//

// MARK: - SwiftUI Wrapper
struct ListVCWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = ViewController()
        return UINavigationController(rootViewController: vc)
    }
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        ListVCWrapper()
            .edgesIgnoringSafeArea(.all)
    }
}
