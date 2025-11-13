//
//  ContentView.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/12.
//

import SwiftUI
import CoreData
import UIKit

import UIKit

// MARK: - メインViewController
class ViewController: UIViewController, UITextViewDelegate {

    let textView = UITextView()
    var attachments: [NSTextAttachment] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        textView.isEditable = false
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
              let image = attachment.image else { return }

        // 🔹 Apple ライクに拡大
        let gallery = GalleryViewController(images: attachments.compactMap { $0.image }, initialIndex: tappedIndex)
        gallery.modalPresentationStyle = .overFullScreen
        present(gallery, animated: false)
    }
}

// MARK: - ギャラリー
class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {

    var images: [UIImage]
    var initialIndex: Int
    private var collectionView: UICollectionView!
    private var panStartCenter: CGPoint = .zero

    init(images: [UIImage], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = view.bounds.size
        layout.minimumLineSpacing = 0

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.scrollToItem(at: IndexPath(item: initialIndex, section: 0), at: .centeredHorizontally, animated: false)

        // 下スワイプジェスチャー
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    // UICollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { images.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GalleryCell
        cell.setImage(images[indexPath.item])
        return cell
    }

    // 横スワイプと下スワイプの共存
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panStartCenter = view.center
        case .changed:
            if translation.y > 0 {
                view.center = CGPoint(x: panStartCenter.x + translation.x, y: panStartCenter.y + translation.y)
                view.backgroundColor = UIColor.black.withAlphaComponent(max(0.2, 1 - translation.y/400))
            }
        case .ended, .cancelled:
            if translation.y > 150 || velocity.y > 500 {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.center.y += self.view.frame.height
                    self.view.alpha = 0
                }, completion: { _ in
                    self.dismiss(animated: false)
                })
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.view.center = self.panStartCenter
                    self.view.backgroundColor = .black
                }
            }
        default: break
        }
    }
}

// MARK: - セル
class GalleryCell: UICollectionViewCell, UIScrollViewDelegate {
    private let scroll = UIScrollView()
    private let imgView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        scroll.frame = contentView.bounds
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 3
        scroll.delegate = self
        contentView.addSubview(scroll)

        imgView.contentMode = .scaleAspectFit
        imgView.frame = scroll.bounds
        imgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scroll.addSubview(imgView)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setImage(_ img: UIImage) { imgView.image = img }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imgView }
}




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
