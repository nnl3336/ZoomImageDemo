//
//  ContentView.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/12.
//

import SwiftUI
import CoreData
import UIKit

// MARK: - ViewController (UITextView)
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
        textView.backgroundColor = .systemGray6
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

            let maxWidth: CGFloat = 150
            let maxHeight: CGFloat = 200
            let ratio = image.size.height / image.size.width
            let height = min(maxWidth * ratio, maxHeight)
            attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: height)

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

        let characterIndex = layoutManager.characterIndex(for: loc,
                                                          in: textContainer,
                                                          fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textView.attributedText.length,
              let attachment = textView.attributedText.attribute(.attachment, at: characterIndex, effectiveRange: nil) as? NSTextAttachment,
              let tappedIndex = attachments.firstIndex(of: attachment),
              let image = attachment.image
        else { return }

        // ✅ ビヨンアニメーション
        let frameInTextView = layoutManager.boundingRect(forGlyphRange: NSRange(location: characterIndex, length: 1),
                                                         in: textContainer)
        var startFrame = frameInTextView
        startFrame.origin.x += textView.textContainerInset.left
        startFrame.origin.y += textView.textContainerInset.top
        startFrame = textView.convert(startFrame, to: view)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = startFrame
        imageView.clipsToBounds = true
        view.addSubview(imageView)

        let finalFrame = view.bounds

        UIView.animate(withDuration: 0.3, animations: {
            imageView.frame = finalFrame
        }, completion: { _ in
            imageView.removeFromSuperview()
            let zoomVC = ImageGalleryViewController(images: self.attachments.compactMap { $0.image },
                                                     initialIndex: tappedIndex)
            zoomVC.modalPresentationStyle = .overFullScreen
            self.present(zoomVC, animated: false)
        })
    }
}

// MARK: - Image Gallery
class ImageGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var images: [UIImage]
    var initialIndex: Int
    private var collectionView: UICollectionView!

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
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageZoomCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)

        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: IndexPath(item: initialIndex, section: 0),
                                    at: .centeredHorizontally, animated: false)

        addCloseButton()
    }

    private func addCloseButton() {
        let btn = UIButton(type: .system)
        btn.setTitle("×", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        btn.tintColor = .white
        btn.frame = CGRect(x: 20, y: 40, width: 50, height: 40)
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(btn)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageZoomCell
        cell.configure(with: images[indexPath.item])
        return cell
    }
}

// MARK: - Zoomable Cell
class ImageZoomCell: UICollectionViewCell, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.frame = contentView.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 3
        scrollView.delegate = self
        contentView.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with image: UIImage) {
        imageView.image = image
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
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
