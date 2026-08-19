//
//  HiddenStepsViewController.swift
//  Vistalio
//
//  Created by Julia Konkova on 09.05.2026.
//

import UIKit
import FittedSheets

class HiddenStepsViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var notificationsStackView: UIStackView!
    
    var mission: Mission!
    var onStepHidden: (() -> ())?
    
    private var steps = [MissionStep]()
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setShadow(offset: CGSize(width: 0, height: 0), radius: 10, cornerRadius: 20, shadowOpacity: 0.1, bounds: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        steps = (mission.blocks?.allObjects as? [StepsBlock])?.flatMap { ($0.steps?.allObjects as? [MissionStep])?.filter { $0.hidden } ?? []}.sorted(by: { $0.id < $1.id }) ?? []
    }
    
    @IBAction func closeTapped() {
        dismiss(animated: true)
    }
    
    private func showMenu(step: MissionStep, anchorRect: CGRect, image: UIImage) {
        let menuUnderlayControl = sheetViewController!.addMenuUnderlayControl(color: .black.withAlphaComponent(0.25))
        
        let menuView = MenuView()
        menuView.items = [
            MenuItemData(text: "Изменить", image: .edit, type: .normal, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                
                let row = steps.firstIndex(of: step)!
                openEditStep(mission: mission, step: step) { [unowned self] step in
                    notificationsStackView.addNotification(text: "Шаг изменён")
                    
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                    tableView.endUpdates()
                }
            }),
            MenuItemData(text: "Вернуть из скрытых", image: .eyeOn1, type: .blue, action: { [unowned self] in
                menuUnderlayControl.removeFromSuperview()
                CoreDataStack.shared.performAndWait { context in
                    step.hidden = false
                }
                if let index = steps.firstIndex(where: { $0.id == step.id }) {
                    steps.remove(at: index)
                    onStepHidden?()
                    if steps.isEmpty {
                        dismiss(animated: true)
                    } else {
                        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                }
            })
        ]
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(menuView)
        
        let screenHeight = UIScreen.main.bounds.height
        let menuHeight = CGFloat(menuView.height)
        let horizontalConstraint = menuView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: 20)
        let verticalConstraint = anchorRect.maxY + 20 + menuHeight > screenHeight ? menuView.bottomAnchor.constraint(equalTo: menuUnderlayControl.bottomAnchor, constant: anchorRect.minY - 7 - screenHeight) : menuView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.maxY + 7)
        NSLayoutConstraint.activate([verticalConstraint, horizontalConstraint])
        
        menuView.layer.cornerRadius = 30
        
        let highlightedItemImageView = UIImageView()
        highlightedItemImageView.translatesAutoresizingMaskIntoConstraints = false
        menuUnderlayControl.addSubview(highlightedItemImageView)
        
        let constraints = [
            highlightedItemImageView.topAnchor.constraint(equalTo: menuUnderlayControl.topAnchor, constant: anchorRect.minY),
            highlightedItemImageView.leftAnchor.constraint(equalTo: menuUnderlayControl.leftAnchor, constant: anchorRect.minX),
            highlightedItemImageView.widthAnchor.constraint(equalToConstant: anchorRect.width),
            highlightedItemImageView.heightAnchor.constraint(equalToConstant: anchorRect.height),
        ]
        NSLayoutConstraint.activate(constraints)
        
        highlightedItemImageView.image = image
    }
}

extension HiddenStepsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedStepCell", for: indexPath) as! RecommendedStepCell
        let step = steps[indexPath.row]
        cell.step = step
        cell.onStepTapped = {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        cell.onStepAdded = { [unowned self] step in
            if let index = steps.firstIndex(of: step) {
                steps.remove(at: index)
                onStepHidden?()
                if steps.isEmpty {
                    dismiss(animated: true)
                } else {
                    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        }
        cell.onLongGesture = { [unowned self] image, rect in
            self.generator.impactOccurred()
            self.generator.prepare()
            self.showMenu(step: step, anchorRect: rect, image: image)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
}
