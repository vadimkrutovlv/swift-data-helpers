import SwiftDataHelpers
import SwiftUI
import UIKit

struct MainDatabaseUIKitPersonsList: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MainDatabaseUIKitPersonsViewController {
        return .init()
    }

    func updateUIViewController(
        _ uiViewController: MainDatabaseUIKitPersonsViewController,
        context: Context
    ) {}
}


final class MainDatabaseUIKitPersonsViewController: LiveQueryViewController {
    @LiveQuery(sort: [.init(\Person.name)])
    private var persons: [Person]

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var displayedPersons: [Person] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureEmptyLabel()
        observe($persons) { [weak self] snapshot in
            guard let self else { return }
            displayedPersons = snapshot
            tableView.reloadData()
            updateEmptyState()
        }
        updateEmptyState()
    }
}

private extension MainDatabaseUIKitPersonsViewController {
    func configureTableView() {
        view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PersonCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func configureEmptyLabel() {
        emptyLabel.text = "No people in Main DB."
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .preferredFont(forTextStyle: .footnote)
    }

    func updateEmptyState() {
        tableView.backgroundView = displayedPersons.isEmpty ? emptyLabel : nil
    }
}

extension MainDatabaseUIKitPersonsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPersons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath)
        let person = displayedPersons[indexPath.row]
        let name = person.name.isEmpty ? "Unnamed" : person.name

        var content = cell.defaultContentConfiguration()
        content.directionalLayoutMargins = .zero
        content.text = name
        content.secondaryText = "Age \(person.age.formatted())"
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        cell.layoutMargins = .zero
        cell.separatorInset = .zero
        cell.preservesSuperviewLayoutMargins = false

        return cell
    }
}

extension MainDatabaseUIKitPersonsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layoutMargins = .zero
        cell.separatorInset = .zero
        cell.preservesSuperviewLayoutMargins = false
    }
}
