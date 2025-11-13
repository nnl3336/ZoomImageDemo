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
              let image = attachment.image else { return }

        guard let window = view.window else { return }

        // 親ビュー全体を暗くするビュー
        let fadeView = UIView(frame: window.bounds)
        fadeView.backgroundColor = .black
        fadeView.alpha = 0
        window.addSubview(fadeView)

        // フェードイン
        UIView.animate(withDuration: 0.25) {
            fadeView.alpha = 0.5  // 好きな暗さに調整
        }

        let gallery = GalleryViewController(images: attachments.compactMap { $0.image }, initialIndex: tappedIndex)
        gallery.modalPresentationStyle = .overFullScreen

        // Gallery が閉じられたときにフェードを戻す
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

// MARK: - ギャラリー
// MARK: - GalleryViewController
class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var images: [UIImage]
    var initialIndex: Int
    private var collectionView: UICollectionView!

    // 下スワイプ用
    private let dimmingView = UIView()
    private var panStartCenter: CGPoint = .zero
    private var isDraggingToDismiss = false
    
    var onDismiss: (() -> Void)?  // ←追加

    init(images: [UIImage], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // dimmingView は初期 alpha = 1（真っ黒）
        dimmingView.frame = view.bounds
        dimmingView.backgroundColor = .black
        dimmingView.alpha = 1
        view.addSubview(dimmingView)

        // UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageZoomCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)

        addCloseButton()

        // 下スワイプ用
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panStartCenter = view.center
            isDraggingToDismiss = true
            collectionView.isScrollEnabled = false // 横スクロール無効化
        case .changed:
            view.center = CGPoint(x: panStartCenter.x + translation.x,
                                  y: panStartCenter.y + translation.y)
            // 縦移動量に応じて背景フェード
            let alpha = max(0.2, 1 - abs(translation.y) / 400)
            dimmingView.alpha = alpha
        case .ended, .cancelled:
            collectionView.isScrollEnabled = true
            isDraggingToDismiss = false
            if translation.y > 150 || velocity.y > 500 {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.center.y += self.view.frame.height
                    self.dimmingView.alpha = 0
                }, completion: { _ in
                    self.dismiss(animated: false)
                })
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.view.center = self.panStartCenter
                    self.dimmingView.alpha = 1
                }
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

    // MARK: UICollectionViewDataSource
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
    
    private let editButton = UIButton(type: .system)

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
        
        editButton.setTitle("Edit & Save", for: .normal)
            editButton.tintColor = .white
            editButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            editButton.layer.cornerRadius = 8
            editButton.frame = CGRect(x: contentView.bounds.width - 120, y: contentView.bounds.height - 60, width: 100, height: 40)
            editButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
            editButton.addTarget(self, action: #selector(editAndSave), for: .touchUpInside)
            contentView.addSubview(editButton)
    }

    required init?(coder: NSCoder) { fatalError() }
    
    //
    
    @objc private func editAndSave() {
        guard let image = imageView.image else { return }
        let edited = applySomeFilter(to: image)
        saveToPhotoLibrary(edited)
    }
    func applySomeFilter(to image: UIImage) -> UIImage {
        let context = CIContext()
        let ciImage = CIImage(image: image)!
        
        // 型安全版フィルター
        let filter = CIFilter.sepiaTone()
        filter.inputImage = ciImage
        filter.intensity = 0.8
        
        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }

    func saveToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }


    
    //

    func configure(with image: UIImage) {
        imageView.image = image
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
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
