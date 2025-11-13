//
//  ContentView.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/12.
//

import SwiftUI
import CoreData
import UIKit

// MARK: - メインVC
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
            attachment.bounds = CGRect(x: 0, y: 0, width: 150, height: 150 * (image.size.height / image.size.width))
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
        let idx = layoutManager.characterIndex(for: loc, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard idx < textView.attributedText.length,
              let attachment = textView.attributedText.attribute(.attachment, at: idx, effectiveRange: nil) as? NSTextAttachment,
              let image = attachment.image,
              let tappedIndex = attachments.firstIndex(of: attachment)
        else { return }

        // 元画像のフレーム
        let frameInTextView = layoutManager.boundingRect(forGlyphRange: NSRange(location: idx, length: 1), in: textContainer)
        var startFrame = frameInTextView
        startFrame.origin.x += textView.textContainerInset.left
        startFrame.origin.y += textView.textContainerInset.top
        let convertedFrame = textView.convert(startFrame, to: view)

        // **attachments はそのままにしておく**
        let zoomVC = FreeFloatImageViewController(images: attachments.map { $0.image! },
                                                  initialIndex: tappedIndex,
                                                  startFrame: convertedFrame)
        zoomVC.modalPresentationStyle = .overFullScreen
        present(zoomVC, animated: false)
    }
}

// MARK: - 拡大画像VC
class FreeFloatImageViewController: UIViewController {

    var images: [UIImage]
    var currentIndex: Int
    private var imageView = UIImageView()
    private var startFrame: CGRect
    private var panStartCenter: CGPoint = .zero

    init(images: [UIImage], initialIndex: Int, startFrame: CGRect) {
        self.images = images
        self.currentIndex = initialIndex
        self.startFrame = startFrame
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // UIImageView 設定
        imageView.image = images[currentIndex]
        imageView.contentMode = .scaleAspectFit
        imageView.frame = startFrame
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)

        // スナップショット拡大
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6) {
            self.imageView.frame = self.view.bounds
        }

        // 下スワイプ＋自由移動
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        imageView.addGestureRecognizer(pan)

        // 左右スワイプ（ページ切替）
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextImage))
        swipeLeft.direction = .left
        imageView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(prevImage))
        swipeRight.direction = .right
        imageView.addGestureRecognizer(swipeRight)

        // 閉じるボタン
        let btn = UIButton(type: .system)
        btn.setTitle("×", for: .normal)
        btn.tintColor = .white
        btn.titleLabel?.font = .systemFont(ofSize: 30)
        btn.frame = CGRect(x: 20, y: 40, width: 50, height: 40)
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(btn)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panStartCenter = imageView.center
        case .changed:
            imageView.center = CGPoint(x: panStartCenter.x + translation.x,
                                       y: panStartCenter.y + translation.y)
            view.backgroundColor = UIColor.black.withAlphaComponent(max(0.3, 1 - abs(translation.y)/400))
        case .ended, .cancelled:
            if translation.y > 150 || velocity.y > 500 {
                UIView.animate(withDuration: 0.2, animations: {
                    self.imageView.alpha = 0
                    self.imageView.center.y += 1000
                }, completion: { _ in
                    self.dismiss(animated: false)
                })
            } else {
                UIView.animate(withDuration: 0.25,
                               delay: 0,
                               usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 0.6,
                               options: [], animations: {
                    self.imageView.center = self.panStartCenter
                    self.view.backgroundColor = .black
                })
            }
        default: break
        }
    }

    @objc private func nextImage() {
        guard currentIndex < images.count - 1 else { return }
        currentIndex += 1
        imageView.image = images[currentIndex]
    }

    @objc private func prevImage() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        imageView.image = images[currentIndex]
    }

    @objc private func close() {
        UIView.animate(withDuration: 0.2, animations: {
            self.imageView.alpha = 0
            self.imageView.center.y += 500
        }, completion: { _ in
            self.dismiss(animated: false)
        })
    }
}

