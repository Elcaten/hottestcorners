import Cocoa
import ServiceManagement

final class ApplicationsMenu: NSMenu {

    private let searchField = NSSearchField(frame: NSRect(x: 8, y: 4, width: 244, height: 24))
    private var favoriteItems: [NSMenuItem] = []
    private var otherItems: [NSMenuItem] = []
    private let favoritesSeparator = NSMenuItem.separator()
    private let noResultsItem = NSMenuItem(title: "No Applications Found", action: nil, keyEquivalent: "")

    init(corner: MainMenu.CornerType) {
        super.init(title: "ApplicationsMenu-\(corner.menuTitle())")

        addSearchItem()
        let doNothingItem = addDoNothingItem()
        addSeparator()

        var selectedNothing = true
        ApplicationsList.shared.favoritesApps.forEach  {
            favoriteItems.append(addApplication(corner: corner, appName: $0))
            if corner.applicationName == $0 { selectedNothing = false }
        }
        addItem(favoritesSeparator)
        ApplicationsList.shared.otherApps.forEach  {
            otherItems.append(addApplication(corner: corner, appName: $0))
            if corner.applicationName == $0 { selectedNothing = false }
        }
        noResultsItem.isEnabled = false
        noResultsItem.isHidden = true
        addItem(noResultsItem)
        updateSearchResults(for: "")

        if selectedNothing {
            corner.removeApplication()
            doNothingItem.state = .on
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Add methods

private extension ApplicationsMenu {

    func addSearchItem() {
        searchField.placeholderString = "Search Applications"
        searchField.sendsSearchStringImmediately = true
        searchField.delegate = self

        let searchItem = NSMenuItem()
        searchItem.view = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 32))
        searchItem.view?.addSubview(searchField)
        addItem(searchItem)
    }

    func addDoNothingItem() -> NSMenuItem {
        let item = addItem(
            withTitle: "Do Nothing",
            action: #selector(setDoNothing(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.tag = -1  // Just a magic number encoding "Nothing"
        return item
    }

    func addApplication(corner: MainMenu.CornerType, appName: String) -> NSMenuItem {
        let item = addItem(
            withTitle: appName,
            action: #selector(setApplication(_:)),
            keyEquivalent: ""
        )
        item.target = self
        if corner.applicationName == appName {
            item.state = .on
        }
        return item
    }

    func updateSearchResults(for query: String) {
        let matches: (NSMenuItem) -> Bool = { item in
            query.isEmpty || item.title.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) != nil
        }

        favoriteItems.forEach { $0.isHidden = !matches($0) }
        otherItems.forEach { $0.isHidden = !matches($0) }

        let hasFavoriteResults = favoriteItems.contains(where: { !$0.isHidden })
        let hasOtherResults = otherItems.contains(where: { !$0.isHidden })
        favoritesSeparator.isHidden = !hasFavoriteResults || !hasOtherResults
        noResultsItem.isHidden = hasFavoriteResults || hasOtherResults
    }

}

// MARK: - Search field delegate

extension ApplicationsMenu: NSSearchFieldDelegate {

    func controlTextDidChange(_ notification: Notification) {
        updateSearchResults(for: searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }

}

// MARK: - Menu actions

@objc
private extension ApplicationsMenu {

    func setApplication(_ sender: NSMenuItem) {
        guard
            let parentTag = sender.parent?.tag,
            let menuItems = sender.parent?.submenu?.items
        else {
            return
        }

        for item in menuItems {
            item.state = .off
        }
        sender.state = .on

        MainMenu.CornerType.getType(tag: parentTag)?.saveApplication(name: sender.title)
        StatusBarConfigurator.reloadMenu()
    }
    
    func setDoNothing(_ sender: NSMenuItem) {
        guard
            let parentTag = sender.parent?.tag,
            let menuItems = sender.parent?.submenu?.items
        else {
            return
        }

        for item in menuItems {
            item.state = .off
        }
        sender.state = .on

        MainMenu.CornerType.getType(tag: parentTag)?.removeApplication()
        StatusBarConfigurator.reloadMenu()
    }

}

// MARK: - Corner type extension

extension MainMenu.CornerType {

    static func getType(tag: Int) -> MainMenu.CornerType? {
        MainMenu.CornerType.allCases.first(where: { $0.menuTag == tag })
    }

    var applicationName: String? {
        switch self {
        case .lowerLeft:
            return UserDefaults.lowerLeftAppName
        case .lowerRight:
            return UserDefaults.lowerRightAppName
        case .upperLeft:
            return UserDefaults.upperLeftAppName
        case .upperRight:
            return UserDefaults.upperRightAppName
        }
    }

    func saveApplication(name: String) {
        switch self {
        case .lowerLeft:
            UserDefaults.setLowerLeftAppName(name)
        case .lowerRight:
            UserDefaults.setLowerRightAppName(name)
        case .upperLeft:
            UserDefaults.setUpperLeftAppName(name)
        case .upperRight:
            UserDefaults.setUpperRightAppName(name)
        }
    }

    func removeApplication() {
        switch self {
        case .lowerLeft:
            UserDefaults.removeLowerLeftAppName()
        case .lowerRight:
            UserDefaults.removeLowerRightAppName()
        case .upperLeft:
            UserDefaults.removeUpperLeftAppName()
        case .upperRight:
            UserDefaults.removeUpperRightAppName()
        }
    }

}
