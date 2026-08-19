//
//  WeeklyView.swift
//  Vistalio
//
//  Created by Julia Konkova on 14.08.2026.
//

import UIKit

class WeeklyView: UIView {
    
    var selectedDate: Date?
    var onDateSelected: ((Date) -> ())?
    
    @IBOutlet private weak var weekLabel: UILabel!
    @IBOutlet private weak var previousMonthButton: UIButton!
    @IBOutlet private weak var nextMonthButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var view: UIView!
    
    private var weeks = [Date]()
    private var previousPage = 0
    private let pageWidth: CGFloat = 336
    
    private var weekIndex = 0 {
        didSet {
            displayWeekName(index: weekIndex)
            if weekIndex == 0 {
                previousMonthButton.isEnabled = false
                previousMonthButton.tintColor = UIColor.lightGrey
            } else {
                previousMonthButton.isEnabled = true
                previousMonthButton.tintColor = UIColor.black
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        view = xibSetup()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = xibSetup()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .clear
        
        previousMonthButton.transform = CGAffineTransform(rotationAngle: -.pi/2)
        nextMonthButton.transform = CGAffineTransform(rotationAngle: .pi/2)
        
        let nib = UINib(nibName: "WeekViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "WeekViewCell")
    }
    
    func generateWeeks() {
        weeks.removeAll()
        let calendar = Calendar.current
        let week = (selectedDate ?? Date()).startOfWeek
        weeks.append(week)
        
        var w = calendar.date(byAdding: .weekOfYear, value: -1, to: week)!
        addWeekBefore(w: w)
        w = calendar.date(byAdding: .weekOfYear, value: -2, to: week)!
        addWeekBefore(w: w)
        
        w = calendar.date(byAdding: .weekOfYear, value: 1, to: week)!
        addWeekAfter(w: w)
        w = calendar.date(byAdding: .weekOfYear, value: 2, to: week)!
        addWeekAfter(w: w)
        
        weekIndex = 2
        
        collectionView.reloadData()
        DispatchQueue.main.async {
            self.collectionView.setContentOffset(CGPoint(x: self.weekIndex * Int(self.pageWidth), y: 0), animated: false)
        }
    }
    
    private func addWeekBefore(w: Date) {
        weeks.insert(w, at: 0)
    }
    
    private func addWeekAfter(w: Date) {
        weeks.append(w)
    }
    
    private func displayWeekName(index: Int) {
        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy"
        df.locale = Locale(identifier: "ru_RU")
        
        let calendar = Calendar.current
        let startDate = weeks[index]
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
        
        let weekName = "\(df.string(from: startDate).replacingOccurrences(of: ".", with: "")) - \(df.string(from: endDate).replacingOccurrences(of: ".", with: ""))"
        if weekName != weekLabel.text {
            weekLabel.text = weekName
        }
    }
    
    private func scrollToIndex(_ index: Int, animated: Bool) {
        collectionView.scrollToItem(at: IndexPath(row: index * 7, section: 0), at: .left, animated: animated)
    }
    
    @IBAction func previousTapped(_ sender: AnyObject) {
        scrollToIndex(weekIndex - 1, animated: true)
    }
    
    @IBAction func nextTapped(_ sender: AnyObject) {
        scrollToIndex(weekIndex + 1, animated: true)
    }
    
    func clearSelectionDate() {
        selectedDate = nil
        collectionView.reloadData()
    }
    
    func refresh() {
        collectionView.reloadData()
    }
}

extension WeeklyView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weeks.count * 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeekViewCell", for: indexPath) as! WeekViewCell
        cell.day = Calendar.current.date(byAdding: .day, value: indexPath.row, to: weeks.first!)
        cell.isSelectedDate = selectedDate != nil && cell.day.isSameDay(selectedDate!)
        cell.onDateSelected = { [unowned self] date in
            selectedDate = date
            collectionView.reloadData()
            onDateSelected?(date)
        }
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        previousPage = weekIndex
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = pageWidth
        if w > 0 {
            let floorPage = Int(floor(x/w))
            let ceilPage = Int(ceil(x/w))
            if previousPage != floorPage && previousPage != ceilPage {
                previousPage = weekIndex
            }
            let page = (floorPage != previousPage) ? floorPage : (ceilPage != previousPage) ? ceilPage : previousPage
            if page != weekIndex {
                if page < 2 {
                    let previuosOffset = collectionView.contentOffset.x
                    addWeekBefore(w: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weeks.first!)!)
                    weekIndex = page + 1
                    previousPage += 1
                    collectionView.reloadData()
                    collectionView.layoutIfNeeded()
                    collectionView.contentOffset = CGPoint(x: previuosOffset + pageWidth, y: collectionView.contentOffset.y)
                } else if page > weeks.count - 3 {
                    weekIndex = page
                    addWeekAfter(w: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weeks.last!)!)
                    collectionView.reloadData()
                } else {
                    weekIndex = page
                }
            }
        }
    }
}
