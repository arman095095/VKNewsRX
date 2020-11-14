//
//  NewsFeedModels.swift
//  NewsFeed
//
//  Created by Arman Davidoff on 10.03.2020.
//  Copyright (c) 2020 Arman Davidoff. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxRelay

class NewsFeedsViewModel {
    
    private var cellModels: [ModelForCell]
    
    private var mayRequestNextNews = true
    
    var updatedNewsList = BehaviorRelay<[ModelForCell]?>(value: nil)
    var updatedNewsListWithError = BehaviorRelay<NewsFeedService.Errors?>(value: nil)
    var updatedUserInfo = BehaviorRelay<UserInfoModel?>(value: nil)
    var addedNextNews = BehaviorRelay<[ModelForCell]?>(value: nil)
    var addedNextNewsWithError = BehaviorRelay<NewsFeedService.Errors?>(value: nil)
    var showedFullText = BehaviorRelay<(ModelForCell,Int)?>.init(value: nil)
    
    var updatedNewsListPublish = PublishSubject<Bool>.init()
    var addedNextNewsPublish = PublishSubject<Bool>.init()
    var showedFullTextPublish = PublishSubject<Bool>.init()
    
    let dispose = DisposeBag()
    
    init(cellModels: [ModelForCell]) {
        self.cellModels = cellModels
        binding()
    }
    
    private func binding() {
        updatedNewsList.asDriver().drive(onNext: { news in
            if let news = news {
                self.updateCellModels(models: news)
                self.allowRequestNext()
                self.updatedNewsListPublish.onNext(true)
            }
        }).disposed(by: dispose)
        addedNextNews.asDriver().drive(onNext: { news in
            if let news = news {
                self.addNewModels(models: news)
                self.allowRequestNext()
                self.addedNextNewsPublish.onNext(true)
            }
        }).disposed(by: dispose)
        showedFullText.asDriver().drive(onNext: { post in
            if let post = post {
                self.setCellModel(at: post.1, cellModel: post.0)
                self.showedFullTextPublish.onNext(true)
            }
        }).disposed(by: dispose)
        addedNextNewsWithError.asDriver().drive(onNext: { x in
            self.allowRequestNext()
        }).disposed(by: dispose)
    }

    func mayRequestNext() -> Bool {
        return mayRequestNextNews
    }
    
    func allowRequestNext() {
        mayRequestNextNews = true
    }
    
    func disallowRequestNext() {
        mayRequestNextNews = false
    }
    
    func numberOfCells() -> Int {
        return cellModels.count
    }
    
    func modelForCell(at indexPath: IndexPath) -> NewsFeedsViewModel.ModelForCell {
        return cellModels[indexPath.row]
    }
    
    func addNewModels(models: [ModelForCell]) {
        cellModels.append(contentsOf: models)
    }
    
    func getCellModels() -> [ModelForCell] {
        return cellModels
    }
    
    func updateCellModels(models: [NewsFeedsViewModel.ModelForCell]) {
        self.cellModels = models
    }
    
    func heightForRow(at indexPath: IndexPath) -> CGFloat {
        return modelForCell(at: indexPath).sizes.heightRow
    }
    
    func setCellModel(at index: Int, cellModel: ModelForCell) {
        cellModels[index] = cellModel
    }
}

extension NewsFeedsViewModel {
    class ModelForCell {
        init(postImageModels: [PostImageModelForCellProtocol], postId: Int, sizes: SizesProtocol, personImageURL: URL, name: String, date: String, postsText: String?, likesCount: String?, commentsCount: String?, repostsCount: String?, viewsCount: String?) {
            self.postImageModels = postImageModels
            self.postId = postId
            self.sizes = sizes
            self.personImageURL = personImageURL
            self.name = name
            self.date = date
            self.postsText = postsText
            self.likesCount = likesCount
            self.commentsCount = commentsCount
            self.repostsCount = repostsCount
            self.viewsCount = viewsCount
        }
        var postImageModels: [PostImageModelForCellProtocol]
        var postId: Int
        var sizes: SizesProtocol
        var personImageURL: URL
        var name: String
        var date: String
        var postsText: String?
        var likesCount: String?
        var commentsCount: String?
        var repostsCount: String?
        var viewsCount: String?
        
        struct Sizes: SizesProtocol {
            var imageFrame: CGRect
            var buttonFrame: CGRect
            var postFrame: CGRect
            var heightRow: CGFloat
        }
        struct PostImageModelForCell: PostImageModelForCellProtocol {
            var imageURLString: String
            var width: Int
            var height: Int
        }
    }
}
