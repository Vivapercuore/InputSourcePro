import XCTest
@testable import Input_Source_Pro

final class SpotlightIndicatorPositionTests: XCTestCase {
    private let visibleFrame = CGRect(x: 0, y: 0, width: 1512, height: 949)
    private let indicatorSize = CGSize(width: 54, height: 24)

    func testSearchFieldPositioningIsLimitedToTheNewSpotlightHostOnMacOS27AndLater() {
        XCTAssertFalse(SpotlightIndicatorPosition.usesSearchFieldBounds(bundleIdentifier: "com.apple.campo", macOSMajorVersion: 26))
        XCTAssertTrue(SpotlightIndicatorPosition.usesSearchFieldBounds(bundleIdentifier: "com.apple.campo", macOSMajorVersion: 27))
        XCTAssertTrue(SpotlightIndicatorPosition.usesSearchFieldBounds(bundleIdentifier: "com.apple.campo", macOSMajorVersion: 28))
        XCTAssertFalse(SpotlightIndicatorPosition.usesSearchFieldBounds(bundleIdentifier: "com.apple.Spotlight", macOSMajorVersion: 27))
        XCTAssertFalse(SpotlightIndicatorPosition.usesSearchFieldBounds(bundleIdentifier: "com.raycast.macos", macOSMajorVersion: 27))
        XCTAssertFalse(SpotlightIndicatorPosition.usesSearchFieldBounds(bundleIdentifier: nil, macOSMajorVersion: 27))
    }

    func testMeasuredSearchBarBoundsPlaceIndicatorNextToSpotlight() {
        // Measured on macOS 27: Quartz (498, 203, 558, 56), converted to
        // Cocoa coordinates on a 1512 x 982 display.
        let input = CGRect(x: 498, y: 723, width: 558, height: 56)

        XCTAssertEqual(point(for: input), CGPoint(x: 498, y: 785))
    }

    func testScreenSizedHostWindowCannotPlaceIndicatorInMenuBar() {
        XCTAssertNil(point(for: CGRect(x: 0, y: 0, width: 1512, height: 949)))
    }

    func testSearchBarNearTopPlacesIndicatorBelowInsteadOfInMenuBar() {
        XCTAssertEqual(
            point(for: CGRect(x: 498, y: 890, width: 558, height: 56)),
            CGPoint(x: 498, y: 860)
        )
    }

    func testPlacementUsesTheSecondaryDisplaysCoordinates() {
        let screen = CGRect(x: -1920, y: 300, width: 1920, height: 1047)
        let point = SpotlightIndicatorPosition.point(
            searchFieldBounds: CGRect(x: -1400, y: 900, width: 558, height: 56),
            indicatorSize: indicatorSize,
            visibleFrame: screen
        )

        XCTAssertEqual(point, CGPoint(x: -1400, y: 962))
    }

    func testIndicatorStaysInsideRightEdge() {
        XCTAssertEqual(
            point(for: CGRect(x: 1490, y: 723, width: 558, height: 56)),
            CGPoint(x: 1458, y: 785)
        )
    }

    func testInvalidAndOffscreenBoundsDoNotProduceAPosition() {
        XCTAssertNil(point(for: .zero))
        XCTAssertNil(point(for: CGRect(x: 498, y: 723, width: CGFloat.infinity, height: 56)))
        XCTAssertNil(point(for: CGRect(x: 2000, y: 723, width: 558, height: 56)))
    }

    private func point(for bounds: CGRect) -> CGPoint? {
        SpotlightIndicatorPosition.point(
            searchFieldBounds: bounds,
            indicatorSize: indicatorSize,
            visibleFrame: visibleFrame
        )
    }
}
