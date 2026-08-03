import Foundation

class EdgeBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "com.microsoft.edgemac", displayName: "Edge")
    }

    override var currentURLScript: String {
        return """
            tell application "Microsoft Edge"
                if (count of windows) > 0 then
                    set currentTab to active tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }

    override func isInPrivateBrowsingMode() -> Bool? {
        let script = """
            tell application "Microsoft Edge"
                if (count of windows) > 0 then
                    return mode of window 1 is equal to "incognito"
                end if
            end tell
            """

        let scriptResult = executeAppleScript(script)

        guard let result = scriptResult.result,
              let isInPrivate = Bool(result.lowercased()) else {
            return nil
        }

        return isInPrivate
    }
}
