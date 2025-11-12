//
//  ContentView.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/12.
//

import SwiftUI
import CoreData
import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    let textView = UITextView()
    var attachments: [NSTextAttachment] = [] // 画像のリスト

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        textView.frame = view.bounds.insetBy(dx: 20, dy: 60)
        textView.isEditable = false
        view.addSubview(textView)

        let attr = NSMutableAttributedString(string: "Tap images below:\n\n")

        // サンプル画像を3枚追加
        for i in 1...3 {
            if let image = UIImage(named: "sample\(i)") {
                let att = NSTextAttachment()
                att.image = image
                let ratio = image.size.height / image.size.width
                att.bounds = CGRect(x: 0, y: 0, width: 150, height: 150 * ratio)
                attachments.append(att)
                attr.append(NSAttributedString(attachment: att))
                attr.append(NSAttributedString(string: "\n\n"))
            }
        }
        textView.attributedText = attr

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        textView.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: textView)
        
        guard let position = textView.closestPosition(to: location) else { return }

        guard let range = textView.tokenizer.rangeEnclosingPosition(
            position,
            with: .character,
            inDirection: UITextDirection(rawValue: UITextLayoutDirection.right.rawValue)
        ) else { return }

        let index = textView.offset(from: textView.beginningOfDocument, to: range.start)
        
        guard let attachment = textView.attributedText?.attribute(.attachment, at: index, effectiveRange: nil) as? NSTextAttachment else { return }
        
        guard let tappedIndex = attachments.firstIndex(of: attachment) else { return }

        let images = attachments.compactMap { $0.image }
        let zoomVC = ImageGalleryViewController(images: images, initialIndex: tappedIndex)
        zoomVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        present(zoomVC, animated: false)
    }


}

//

// SwiftUI Preview / 使用例
struct ContentView: View {
    var body: some View {
        //NavigationView {
            ListVCWrapper()
                //.navigationTitle("Detail")
        //}
    }
}

// ListViewController 用ラッパー
struct ListVCWrapper: UIViewControllerRepresentable {

    @Environment(\.managedObjectContext) var context

    func makeUIViewController(context: Context) -> UINavigationController {
        let folderVC = ViewController()
        //folderVC.context = self.context
        let nav = UINavigationController(rootViewController: folderVC)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 必要があれば更新
    }
}
