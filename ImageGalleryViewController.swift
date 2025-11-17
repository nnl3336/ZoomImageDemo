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
    
    enum GalleryUIState {
        case normal        // ナビゲーションバー & ツールバー 表示
        case hidden        // 全て隠す（タップで復帰）
        case editing       // 加工UIなど重ねるとき
        case saving        // 保存中インジケータなど
    }
    private var uiState: GalleryUIState = .normal {
        didSet { updateUIState() }
    }


    //initialize

    init(images: [UIImage], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
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
        navBarView.frame = CGRect(x: 0, y: 0,
                                  width: view.bounds.width, height: 80)
        navBarView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        navBarView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        view.addSubview(navBarView)

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
        save.frame = CGRect(x: navBarView.bounds.width - 80, y: 30, width: 70, height: 40)
        save.autoresizingMask = [.flexibleLeftMargin]
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        navBarView.addSubview(save)



        // MARK: - ツールバー（下）
        toolBarView.frame = CGRect(x: 0,
                                   y: view.bounds.height - 80,
                                   width: view.bounds.width,
                                   height: 80)
        toolBarView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        toolBarView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(toolBarView)

        // 編集ボタン
        let edit = UIButton(type: .system)
        edit.setTitle("編集", for: .normal)
        edit.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        edit.tintColor = .white
        edit.frame = CGRect(x: 20, y: 20, width: 80, height: 40)
        edit.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        toolBarView.addSubview(edit)

        // 削除ボタン
        let delete = UIButton(type: .system)
        delete.setTitle("削除", for: .normal)
        delete.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        delete.tintColor = .white
        delete.frame = CGRect(x: toolBarView.bounds.width - 100, y: 20,
                              width: 80, height: 40)
        delete.autoresizingMask = [.flexibleLeftMargin]
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        toolBarView.addSubview(delete)
    }
    @objc private func closeTapped() {
        dismiss(animated: true)
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
