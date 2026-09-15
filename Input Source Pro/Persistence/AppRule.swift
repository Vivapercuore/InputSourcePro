import Cocoa

extension AppRule {
    var displayName: String {
        NSApplication.isSpotlightApp(bundleId) ? "Spotlight" : bundleName ?? "(unknown)"
    }

    static func matching(bundleId: String, in context: NSManagedObjectContext) throws -> AppRule? {
        let request = fetchRequest()
        if NSApplication.isSpotlightApp(bundleId) {
            request.predicate = NSPredicate(format: "bundleId IN %@", NSApplication.spotlightBundleIdentifiers)
        } else {
            request.predicate = NSPredicate(format: "bundleId == %@", bundleId)
        }

        let rules = try context.fetch(request)
        // Preserve an explicitly configured rule if both Spotlight identifiers
        // are present (for example, after importing settings).
        return rules.first(where: { $0.bundleId == bundleId }) ?? rules.first
    }

    var image: NSImage? {
        guard let path = url else { return nil }

        return NSWorkspace.shared.icon(forFile: path.path)
    }
}

extension AppRule {
    @MainActor
    var forcedKeyboard: InputSource? {
        return InputSource.resolvePersistedIdentifier(inputSourceId)
    }

    var functionKeyMode: FKeyMode? {
        get {
            guard let rawValue = functionKeyModeRaw else { return nil }
            return FKeyMode(rawValue: rawValue)
        }
        set {
            functionKeyModeRaw = newValue?.rawValue
        }
    }
    
    var shouldForceEnglishPunctuation: Bool {
        return forceEnglishPunctuation
    }
}
