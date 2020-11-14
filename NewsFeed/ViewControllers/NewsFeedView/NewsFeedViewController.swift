//
//  NewsFeedViewController.swift
//  NewsFeed
//
//  Created by Arman Davidoff on 10.03.2020.
//  Copyright (c) 2020 Arman Davidoff. All rights reserved.
//

import UIKit
import RxSwift

protocol NewsFeedDisplayLogic: class {
  func displayData(viewModel: NewsFeed.Model.ViewModel.ViewModelData)
}

class NewsFeedViewController: UIViewController, NewsFeedDisplayLogic {
    
    var interactor: NewsFeedBusinessLogic?

  // MARK: Object lifecycle
    var tableView: UITableView!
    var titleTopView = TitleView()
    var footerView = FooterView()
    var footerControl: Footer!
    var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshing), for: .valueChanged)
        return refresh
    }()
    var newsFeeds = NewsFeedsViewModel(cellModels: [])
    let dispose = DisposeBag()
    
  // MARK: Setup
    private func setup() {
        let viewController        = self
        let interactor            = NewsFeedInteractor()
        let presenter             = NewsFeedPresenter()
        viewController.interactor = interactor
        interactor.presenter      = presenter
        presenter.viewController  = viewController
    }

  // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        setup()
        setupTableView()
        setupTopBar()
        setupBinding()
        interactor?.makeRequest(request: .getNewsFeed)
        interactor?.makeRequest(request: .getUserInfo)
    }
    
    func displayData(viewModel: NewsFeed.Model.ViewModel.ViewModelData) {
        switch viewModel {
        case .displayNewsFeed(let newsFeed):
            newsFeeds.updatedNewsList.accept(newsFeed)
        case .displayUserInfo(let userInfo):
            newsFeeds.updatedUserInfo.accept(userInfo)
        case .displayNewsFeedFulltext(let newsFeed,let index):
            newsFeeds.showedFullText.accept((newsFeed,index))
        case .displayNextNewsFeed(let newsFeed):
            newsFeeds.addedNextNews.accept(newsFeed)
        case .displayErrorNewsFeed(error: let error):
            newsFeeds.updatedNewsListWithError.accept(error)
        case .displayErrorNextNewsFeed(error: let error):
            newsFeeds.addedNextNewsWithError.accept(error)
        }
    }
    
    @objc private func refreshing() {
        interactor?.makeRequest(request: .getNewsFeed)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.isAtBottom && newsFeeds.mayRequestNext()  {
            footerControl.start(count: newsFeeds.numberOfCells())
            newsFeeds.disallowRequestNext()
            interactor?.makeRequest(request: .getNextNewsFeed)
        }
    }
}

// MARK: TableViewDelegate&TableViewDataSource methods
extension NewsFeedViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        footerControl.stop(count: newsFeeds.numberOfCells(),info: "")
        return newsFeeds.numberOfCells()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedTableViewCell.cellID, for: indexPath) as! NewsFeedTableViewCell
        let model = newsFeeds.modelForCell(at: indexPath)
        cell.config(model: model)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return newsFeeds.heightForRow(at: indexPath)
    }
}

//Cell Delegate Functions
extension NewsFeedViewController: CustomCellDelegate {
    func showFullText(cell: NewsFeedTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        print(indexPath)
        self.interactor?.makeRequest(request: .showFullText(index: indexPath.row))
    }
}

//Setup UI
private extension NewsFeedViewController {
    
    func setupTopBar() {
        guard let navigationController = navigationController else { return }
        let navigationBar = navigationController.navigationBar
        navigationController.hidesBarsOnSwipe = true
        navigationController.overrideUserInterfaceStyle = .light
        navigationBar.shadowImage = UIImage()
        navigationItem.titleView = titleTopView
    }
    
    func setupTableView() {
        tableView = UITableView(frame: view.bounds)
        self.view.addSubview(tableView)
        tableView.contentInset.top = Constants.cardViewTopInset
        tableView.separatorStyle = .none
        tableView.backgroundView = UIView()
        tableView.backgroundView!.addGradientInView(cornerRadius: 0)
        tableView.register(NewsFeedTableViewCell.self, forCellReuseIdentifier: NewsFeedTableViewCell.cellID)
        tableView.addSubview(refreshControl)
        tableView.tableFooterView = footerView
        tableView.tableFooterView?.isHidden = false
        footerControl = (tableView.tableFooterView as! Footer)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
    }
}

//Update UI
private extension NewsFeedViewController {
    private func setupBinding() {
        newsFeeds.updatedNewsListPublish.asDriver(onErrorJustReturn: false).drive(onNext: {
            if $0 {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }).disposed(by: dispose)
        
        newsFeeds.addedNextNewsPublish.asDriver(onErrorJustReturn: false).drive(onNext: {
            if $0 {
                self.tableView.reloadData()
                self.footerControl.stop(count:self.newsFeeds.numberOfCells(),info: "")
            }
        }).disposed(by: dispose)
        
        newsFeeds.showedFullTextPublish.asDriver(onErrorJustReturn: false).drive(onNext: {
            if $0 { self.tableView.reloadData() }
        }).disposed(by: dispose)
        
        newsFeeds.updatedUserInfo.asDriver().drive(onNext: {
            if let user = $0 {
                self.titleTopView.setup(with: user)
            }
        }).disposed(by: dispose)
        
        newsFeeds.addedNextNewsWithError.asDriver().drive(onNext: {
            if let error = $0 {
                self.footerControl.stop(count: self.newsFeeds.numberOfCells(),info: error.localizedDescription)
            }
        }).disposed(by: dispose)
        
        newsFeeds.updatedNewsListWithError.asDriver().drive(onNext: {
            if let _ = $0 { self.refreshControl.endRefreshing() }
        }).disposed(by: dispose)
    }
}
