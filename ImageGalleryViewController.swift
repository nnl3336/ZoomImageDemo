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

        // dimmingView
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

        // ここでナビバー・ツールバーを追加（collectionView の上）
        setupBars()

        // 下スワイプ用
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    //編集バー
    
    private let editingPanel = UIView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private func setupEditingPanel() {
        editingPanel.frame = CGRect(x: 0, y: view.bounds.height - 100, width: view.bounds.width, height: 100)
        editingPanel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        editingPanel.isHidden = true
        view.addSubview(editingPanel)

        // 保存ボタン
        saveButton.setTitle("保存", for: .normal)
        saveButton.tintColor = .white
        saveButton.frame = CGRect(x: 20, y: 30, width: 100, height: 40)
        saveButton.addTarget(self, action: #selector(saveEditedImage), for: .touchUpInside)
        editingPanel.addSubview(saveButton)

        // キャンセルボタン
        cancelButton.setTitle("キャンセル", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.frame = CGRect(x: editingPanel.bounds.width - 120, y: 30, width: 100, height: 40)
        cancelButton.autoresizingMask = [.flexibleLeftMargin]
        cancelButton.addTarget(self, action: #selector(cancelEditing), for: .touchUpInside)
        editingPanel.addSubview(cancelButton)
    }

    // 保存
    @objc private func saveEditedImage() {
        print("保存処理")
        editingPanel.isHidden = true
        uiState = .normal
    }

    // キャンセル
    @objc private func cancelEditing() {
        print("キャンセル処理")
        editingPanel.isHidden = true
        uiState = .normal
    }


    //

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


    //イニシャライズ

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
        // ナビバー・ツールバーを隠して編集パネルを表示
        uiState = .editing
        //editingPanel.isHidden = false
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
    
    //updateState
    
    private func updateUIState() {
        switch uiState {
        case .normal:
            UIView.animate(withDuration: 0.25) {
                self.navBarView.alpha = 1
                self.toolBarView.alpha = 1
            }
            // ナビバーのボタン
            showNormalNavBarButtons()
            // ツールバーのボタン
            showNormalToolBarButtons()

        case .hidden:
            UIView.animate(withDuration: 0.25) {
                self.navBarView.alpha = 0
                self.toolBarView.alpha = 0
            }

        case .editing:
            UIView.animate(withDuration: 0.25) {
                self.navBarView.alpha = 1
                self.toolBarView.alpha = 1
            }
            // ナビバーのボタン差し替え
            showEditingNavBarButtons()
            // ツールバーのボタン差し替え
            showEditingToolBarButtons()

        case .saving:
            break
        }
    }

    // 例: ボタン差し替え
    private func showNormalNavBarButtons() {
        // 既存ボタンを削除
        navBarView.subviews.forEach { $0.removeFromSuperview() }

        let close = UIButton(type: .system)
        close.setTitle("×", for: .normal)
        close.frame = CGRect(x: 10, y: 30, width: 50, height: 40)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        navBarView.addSubview(close)

        let save = UIButton(type: .system)
        save.setTitle("保存", for: .normal)
        save.frame = CGRect(x: navBarView.bounds.width - 80, y: 30, width: 70, height: 40)
        save.autoresizingMask = [.flexibleLeftMargin]
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        navBarView.addSubview(save)
    }

    private func showEditingNavBarButtons() {
        navBarView.subviews.forEach { $0.removeFromSuperview() }

        let cancel = UIButton(type: .system)
        cancel.setTitle("キャンセル", for: .normal)
        cancel.frame = CGRect(x: 10, y: 30, width: 80, height: 40)
        cancel.addTarget(self, action: #selector(cancelEditing), for: .touchUpInside)
        navBarView.addSubview(cancel)

        let save = UIButton(type: .system)
        save.setTitle("保存", for: .normal)
        save.frame = CGRect(x: navBarView.bounds.width - 80, y: 30, width: 70, height: 40)
        save.autoresizingMask = [.flexibleLeftMargin]
        save.addTarget(self, action: #selector(saveEditedImage), for: .touchUpInside)
        navBarView.addSubview(save)
    }
    private func showNormalToolBarButtons() {
        toolBarView.subviews.forEach { $0.removeFromSuperview() }

        let edit = UIButton(type: .system)
        edit.setTitle("編集", for: .normal)
        edit.frame = CGRect(x: 20, y: 20, width: 80, height: 40)
        edit.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        toolBarView.addSubview(edit)

        let delete = UIButton(type: .system)
        delete.setTitle("削除", for: .normal)
        delete.frame = CGRect(x: toolBarView.bounds.width - 100, y: 20, width: 80, height: 40)
        delete.autoresizingMask = [.flexibleLeftMargin]
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        toolBarView.addSubview(delete)
    }

    private func showEditingToolBarButtons() {
        toolBarView.subviews.forEach { $0.removeFromSuperview() }

        let filter = UIButton(type: .system)
        filter.setTitle("フィルター", for: .normal)
        filter.frame = CGRect(x: 20, y: 20, width: 100, height: 40)
        filter.addTarget(self, action: #selector(applyFilter), for: .touchUpInside)
        toolBarView.addSubview(filter)

        let rotate = UIButton(type: .system)
        rotate.setTitle("回転", for: .normal)
        rotate.frame = CGRect(x: toolBarView.bounds.width - 100, y: 20, width: 80, height: 40)
        rotate.autoresizingMask = [.flexibleLeftMargin]
        rotate.addTarget(self, action: #selector(rotateImage), for: .touchUpInside)
        toolBarView.addSubview(rotate)
    }
    @objc private func applyFilter() {
        print("フィルター適用")
    }

    @objc private func rotateImage() {
        print("画像回転")
    }

    
}
