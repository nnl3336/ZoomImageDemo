//
//  ContentView.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/12.
//

import SwiftUI
import CoreData

import UIKit

class ViewController: UIViewController {

    let thumbnailImageView = UIImageView(image: UIImage(named: "sample"))

    // 拡大時のビュー保持
    var zoomBackgroundView: UIView?
    var zoomImageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // サムネイル設定
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.frame = CGRect(x: 100, y: 200, width: 150, height: 150)
        thumbnailImageView.isUserInteractionEnabled = true
        view.addSubview(thumbnailImageView)

        // タップジェスチャー追加
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        thumbnailImageView.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView,
              let image = imageView.image,
              let window = UIApplication.shared.keyWindow else { return }

        // 背景ビュー
        let bgView = UIView(frame: window.bounds)
        bgView.backgroundColor = UIColor.black.withAlphaComponent(0)
        window.addSubview(bgView)
        self.zoomBackgroundView = bgView

        // 拡大画像
        let zoomView = UIImageView(image: image)
        zoomView.contentMode = .scaleAspectFit
        zoomView.frame = imageView.convert(imageView.bounds, to: window)
        bgView.addSubview(zoomView)
        self.zoomImageView = zoomView

        // タップで閉じる
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(closeZoom))
        bgView.addGestureRecognizer(closeTap)

        // アニメーション（ビヨン感あり）
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut]) {
            zoomView.frame = window.bounds
            bgView.backgroundColor = UIColor.black.withAlphaComponent(1)
        }
    }

    @objc func closeZoom() {
        guard let bgView = zoomBackgroundView,
              let zoomView = zoomImageView,
              let originalFrame = thumbnailImageView.superview?.convert(thumbnailImageView.frame, to: nil)
        else { return }

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.8,
                       options: [.curveEaseIn]) {
            zoomView.frame = originalFrame
            bgView.backgroundColor = UIColor.black.withAlphaComponent(0)
        } completion: { _ in
            zoomView.removeFromSuperview()
            bgView.removeFromSuperview()
        }
    }
}

// SwiftUI Preview / 使用例
struct ContentView: View {
    var body: some View {
        //NavigationView {
            ListVCWrapper()
                //.navigationTitle("Detail")
        //}
    }
}

// ListViewController 用ラッパー
struct ListVCWrapper: UIViewControllerRepresentable {

    @Environment(\.managedObjectContext) var context

    func makeUIViewController(context: Context) -> UINavigationController {
        let folderVC = ViewController()
        //folderVC.context = self.context
        let nav = UINavigationController(rootViewController: folderVC)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 必要があれば更新
    }
}
