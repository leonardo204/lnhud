import Carbon.HIToolbox

protocol InputSourceReading {
    func currentInputSourceName() -> String?
    func currentInputSourceID() -> String?
    func installedKeyboardSources() -> [(id: String, name: String)]
}

final class InputSourceReader: InputSourceReading {
    func currentInputSourceName() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
        return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
    }

    func currentInputSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    }

    func installedKeyboardSources() -> [(id: String, name: String)] {
        let conditions = [
            kTISPropertyInputSourceCategory!: kTISCategoryKeyboardInputSource!,
            kTISPropertyInputSourceIsSelectCapable!: true
        ] as CFDictionary
        guard let sourceList = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        var results: [(id: String, name: String)] = []
        for source in sourceList {
            guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
                  let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { continue }
            let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
            results.append((id: id, name: name))
        }
        return results
    }
}