// MARK: - Image Gallery with Swipe-to-Dismiss
class ImageGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var images: [UIImage]
    var initialIndex: Int
    private var collectionView: UICollectionView!

    // フリーフロート用
    private var panStartCenter: CGPoint = .zero
    private var currentVelocity: CGPoint = .zero

    init(images: [UIImage], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
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

        collectionView.scrollToItem(at: IndexPath(item: initialIndex, section: 0),
                                    at: .centeredHorizontally, animated: false)

        addCloseButton()

        // 下スワイプ＋フリーフロート
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panStartCenter = view.center
        case .changed:
            // 上下左右自由に動かす
            view.center = CGPoint(x: panStartCenter.x + translation.x,
                                  y: panStartCenter.y + translation.y)
            
            // 背景フェード（縦移動だけ連動）
            let alpha = max(0.3, 1 - abs(translation.y) / 400)
            view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
        case .ended, .cancelled:
            // 閾値または下向き速度で閉じる
            if translation.y > 150 || velocity.y > 500 {
                let finalY = view.frame.origin.y + view.frame.height + 200
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.center.y = finalY
                    self.view.alpha = 0
                }, completion: { _ in
                    self.dismiss(animated: false)
                })
            } else {
                // 元に戻す
                UIView.animate(withDuration: 0.25, delay: 0,
                               usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 0.6,
                               options: [.curveEaseOut], animations: {
                    self.view.center = self.panStartCenter
                    self.view.backgroundColor = .black
                })
            }
        default: break
        }
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

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
    -> UIPresentationController? {
        return ZoomPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var isPresenting = true
    var originFrame: CGRect = .zero
    var imageView: UIImageView?

    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let fromVC = ctx.viewController(forKey: .from),
              let toVC = ctx.viewController(forKey: .to),
              let imageView = imageView else { return }
        
        let container = ctx.containerView
        let snapshot = UIImageView(image: imageView.image)
        snapshot.contentMode = .scaleAspectFit
        snapshot.frame = isPresenting ? originFrame : toVC.view.frame
        container.addSubview(snapshot)
        
        if isPresenting {
            toVC.view.alpha = 0
            container.addSubview(toVC.view)
        }

        UIView.animate(withDuration: transitionDuration(using: ctx),
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.6) {
            snapshot.frame = self.isPresenting ? container.bounds : self.originFrame
            if self.isPresenting {
                toVC.view.alpha = 1
            } else {
                fromVC.view.alpha = 0
            }
        } completion: { _ in
            snapshot.removeFromSuperview()
            ctx.completeTransition(true)
        }
    }
}

// MARK: - Presentation Controller
class ZoomPresentationController: UIPresentationController {
    private var dimmingView: UIView!
    private var panGesture: UIPanGestureRecognizer!
    private var initialFrame: CGRect = .zero

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setup()
    }

    private func setup() {
        dimmingView = UIView()
        dimmingView.backgroundColor = .black
        dimmingView.alpha = 0

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        presentedViewController.view.addGestureRecognizer(panGesture)
    }

    override func presentationTransitionWillBegin() {
        guard let container = containerView else { return }
        dimmingView.frame = container.bounds
        container.insertSubview(dimmingView, at: 0)

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        })
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        })
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = presentedView else { return }
        let translation = gesture.translation(in: containerView)

        switch gesture.state {
        case .began:
            initialFrame = view.frame
        case .changed:
            if translation.y > 0 {
                view.frame.origin.y = translation.y
                dimmingView.alpha = max(0, 1 - translation.y / 400)
            }
        case .ended, .cancelled:
            if translation.y > 200 {
                presentedViewController.dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.25) {
                    view.frame = self.initialFrame
                    self.dimmingView.alpha = 1
                }
            }
        default:
            break
        }
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = containerView?.bounds ?? .zero
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
