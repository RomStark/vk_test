import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsViews = makeReviewsView()
    private let viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsViews
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsViews = ReviewsView()
        reviewsViews.tableView.delegate = viewModel
        reviewsViews.tableView.dataSource = viewModel
        return reviewsViews
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak reviewsViews] _ in
            reviewsViews?.tableView.reloadData()
        }
    }

}
