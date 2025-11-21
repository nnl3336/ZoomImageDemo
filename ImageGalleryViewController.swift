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
//    private let saveButton = UIButton(type: .system)
//    private let cancelButton = UIButton(type: .system)

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
    // MARK: - ナビゲーションバーとツールバーのプロパティ
    private let navBar = UINavigationBar()
    private let editNavBarView = UIView() // 編集モード用バー
    private let toolBar = UIToolbar()

    // ナビバーのボタン
    private var closeButton: UIBarButtonItem!
    private var saveButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!

    // ツールバーのボタン
    private var editButton: UIBarButtonItem!
    private var deleteButton: UIBarButtonItem!
    private var filterButton: UIBarButtonItem!
    private var rotateButton: UIBarButtonItem!
    
    private func setupBars() {
        // ---- 通常ナビバー ----
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = .white

        // 左ボタン（閉じる）
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("×", for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        let closeButton = UIBarButtonItem(customView: closeBtn)

        // 右ボタン（保存）
        saveButton = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(saveTapped))
        saveButton.tintColor = .white

        let navItem = UINavigationItem(title: "")
        navItem.leftBarButtonItems = [closeButton]
        navItem.rightBarButtonItems = [saveButton]
        navBar.items = [navItem]

        // AutoLayout
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 44)
        ])

        
        // ---- 編集ナビバー ----
        editNavBarView.translatesAutoresizingMaskIntoConstraints = false
        editNavBarView.backgroundColor = .black
        editNavBarView.isHidden = true
        view.addSubview(editNavBarView)

        NSLayoutConstraint.activate([
            editNavBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            editNavBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editNavBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editNavBarView.heightAnchor.constraint(equalToConstant: 44)
        ])

        // 編集バー中央タイトル
        let label = UILabel()
        label.text = "編集中"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        editNavBarView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: editNavBarView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: editNavBarView.centerYAnchor)
        ])

        // 編集バー右：保存
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("保存", for: .normal)
        saveBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        saveBtn.tintColor = .white
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        editNavBarView.addSubview(saveBtn)
        NSLayoutConstraint.activate([
            saveBtn.trailingAnchor.constraint(equalTo: editNavBarView.trailingAnchor, constant: -16),
            saveBtn.centerYAnchor.constraint(equalTo: editNavBarView.centerYAnchor)
        ])

        // 編集バー左：キャンセル
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("キャンセル", for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 16)
        cancelBtn.tintColor = .white
        cancelBtn.addTarget(self, action: #selector(cancelEditing), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        editNavBarView.addSubview(cancelBtn)
        NSLayoutConstraint.activate([
            cancelBtn.leadingAnchor.constraint(equalTo: editNavBarView.leadingAnchor, constant: 16),
            cancelBtn.centerYAnchor.constraint(equalTo: editNavBarView.centerYAnchor)
        ])

        // ---- ツールバー ----
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.barTintColor = .black
        toolBar.tintColor = .white
        toolBar.isTranslucent = false
        view.addSubview(toolBar)

        editButton = UIBarButtonItem(title: "編集", style: .plain, target: self, action: #selector(editTapped))
        deleteButton = UIBarButtonItem(title: "削除", style: .plain, target: self, action: #selector(deleteTapped))
        filterButton = UIBarButtonItem(title: "フィルター", style: .plain, target: self, action: #selector(applyFilter))
        rotateButton = UIBarButtonItem(title: "回転", style: .plain, target: self, action: #selector(rotateImage))
        toolBar.setItems([editButton, UIBarButtonItem.flexibleSpace(), deleteButton], animated: false)

        NSLayoutConstraint.activate([
            toolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBar.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    
    private func updateUIState() {
        switch uiState {

        case .normal:
            navBar.isHidden = false
            editNavBarView.isHidden = true

            toolBar.setItems(
                [editButton, UIBarButtonItem.flexibleSpace(), deleteButton],
                animated: true
            )

        case .editing:
            navBar.isHidden = true
            editNavBarView.isHidden = false

            toolBar.setItems(
                [filterButton, UIBarButtonItem.flexibleSpace(), rotateButton],
                animated: true
            )

        case .hidden:
            navBar.isHidden = true
            toolBar.isHidden = true
            editNavBarView.isHidden = true

        case .saving:
            break
        }
    }

    @objc private func applyFilter() {
        print("フィルター適用")
    }

    @objc private func rotateImage() {
        print("画像回転")
    }
    
}
