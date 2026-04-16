import XCTest
import Combine
@testable import LnHud

// MARK: - 테스트용 가짜 타이머

/// 실제 시간 경과 없이 수동으로 발화(fire)할 수 있는 테스트용 타이머
final class FakeHUDTimer: HUDTimerProtocol {
    struct ScheduledAction {
        let delay: TimeInterval
        let action: () -> Void
    }

    private(set) var scheduledActions: [ScheduledAction] = []
    private(set) var cancelCount = 0

    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> any Cancellable {
        let scheduled = ScheduledAction(delay: delay, action: action)
        scheduledActions.append(scheduled)
        return FakeCancellable { [weak self] in
            self?.cancelCount += 1
        }
    }

    /// 가장 최근에 예약된 액션을 실행
    func fireLast() {
        scheduledActions.last?.action()
    }

    /// 모든 예약된 액션을 순서대로 실행
    func fireAll() {
        let actions = scheduledActions
        scheduledActions.removeAll()
        actions.forEach { $0.action() }
    }

    func reset() {
        scheduledActions.removeAll()
        cancelCount = 0
    }
}

final class FakeCancellable: Cancellable {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        onCancel()
    }
}

// MARK: - HUDController 상태 전이 테스트

@MainActor
final class HUDControllerStateTests: XCTestCase {

    private var controller: HUDController!
    private var fakeTimer: FakeHUDTimer!

    override func setUp() {
        super.setUp()
        fakeTimer = FakeHUDTimer()
        controller = HUDController(timer: fakeTimer)
    }

    override func tearDown() {
        controller = nil
        fakeTimer = nil
        super.tearDown()
    }

    // MARK: - 초기 상태

    func test_initialState_isIdle() {
        XCTAssertEqual(controller.state, .idle)
    }

    func test_initialDisplayText_isEmpty() {
        // 초기 텍스트는 빈 문자열이거나 nil
        XCTAssertTrue(controller.displayText?.isEmpty ?? true)
    }

    // MARK: - show(text:) → fadeIn 전이

    func test_show_transitionsToFadeIn() {
        controller.show(text: "한국어")
        XCTAssertEqual(controller.state, .fadeIn)
    }

    func test_show_setsDisplayText() {
        controller.show(text: "English")
        XCTAssertEqual(controller.displayText, "English")
    }

    func test_show_schedulesTimer() {
        controller.show(text: "한국어")
        XCTAssertFalse(fakeTimer.scheduledActions.isEmpty)
    }

    // MARK: - fadeIn → visible 전이

    func test_show_fadeInCompletes_transitionsToVisible() {
        controller.show(text: "한국어")
        // fadeIn 완료 타이머 발화
        fakeTimer.fireLast()
        XCTAssertEqual(controller.state, .visible)
    }

    // MARK: - visible → fadeOut 전이

    func test_show_visibleTimerExpires_transitionsToFadeOut() {
        controller.show(text: "한국어")
        fakeTimer.fireLast() // fadeIn → visible
        fakeTimer.fireLast() // visible → fadeOut
        XCTAssertEqual(controller.state, .fadeOut)
    }

    // MARK: - fadeOut → idle 전이 (전체 사이클)

    func test_show_fullCycle_returnsToIdle() {
        controller.show(text: "한국어")
        fakeTimer.fireLast() // fadeIn → visible
        fakeTimer.fireLast() // visible → fadeOut
        fakeTimer.fireLast() // fadeOut → idle
        XCTAssertEqual(controller.state, .idle)
    }

    // MARK: - 연속 호출 (기존 타이머 취소 + 최신 텍스트 + fadeIn 재시작)

    func test_showCalledAgain_whileFadeIn_cancelsExistingTimer() {
        controller.show(text: "한국어")
        let cancelBefore = fakeTimer.cancelCount
        controller.show(text: "English")
        XCTAssertGreaterThan(fakeTimer.cancelCount, cancelBefore)
    }

    func test_showCalledAgain_updatesDisplayText() {
        controller.show(text: "한국어")
        controller.show(text: "English")
        XCTAssertEqual(controller.displayText, "English")
    }

    func test_showCalledAgain_whileFadeIn_restartsFromFadeIn() {
        controller.show(text: "한국어")
        fakeTimer.fireLast() // fadeIn → visible
        controller.show(text: "English") // 재시작
        XCTAssertEqual(controller.state, .fadeIn)
    }

    func test_showCalledAgain_whileVisible_restartsFromFadeIn() {
        controller.show(text: "한국어")
        fakeTimer.fireLast() // fadeIn → visible
        controller.show(text: "English")
        XCTAssertEqual(controller.state, .fadeIn)
    }

    func test_showCalledAgain_whileFadeOut_restartsFromFadeIn() {
        controller.show(text: "한국어")
        fakeTimer.fireLast() // fadeIn → visible
        fakeTimer.fireLast() // visible → fadeOut
        controller.show(text: "日本語")
        XCTAssertEqual(controller.state, .fadeIn)
    }

    // MARK: - 빠른 연속 호출 시 마지막 텍스트 반영

    func test_rapidSuccessiveCalls_lastTextDisplayed() {
        controller.show(text: "A")
        controller.show(text: "B")
        controller.show(text: "C")
        XCTAssertEqual(controller.displayText, "C")
    }

    func test_rapidSuccessiveCalls_staysInFadeIn() {
        controller.show(text: "A")
        controller.show(text: "B")
        controller.show(text: "C")
        XCTAssertEqual(controller.state, .fadeIn)
    }

    // MARK: - 타이머 지연값 검증

    func test_fadeInDuration_isApproximately0_15s() {
        controller.show(text: "한국어")
        // fadeIn 첫 번째 타이머 지연 확인 (약 0.15초)
        let firstDelay = fakeTimer.scheduledActions.first?.delay ?? 0
        XCTAssertEqual(firstDelay, 0.15, accuracy: 0.05)
    }

    func test_fadeOutDuration_isApproximately0_3s() {
        controller.show(text: "한국어")
        fakeTimer.fireLast() // fadeIn → visible (두 번째 타이머 예약됨)
        fakeTimer.fireLast() // visible → fadeOut (세 번째 타이머 예약됨)
        // fadeOut 타이머 지연 확인 (약 0.3초)
        let lastDelay = fakeTimer.scheduledActions.last?.delay ?? 0
        XCTAssertEqual(lastDelay, 0.3, accuracy: 0.05)
    }

    // MARK: - 빈 텍스트 처리

    func test_show_emptyText_stillTransitionsState() {
        controller.show(text: "")
        // 빈 텍스트도 상태 전이는 발생해야 함
        XCTAssertNotEqual(controller.state, .idle)
    }
}
