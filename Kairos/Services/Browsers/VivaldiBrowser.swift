import Foundation

class VivaldiBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "com.vivaldi.Vivaldi", displayName: "Vivaldi")
    }

    override var currentURLScript: String {
        return """
            tell application id "com.vivaldi.Vivaldi"
                if (count of windows) > 0 then
                    set currentTab to active tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }

    override func isInPrivateBrowsingMode() -> Bool? {
        let script = """
            tell application id "com.vivaldi.Vivaldi"
                if (count of windows) > 0 then
                    return mode of window 1 is equal to "incognito"
                end if
            end tell
            """

        let scriptResult = executeAppleScript(script)

        guard let result = scriptResult.result,
              let isPrivate = Bool(result.lowercased()) else {
            return nil
        }

        return isPrivate
    }
}
