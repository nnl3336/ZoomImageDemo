//
//  SwiftUIView.swift
//  ZoomImageDemo
//
//  Created by Yuki Sasaki on 2025/11/16.
//

import SwiftUI


// MARK: - GalleryViewController
class YourViewController: UIViewController {
    //viewDidLoad()
    
    //action
    
    //***//デフォルトfunc

    //***//基本プロパティ
    
    //setupData
    //fetch
    //setupUI
    //setupNavBar
    //setupToolBar
    //keyboardToolBar
    //setupGesture
}

extension YourViewController: UITableViewDelegate {
}
extension YourViewController: UITableViewDataSource {
    //セル個数
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return 10 // 適当に
    }
    
    //セル表示
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
    }
}
