//
//  ImageGalleryViewController.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/12.
//

import SwiftUI

import UIKit

// MARK: - ギャラリー
// MARK: - GalleryViewController
class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    

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
    
    //基本プロパティ
    
    var images: [UIImage]
    var initialIndex: Int
    private var collectionView: UICollectionView!
    
    var onDismiss: (() -> Void)?
    var onPanChanged: ((CGFloat) -> Void)? // translationY を渡すクロージャ

    // 下スワイプ用
    private let dimmingView = UIView()
    private var panStartCenter: CGPoint = .zero
    private var isDraggingToDismiss = false


    //initialize

    init(images: [UIImage], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) { fatalError() }
    
    
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panStartCenter = view.center
            isDraggingToDismiss = true
            collectionView.isScrollEnabled = false
        case .changed:
            // view 自体を移動
            view.center = CGPoint(x: panStartCenter.x + translation.x,
                                  y: panStartCenter.y + translation.y)

            // 下スワイプ量に応じて全体 alpha を変更
            let progress = min(1, abs(translation.y) / 400)
            view.alpha = 1 - progress

            // 親ビューのフェードも同時に通知
            onPanChanged?(translation.y)
        case .ended, .cancelled:
            collectionView.isScrollEnabled = true
            isDraggingToDismiss = false
            let progress = min(1, abs(translation.y) / 400)

            if translation.y > 150 || velocity.y > 500 {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.center.y += self.view.frame.height
                    self.view.alpha = 0
                }, completion: { _ in
                    self.dismiss(animated: false) {
                        self.onDismiss?()
                    }
                })
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.view.center = self.panStartCenter
                    self.view.alpha = 1
                    self.onPanChanged?(0)
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
}
