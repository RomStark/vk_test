import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    private var lastRequestTime: Date = .distantPast

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        state.items = state.items.filter( { $0.reuseId != CountCellConfig.reuseId } )
        DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try result.get()
                    let reviews = try self.decoder.decode(Reviews.self, from: data)

                    var newItems = self.state.items
                    newItems += reviews.items.map(self.makeReviewItem)
                    let shouldLoad = self.state.offset + self.state.limit < reviews.count
                    let newCount = shouldLoad ? self.state.offset + self.state.limit : reviews.count

                    DispatchQueue.main.async {
                        self.state.items = newItems
                        self.state.offset += self.state.limit
                        self.state.shouldLoad = shouldLoad
                        self.updateCountCell(count: newCount)
                        self.onStateChange?(self.state)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.state.shouldLoad = true
                    }
                }
            }
    }
    
    func updateCountCell(count: Int) {
        let countText = "\(count) \(count%10 <= 4 ? "отзыва" : "отзывов")".attributed(font: .reviewCount, color: .reviewCount)
        
        let countCell = CountCellConfig(countText: countText)
        if let lastItem = state.items.last, lastItem is CountCellConfig {
            state.items[state.items.count - 1] = countCell // Обновляем существующую countCell
        } else {
            state.items.append(countCell) // Добавляем, если её ещё нет
        }
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }

}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let userName = "\(review.first_name) \(review.last_name)".attributed(font: .username)
        let item = ReviewItem(
            reviewText: reviewText,
            created: created,
            userName: userName,
            onTapShowMore: showMoreReview,
            getImage: { [weak self] in
                self?.ratingRenderer.ratingImage(review.rating)
            },
            avatarURL: review.avatarURL
        )
        return item
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastRequestTime) > 0.3 else { return false } // 300 мс задержка
        lastRequestTime = now
        
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
