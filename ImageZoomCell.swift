//
//  ImageZoomCell.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/17.
//

import SwiftUI
import Photos

// MARK: - Zoomable Cell
class ImageZoomCell: UICollectionViewCell, UIScrollViewDelegate {
    
    //画像小さく
    
    func animateToEditingSize() {
        let scrollView = self.scrollView
        scrollView.isScrollEnabled = false

        let targetScale: CGFloat = 0.8

        UIView.animate(withDuration: 0.25) {
            // 中央に向かって transform で縮小
            self.imageView.center = CGPoint(
                x: scrollView.bounds.midX,
                y: scrollView.bounds.midY
            )
            self.imageView.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
        } completion: { _ in
            // ★ここでは zoomScale を変えない
            // ★transform も元に戻さない
            self.centerImageView()
            scrollView.isScrollEnabled = true
        }
    }


    func centerImageView() {
        let scrollView = self.scrollView
        let boundsSize = scrollView.bounds.size
        var frameToCenter = self.imageView.frame

        // 縦方向
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }

        // 横方向
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }

        self.imageView.frame = frameToCenter
    }
    
    // 編集モード = 画像を少し小さくする
    func setEditingMode(_ isEditing: Bool) {
        let targetScale: CGFloat = isEditing ? 0.8 : 1.0

        // アニメーション内で bounds / center に変換
        UIView.animate(withDuration: 0.25) {
            let newWidth = self.scrollView.bounds.width * targetScale
            let newHeight = self.scrollView.bounds.height * targetScale
            self.imageView.bounds.size = CGSize(width: newWidth, height: newHeight)
            self.imageView.center = CGPoint(
                x: self.scrollView.bounds.midX,
                y: self.scrollView.bounds.midY
            )
        } completion: { _ in
            // transform はリセット
            self.imageView.transform = .identity
            self.centerImageView()
        }
    }
    
    
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
    
    //基本プロパティ
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    private let editButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.frame = contentView.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3
        scrollView.delegate = self
        contentView.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        
        /*editButton.setTitle("Edit & Save", for: .normal)
            editButton.tintColor = .white
            editButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            editButton.layer.cornerRadius = 8
            editButton.frame = CGRect(x: contentView.bounds.width - 120, y: contentView.bounds.height - 60, width: 100, height: 40)
            editButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
            editButton.addTarget(self, action: #selector(editAndSave), for: .touchUpInside)
            contentView.addSubview(editButton)*/
    }

    required init?(coder: NSCoder) { fatalError() }
    
    
}

/*
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
*/
