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
    
    enum GalleryUIState {
        case normal        // ナビゲーションバー & ツールバー 表示
        case hidden        // 全て隠す（タップで復帰）
        case editing       // 加工UIなど重ねるとき
        case saving        // 保存中インジケータなど
    }
    private var uiState: GalleryUIState = .normal {
        didSet { updateUIState() }
    }
    var onDismiss: (() -> Void)?
    
    //イニシャライズ

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
    
    //setupData
    //fetch
    //setupUI
    //setupBars
    //基本プロパティ
    private let navBarView = UIView()
    private let toolBarView = UIView()

    private func setupBars() {
        // MARK: - ナビバー（上）
        navBarView.frame = CGRect(
            x: 0,
            y: 0,
            width: contentView.bounds.width,
            height: 80
        )
        navBarView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        navBarView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        contentView.addSubview(navBarView)

        // Close
        let close = UIButton(type: .system)
        close.setTitle("×", for: .normal)
        close.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        close.tintColor = .white
        close.frame = CGRect(x: 10, y: 30, width: 50, height: 40)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        navBarView.addSubview(close)

        // 保存ボタン
        let save = UIButton(type: .system)
        save.setTitle("保存", for: .normal)
        save.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        save.tintColor = .white
        save.frame = CGRect(
            x: navBarView.bounds.width - 80,
            y: 30,
            width: 70,
            height: 40
        )
        save.autoresizingMask = [.flexibleLeftMargin]
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        navBarView.addSubview(save)

        // MARK: - 下ツールバー
        toolBarView.frame = CGRect(
            x: 0,
            y: contentView.bounds.height - 80,
            width: contentView.bounds.width,
            height: 80
        )
        toolBarView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        toolBarView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        contentView.addSubview(toolBarView)

        let edit = UIButton(type: .system)
        edit.setTitle("編集", for: .normal)
        edit.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        edit.tintColor = .white
        edit.frame = CGRect(x: 20, y: 20, width: 80, height: 40)
        edit.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        toolBarView.addSubview(edit)

        let delete = UIButton(type: .system)
        delete.setTitle("削除", for: .normal)
        delete.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        delete.tintColor = .white
        delete.frame = CGRect(
            x: toolBarView.bounds.width - 100,
            y: 20,
            width: 80,
            height: 40
        )
        delete.autoresizingMask = [.flexibleLeftMargin]
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        toolBarView.addSubview(delete)
    }
    @objc private func closeTapped() {
        //dismiss(animated: true)
    }

    @objc private func saveTapped() {
        // 保存処理（後で実装）
        print("保存 tapped")
    }

    @objc private func editTapped() {
        // 編集モードへ
        uiState = .editing
    }

    @objc private func deleteTapped() {
        // 削除のアクション
        print("削除 tapped")
    }


    @objc private func toggleBars() {
        switch uiState {
        case .normal:
            uiState = .hidden
        case .hidden:
            uiState = .normal
        default:
            break
        }
    }
    private func updateUIState() {
        switch uiState {
        case .normal:
            UIView.animate(withDuration: 0.25) {
                self.navBarView.alpha = 1
                self.toolBarView.alpha = 1
            }

        case .hidden:
            UIView.animate(withDuration: 0.25) {
                self.navBarView.alpha = 0
                self.toolBarView.alpha = 0
            }

        case .editing:
            UIView.animate(withDuration: 0.25) {
                self.navBarView.alpha = 0
                self.toolBarView.alpha = 0
            }
            //showEditingPanel()      // ← 後で作る加工UI

        case .saving: break
            //showSavingIndicator()    // ← 後で作る保存アニメーション
        }
    }



    //setupNavBar
    //setupToolBar
    //keyboardToolBar
    //setupGesture
}
