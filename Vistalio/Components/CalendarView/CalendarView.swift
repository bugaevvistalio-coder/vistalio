//
//  CalendarView.swift
//  Vistalio
//
//  Created by Julia Konkova on 07.06.2026.
//

import UIKit

class CalendarView: UIView {
    
    var selectedDate: Date?
    var onDateSelected: ((Date) -> ())?
    
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var previousMonthButton: UIButton!
    @IBOutlet private weak var nextMonthButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var view: UIView!
    
    var minDate: Date? {
        didSet {
            collectionView.reloadData()
        }
    }
    var maxDate: Date? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var months = [Date]()
    private var monthIndex = 0 {
        didSet {
            
            print("Display month name month index")
            displayMonthName(index: monthIndex)
            if monthIndex == 0 {
                previousMonthButton.isEnabled = false
                previousMonthButton.tintColor = UIColor.lightGrey
            } else {
                previousMonthButton.isEnabled = true
                previousMonthButton.tintColor = UIColor.black
            }
        }
    }
    
    private var previousPage = 0
    
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
        
        let nib = UINib(nibName: "CalendarViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "CalendarViewCell")
    }
    
    func generateMonths() {
        months.removeAll()
        let calendar = Calendar.current
        let month = selectedDate ?? minDate ?? Date()
        months.append(month)
        
        var m = calendar.date(byAdding: .month, value: -1, to: month)!
        var added = addMonthBefore(m: m)
        if added {
            m = calendar.date(byAdding: .month, value: -2, to: month)!
            addMonthBefore(m: m)
        }
        
        m = calendar.date(byAdding: .month, value: 1, to: month)!
        added = addMonthAfter(m: m)
        if added {
            m = calendar.date(byAdding: .month, value: 2, to: month)!
            addMonthAfter(m: m)
        }
        
        monthIndex = months.firstIndex(of: month)!
        collectionView.scrollToItem(at: IndexPath(row: monthIndex, section: 0), at: .left, animated: false)
    }
    
    @discardableResult private func addMonthBefore(m: Date) -> Bool {
//        if let minDate = minDate {
//            if minDate < Calendar.current.date(byAdding: .month, value: 1, to: m)!.startOfMonth {
//                months.insert(m, at: 0)
//            } else {
//                return false
//            }
//        } else {
            months.insert(m, at: 0)
//        }
        return true
    }
    
    @discardableResult private func addMonthAfter(m: Date) -> Bool {
//        if let maxDate = maxDate {
//            if maxDate >= m.startOfMonth {
//                months.append(m)
//            } else {
//                return false
//            }
//        } else {
            months.append(m)
//        }
        return true
    }
    
    private func displayMonthName(index: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        formatter.locale = Locale(identifier: "ru_RU")
        let monthName = formatter.string(from: months[index]).capitalized
        if monthName != monthLabel.text {
            monthLabel.text = monthName
        }
    }
    
    @IBAction func previousTapped(_ sender: AnyObject) {
        collectionView.scrollToItem(at: IndexPath(row: monthIndex-1, section: 0), at: .left, animated: true)
    }
    
    @IBAction func nextTapped(_ sender: AnyObject) {
        collectionView.scrollToItem(at: IndexPath(row: monthIndex+1, section: 0), at: .left, animated: true)
    }
    
    func clearSelectionDate() {
        selectedDate = nil
        collectionView.reloadData()
    }
}

extension CalendarView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarViewCell", for: indexPath) as! CalendarViewCell
        cell.month = months[indexPath.row]
        cell.selectedDate = selectedDate
        cell.minDate = minDate
        cell.maxDate = maxDate
        cell.onDateSelected = { [unowned self] date in
            self.selectedDate = date
            self.onDateSelected?(date)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as! CalendarViewCell).selectedDate = selectedDate
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        previousPage = monthIndex
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        if w > 0 {
            let floorPage = Int(floor(x/w))
            let ceilPage = Int(ceil(x/w))
            if previousPage != floorPage && previousPage != ceilPage {
                previousPage = monthIndex
            }
            let page = (floorPage != previousPage) ? floorPage : (ceilPage != previousPage) ? ceilPage : previousPage
            print("Page \(floorPage), \(ceilPage), \(previousPage), \(page)")
//            let page = Int(ceil(x/w))
            if page != monthIndex {
                if page < 2 {
                    let previuosOffset = collectionView.contentOffset.x
                    if addMonthBefore(m: Calendar.current.date(byAdding: .month, value: -1, to: months.first!)!) {
                        monthIndex = page + 1
                        previousPage += 1
                        collectionView.reloadData()
                        collectionView.layoutIfNeeded()
                        collectionView.contentOffset = CGPoint(x: previuosOffset + 312, y: collectionView.contentOffset.y)
                    } else {
                        monthIndex = page
                    }
                } else if page > months.count - 3 {
                    monthIndex = page
                    if addMonthAfter(m: Calendar.current.date(byAdding: .month, value: 1, to: months.last!)!) {
                        collectionView.reloadData()
                    }
                } else {
                    monthIndex = page
                }
            }
        }
    }
}
