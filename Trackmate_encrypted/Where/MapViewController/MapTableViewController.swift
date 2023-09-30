//
//  MapTableViewController.swift
//  TrackMateEX
//
//  Created by iOSprogramming on 2023/08/15.
//

import UIKit

extension MapViewController: UITableViewDataSource, UITableViewDelegate {
    
    func initTableView(){
        // 테이블뷰 설정
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor(white: 0.7, alpha: 0.0) // 불투명한 배경색 설정
        tableView.layer.cornerRadius = 8 // 둥근 모서리 설정
        tableView.clipsToBounds = true
        tableView.register(MateListCell.self, forCellReuseIdentifier: "Cell")
        tableView.allowsMultipleSelection = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        // 오토레이아웃 설정

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            tableView.widthAnchor.constraint(equalToConstant: 100),
            tableView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    // UITableViewDataSource 메서드 구현
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MateListCell
        //Array(mates.keys).sorted()[indexPath.row]
        
        var userName = Array(mates.keys).sorted()[indexPath.row]
        if let mateInfo = mates[userName]{
            userName = userName + ":" + String(mateInfo.selected)
        }

        cell.mateLabel.text = userName
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = Array(mates.keys).sorted()[indexPath.row]
        if let mate = mates[user]{
            mate.selected = mate.selected == true ? false: true
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
 
    func reloadTable(){
        tableView.reloadData()
        let users = Array(mates.keys).sorted()
        for i in 0..<users.count{
            if let user = mates[users[i]]{
                if user.selected{
                    tableView.selectRow(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .top)
                }
            }
            
        }
    }
}

class MateListCell: UITableViewCell {

    public let mateImage: UIImageView = {

        let imgView = UIImageView()
        imgView.image = UIImage(named: "dogHouse.png")
        imgView.contentMode = .scaleAspectFill // 이미지의 비율을 유지하며 채우도록 설정
        imgView.clipsToBounds = true // 이미지가 셀을 벗어나지 않도록 설정
        return imgView

    }()

    public let mateLabel: UILabel = {

        let label = UILabel()
        label.textAlignment = .center // 레이블 텍스트 중앙 정렬
        label.font = UIFont(name: "Yeongdeok Snow Crab", size: 10)
        return label

    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // mateImage를 셀의 하위 뷰로 추가
        addSubview(mateImage)
        mateImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mateImage.topAnchor.constraint(equalTo: topAnchor),
            mateImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            mateImage.trailingAnchor.constraint(equalTo: trailingAnchor),
            mateImage.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // mateLabel을 셀의 하위 뷰로 추가
        addSubview(mateLabel)
        mateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            mateLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10) // 10 포인트 아래로 배치
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
    }
}
