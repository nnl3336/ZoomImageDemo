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
    let transitionDelegate = ZoomTransitionDelegate()

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

            let maxWidth: CGFloat = 150
            let ratio = image.size.height / image.size.width
            attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: maxWidth * ratio)

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

        let characterIndex = layoutManager.characterIndex(for: loc, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textView.attributedText.length,
              let attachment = textView.attributedText.attribute(.attachment, at: characterIndex, effectiveRange: nil) as? NSTextAttachment,
              let tappedIndex = attachments.firstIndex(of: attachment),
              let image = attachment.image
        else { return }

        // 🔹 タップされた画像の位置を特定して「ビヨン」開始
        let frameInTextView = layoutManager.boundingRect(forGlyphRange: NSRange(location: characterIndex, length: 1), in: textContainer)
        var startFrame = frameInTextView
        startFrame.origin.x += textView.textContainerInset.left
        startFrame.origin.y += textView.textContainerInset.top
        startFrame = textView.convert(startFrame, to: view)

        // 🔹 拡大先VCの準備
        let zoomVC = ImageGalleryViewController(images: attachments.compactMap { $0.image }, initialIndex: tappedIndex)
        zoomVC.modalPresentationStyle = .custom
        zoomVC.transitioningDelegate = transitionDelegate

        // 🔹 トランジション情報を設定
        transitionDelegate.animator.originFrame = startFrame
        let tempImageView = UIImageView(image: image)
        tempImageView.contentMode = .scaleAspectFit
        transitionDelegate.animator.imageView = tempImageView

        present(zoomVC, animated: true)
    }
}

// MARK: - Image Gallery with Swipe-to-Dismiss
class ImageGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var images: [UIImage]
    var initialIndex: Int
    private var collectionView: UICollectionView!

    // 下スワイプ用
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

        // 下スワイプジェスチャー
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
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

    // MARK: - UICollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageZoomCell
        cell.configure(with: images[indexPath.item])
        return cell
    }

    // MARK: - 下スワイプ処理
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            panStartCenter = view.center
        case .changed:
            if translation.y > 0 {
                view.center = CGPoint(x: panStartCenter.x, y: panStartCenter.y + translation.y)
                
                // 背景フェード
                let alpha = max(0.3, 1 - (translation.y / 500))
                view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            }
        case .ended, .cancelled:
            if translation.y > 150 {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.view.center = self.panStartCenter
                    self.view.backgroundColor = .black
                }
            }
        default: break
        }
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

class ZoomTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let animator = ZoomAnimator()

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        animator.isPresenting = true
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        animator.isPresenting = false
        return animator
    }
}

class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var isPresenting = true
    var originFrame = CGRect.zero
    var imageView: UIImageView?

    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let toVC = ctx.viewController(forKey: .to),
              let fromVC = ctx.viewController(forKey: .from),
              let imageView = imageView else { return }

        let container = ctx.containerView

        if isPresenting {
            let snapshot = UIImageView(image: imageView.image)
            snapshot.contentMode = .scaleAspectFit
            snapshot.frame = originFrame
            container.addSubview(snapshot)
            toVC.view.alpha = 0
            container.addSubview(toVC.view)

            UIView.animate(withDuration: 0.35,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 0.6) {
                snapshot.frame = container.bounds
                toVC.view.alpha = 1
            } completion: { _ in
                snapshot.removeFromSuperview()
                ctx.completeTransition(true)
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                fromVC.view.alpha = 0
            } completion: { _ in
                ctx.completeTransition(true)
            }
        }
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
