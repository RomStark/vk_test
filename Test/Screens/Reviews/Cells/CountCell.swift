//
//  CountCell.swift
//  Test
//
//  Created by Al Stark on 02.03.2025.
//

import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct CountCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: CountCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Текст отзыва.
    let countText: NSAttributedString

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = CountCellLayout()

}

// MARK: - TableCellConfig

extension CountCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? CountCell else { return }
        cell.countTextLabel.attributedText = countText
        cell.config = self
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        return 44.0
    }

}

// MARK: - Cell

final class CountCell: UITableViewCell {

    fileprivate var config: Config?
   
    fileprivate let countTextLabel = UILabel()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }

        countTextLabel.frame = bounds
    }

}

// MARK: - Private

private extension CountCell {
    func setupCell() {
        setupCountTextLabel()
    }

    func setupCountTextLabel() {
        contentView.addSubview(countTextLabel)
        countTextLabel.textAlignment = .center
    }
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class CountCellLayout {

    // MARK: - Размеры

    // MARK: - Фреймы

  
    private(set) var countTextLabelFrame = CGRect.zero
   

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
}

// MARK: - Typealias

fileprivate typealias Config = CountCellConfig
fileprivate typealias Layout = CountCellLayout
