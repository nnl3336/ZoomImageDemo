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
        scrollView.minimumZoomScale = 1
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
