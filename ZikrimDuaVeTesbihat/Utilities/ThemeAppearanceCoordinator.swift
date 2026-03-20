import SwiftUI
import UIKit

@MainActor
final class ThemeAppearanceCoordinator {
    private var lastAppliedSignature: String?

    func apply(theme: AppTheme, reason: String) {
        let navigationAppearance = navigationAppearance(for: theme)
        let toolbarAppearance = toolbarAppearance(for: theme)
        let tabBarAppearance = tabBarAppearance(for: theme)

        applyNavigationAppearance(theme: theme, appearance: navigationAppearance)
        applyToolbarAppearance(appearance: toolbarAppearance, tint: UIColor(theme.accent))
        applyTabBarAppearance(theme: theme, appearance: tabBarAppearance)
        applyCollectionAndTableAppearance(theme: theme)
        refreshLiveChrome(
            navigationAppearance: navigationAppearance,
            toolbarAppearance: toolbarAppearance,
            tabBarAppearance: tabBarAppearance,
            theme: theme
        )

        if lastAppliedSignature != theme.runtimeSignature {
            debugLog("appearance reapplied theme=\(theme.themeID.rawValue) reason=\(reason)")
        } else {
            debugLog("appearance reapplied theme=\(theme.themeID.rawValue) reason=\(reason) same_signature=true")
        }
        lastAppliedSignature = theme.runtimeSignature
    }

    func applyNavigationAppearance(theme: AppTheme) {
        let appearance = navigationAppearance(for: theme)
        applyNavigationAppearance(theme: theme, appearance: appearance)
        refreshLiveNavigationBars(appearance: appearance, tint: UIColor(theme.accent))
    }

    private func applyNavigationAppearance(theme: AppTheme, appearance: UINavigationBarAppearance) {
        let proxy = UINavigationBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.compactAppearance = appearance
        proxy.compactScrollEdgeAppearance = appearance
        proxy.tintColor = UIColor(theme.accent)
    }

    private func applyToolbarAppearance(appearance: UIToolbarAppearance, tint: UIColor) {
        let proxy = UIToolbar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.compactAppearance = appearance
        proxy.tintColor = tint
    }

    private func applyTabBarAppearance(theme: AppTheme, appearance: UITabBarAppearance) {
        let proxy = UITabBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.tintColor = UIColor(theme.selectedTab)
        proxy.unselectedItemTintColor = UIColor(theme.unselectedTab)
        proxy.backgroundColor = .clear
        proxy.isTranslucent = true
    }

    private func applyCollectionAndTableAppearance(theme: AppTheme) {
        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }

    private func navigationAppearance(for theme: AppTheme) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.navBarBackground)
        appearance.shadowColor = UIColor(theme.divider.opacity(0.18))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(theme.primaryText)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(theme.primaryText)]
        return appearance
    }

    private func toolbarAppearance(for theme: AppTheme) -> UIToolbarAppearance {
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.navBarBackground)
        appearance.shadowColor = UIColor(theme.divider.opacity(0.18))
        return appearance
    }

    private func tabBarAppearance(for theme: AppTheme) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear

        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(theme.selectedTab),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        let unselectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(theme.unselectedTab),
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]

        let layouts = [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ]

        for layout in layouts {
            layout.normal.iconColor = UIColor(theme.unselectedTab)
            layout.normal.titleTextAttributes = unselectedAttributes
            layout.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
            layout.selected.iconColor = UIColor(theme.selectedTab)
            layout.selected.titleTextAttributes = selectedAttributes
            layout.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
        }

        return appearance
    }

    private func refreshLiveChrome(
        navigationAppearance: UINavigationBarAppearance,
        toolbarAppearance: UIToolbarAppearance,
        tabBarAppearance: UITabBarAppearance,
        theme: AppTheme
    ) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)

        for window in windows {
            window.tintColor = UIColor(theme.accent)

            guard let rootViewController = window.rootViewController else { continue }
            update(
                viewController: rootViewController,
                navigationAppearance: navigationAppearance,
                toolbarAppearance: toolbarAppearance,
                tabBarAppearance: tabBarAppearance,
                theme: theme
            )
        }
    }

    private func refreshLiveNavigationBars(appearance: UINavigationBarAppearance, tint: UIColor) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)

        for window in windows {
            guard let rootViewController = window.rootViewController else { continue }
            updateNavigationBars(in: rootViewController, appearance: appearance, tint: tint)
        }
    }

    private func update(
        viewController: UIViewController,
        navigationAppearance: UINavigationBarAppearance,
        toolbarAppearance: UIToolbarAppearance,
        tabBarAppearance: UITabBarAppearance,
        theme: AppTheme
    ) {
        if let navigationController = viewController as? UINavigationController {
            apply(navigationAppearance, to: navigationController.navigationBar, tint: UIColor(theme.accent))
            apply(toolbarAppearance, to: navigationController.toolbar, tint: UIColor(theme.accent))
        }

        if let tabBarController = viewController as? UITabBarController {
            apply(tabBarAppearance, to: tabBarController.tabBar, theme: theme)
        }

        for child in viewController.children {
            update(
                viewController: child,
                navigationAppearance: navigationAppearance,
                toolbarAppearance: toolbarAppearance,
                tabBarAppearance: tabBarAppearance,
                theme: theme
            )
        }

        if let presentedViewController = viewController.presentedViewController {
            update(
                viewController: presentedViewController,
                navigationAppearance: navigationAppearance,
                toolbarAppearance: toolbarAppearance,
                tabBarAppearance: tabBarAppearance,
                theme: theme
            )
        }
    }

    private func updateNavigationBars(in viewController: UIViewController, appearance: UINavigationBarAppearance, tint: UIColor) {
        if let navigationController = viewController as? UINavigationController {
            apply(appearance, to: navigationController.navigationBar, tint: tint)
        }

        for child in viewController.children {
            updateNavigationBars(in: child, appearance: appearance, tint: tint)
        }

        if let presentedViewController = viewController.presentedViewController {
            updateNavigationBars(in: presentedViewController, appearance: appearance, tint: tint)
        }
    }

    private func apply(_ appearance: UINavigationBarAppearance, to navigationBar: UINavigationBar, tint: UIColor) {
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
        navigationBar.tintColor = tint
        navigationBar.isTranslucent = false
        navigationBar.setNeedsLayout()
        navigationBar.layoutIfNeeded()
    }

    private func apply(_ appearance: UIToolbarAppearance, to toolbar: UIToolbar, tint: UIColor) {
        toolbar.standardAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        toolbar.compactAppearance = appearance
        toolbar.tintColor = tint
        toolbar.isTranslucent = false
        toolbar.setNeedsLayout()
        toolbar.layoutIfNeeded()
    }

    private func apply(_ appearance: UITabBarAppearance, to tabBar: UITabBar, theme: AppTheme) {
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = UIColor(theme.selectedTab)
        tabBar.unselectedItemTintColor = UIColor(theme.unselectedTab)
        tabBar.backgroundColor = .clear
        tabBar.barTintColor = .clear
        tabBar.isTranslucent = true
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[ThemeAppearanceCoordinator] \(message)")
#endif
    }
}
