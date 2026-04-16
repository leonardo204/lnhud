import XCTest
@testable import LnHud

// MARK: - Mock 구현

/// 테스트용 MockInputSourceReader — protocol 준수 검증용
final class MockInputSourceReader: InputSourceReading {
    var stubbedName: String? = "Korean"
    var stubbedID: String? = "com.apple.inputmethod.Korean.2SetKorean"
    var nameCallCount = 0
    var idCallCount = 0

    func currentInputSourceName() -> String? {
        nameCallCount += 1
        return stubbedName
    }

    func currentInputSourceID() -> String? {
        idCallCount += 1
        return stubbedID
    }
}

// MARK: - 실제 TIS API 기반 테스트

final class InputSourceReaderTests: XCTestCase {

    private var reader: InputSourceReader!

    override func setUp() {
        super.setUp()
        reader = InputSourceReader()
    }

    override func tearDown() {
        reader = nil
        super.tearDown()
    }

    // MARK: - 실제 TIS 호출 테스트

    func test_currentInputSourceName_returnsNonNilValue() {
        // 시스템에는 반드시 하나 이상의 입력 소스가 있어야 함
        let name = reader.currentInputSourceName()
        XCTAssertNotNil(name, "입력 소스 이름은 nil이 아니어야 합니다")
    }

    func test_currentInputSourceName_returnsNonEmptyString() {
        let name = reader.currentInputSourceName()
        if let name = name {
            XCTAssertFalse(name.isEmpty, "입력 소스 이름은 빈 문자열이 아니어야 합니다")
        }
    }

    func test_currentInputSourceID_returnsNonNilValue() {
        let id = reader.currentInputSourceID()
        XCTAssertNotNil(id, "입력 소스 ID는 nil이 아니어야 합니다")
    }

    func test_currentInputSourceID_returnsNonEmptyString() {
        let id = reader.currentInputSourceID()
        if let id = id {
            XCTAssertFalse(id.isEmpty, "입력 소스 ID는 빈 문자열이 아니어야 합니다")
        }
    }

    func test_currentInputSourceID_containsComApplePrefix() {
        // macOS 기본 입력 소스 ID는 "com.apple." 접두어를 가짐
        let id = reader.currentInputSourceID()
        if let id = id {
            XCTAssertTrue(
                id.hasPrefix("com.apple."),
                "입력 소스 ID는 'com.apple.' 접두어를 포함해야 합니다. 실제 값: \(id)"
            )
        }
    }

    func test_currentInputSourceName_calledMultipleTimes_returnsConsistentResult() {
        let firstName = reader.currentInputSourceName()
        let secondName = reader.currentInputSourceName()
        // 짧은 시간 내 연속 호출은 동일한 값을 반환해야 함
        XCTAssertEqual(firstName, secondName)
    }

    func test_currentInputSourceID_calledMultipleTimes_returnsConsistentResult() {
        let firstID = reader.currentInputSourceID()
        let secondID = reader.currentInputSourceID()
        XCTAssertEqual(firstID, secondID)
    }

    // MARK: - InputSourceReading protocol 준수 검증 (Mock)

    func test_mockReader_conformsToProtocol() {
        // 컴파일 타임에 protocol 준수 확인
        let mock: InputSourceReading = MockInputSourceReader()
        XCTAssertNotNil(mock)
    }

    func test_mockReader_returnsStubName() {
        let mock = MockInputSourceReader()
        mock.stubbedName = "TestLanguage"
        XCTAssertEqual(mock.currentInputSourceName(), "TestLanguage")
    }

    func test_mockReader_returnsStubID() {
        let mock = MockInputSourceReader()
        mock.stubbedID = "com.apple.test.input"
        XCTAssertEqual(mock.currentInputSourceID(), "com.apple.test.input")
    }

    func test_mockReader_returnsNilName_whenStubIsNil() {
        let mock = MockInputSourceReader()
        mock.stubbedName = nil
        XCTAssertNil(mock.currentInputSourceName())
    }

    func test_mockReader_returnsNilID_whenStubIsNil() {
        let mock = MockInputSourceReader()
        mock.stubbedID = nil
        XCTAssertNil(mock.currentInputSourceID())
    }

    func test_mockReader_tracksNameCallCount() {
        let mock = MockInputSourceReader()
        _ = mock.currentInputSourceName()
        _ = mock.currentInputSourceName()
        XCTAssertEqual(mock.nameCallCount, 2)
    }

    func test_mockReader_tracksIDCallCount() {
        let mock = MockInputSourceReader()
        _ = mock.currentInputSourceID()
        XCTAssertEqual(mock.idCallCount, 1)
    }

    // MARK: - protocol 다형성 검증

    func test_inputSourceReading_realReader_conformsToProtocol() {
        let reader: InputSourceReading = InputSourceReader()
        let name = reader.currentInputSourceName()
        // 실제 구현이 protocol을 통해 올바르게 호출됨
        XCTAssertNotNil(name)
    }

    func test_inputSourceReading_mockCanReplaceReal() {
        // 의존성 주입 시나리오: InputSourceReading을 매개변수로 받는 함수에 Mock 주입
        func getDisplayName(from source: InputSourceReading) -> String {
            return source.currentInputSourceName() ?? "Unknown"
        }

        let mock = MockInputSourceReader()
        mock.stubbedName = "한국어"
        let displayName = getDisplayName(from: mock)
        XCTAssertEqual(displayName, "한국어")
    }
}
