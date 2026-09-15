import AppKit
import CoreData
import XCTest
@testable import Input_Source_Pro

final class SpotlightCompatibilityTests: XCTestCase {
    private var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let modelURL = try XCTUnwrap([Bundle.main, Bundle(for: AppRule.self)].lazy.compactMap {
            $0.url(forResource: "Main", withExtension: "momd")
        }.first)
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelURL))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil)
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
    }

    override func tearDownWithError() throws {
        context = nil
        try super.tearDownWithError()
    }

    func testBothSpotlightProcessesAreRecognizedAsFloatingApps() {
        for bundleId in ["com.apple.Spotlight", "com.apple.campo"] {
            XCTAssertTrue(NSApplication.isFloatingApp(bundleId))
            XCTAssertTrue(NSApplication.isFloatingApp(bundleId, windowLayer: 23))
            XCTAssertTrue(NSApplication.isSpotlightLikeApp(bundleId))
        }
        XCTAssertFalse(NSApplication.isFloatingApp("com.apple.siri.launcher"))
        XCTAssertFalse(NSApplication.isFloatingApp(nil))
    }

    func testCampoReusesExistingSpotlightRuleWithoutChangingItsSettings() throws {
        let rule = makeRule("com.apple.Spotlight", name: "Spotlight")
        rule.inputSourceId = "com.apple.keylayout.ABC"
        rule.hideIndicator = true
        rule.doRestoreKeyboard = true
        rule.forceEnglishPunctuation = true
        try context.save()

        let match = try AppRule.matching(bundleId: "com.apple.campo", in: context)

        XCTAssertTrue(match === rule)
        XCTAssertEqual(match?.inputSourceId, "com.apple.keylayout.ABC")
        XCTAssertEqual(match?.hideIndicator, true)
        XCTAssertEqual(match?.doRestoreKeyboard, true)
        XCTAssertEqual(match?.forceEnglishPunctuation, true)
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.count(for: AppRule.fetchRequest()), 1)
    }

    func testLegacySpotlightCanUseImportedCampoRule() throws {
        let rule = makeRule("com.apple.campo", name: "Siri AI")
        try context.save()

        XCTAssertTrue(try AppRule.matching(bundleId: "com.apple.Spotlight", in: context) === rule)
    }

    func testExactRuleWinsWhenBothIdentifiersHaveRules() throws {
        let legacy = makeRule("com.apple.Spotlight", name: "Spotlight")
        let campo = makeRule("com.apple.campo", name: "Siri AI")
        try context.save()

        XCTAssertTrue(try AppRule.matching(bundleId: "com.apple.campo", in: context) === campo)
        XCTAssertTrue(try AppRule.matching(bundleId: "com.apple.Spotlight", in: context) === legacy)
    }

    func testSpotlightAliasesDoNotMatchOtherApps() throws {
        _ = makeRule("com.apple.Spotlight", name: "Spotlight")
        let finder = makeRule("com.apple.finder", name: "Finder")
        try context.save()

        XCTAssertNil(try AppRule.matching(bundleId: "com.apple.siri.launcher", in: context))
        XCTAssertTrue(try AppRule.matching(bundleId: "com.apple.finder", in: context) === finder)
    }

    func testCampoWithoutAnySpotlightRuleReturnsNil() throws {
        _ = makeRule("com.apple.finder", name: "Finder")
        try context.save()

        XCTAssertNil(try AppRule.matching(bundleId: "com.apple.campo", in: context))
    }

    func testSpotlightRulesHaveRecognizableNamesAcrossVersions() {
        XCTAssertEqual(makeRule("com.apple.campo", name: "Siri AI").displayName, "Spotlight")
        XCTAssertEqual(makeRule("com.apple.Spotlight", name: "Spotlight").displayName, "Spotlight")
        XCTAssertEqual(makeRule("com.apple.finder", name: "Finder").displayName, "Finder")
    }

    private func makeRule(_ bundleId: String, name: String) -> AppRule {
        let rule = NSEntityDescription.insertNewObject(forEntityName: "AppRule", into: context) as! AppRule
        rule.bundleId = bundleId
        rule.bundleName = name
        rule.url = URL(fileURLWithPath: "/Applications/\(name).app")
        rule.createdAt = Date()
        return rule
    }
}
