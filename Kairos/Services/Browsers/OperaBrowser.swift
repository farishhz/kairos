import Foundation

class OperaBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "com.operasoftware.Opera", displayName: "Opera")
    }

    override var currentURLScript: String {
        return """
            tell application "Opera"
                if (count of windows) > 0 then
                    return URL of current tab of window 1
                end if
            end tell
            """
    }
}
