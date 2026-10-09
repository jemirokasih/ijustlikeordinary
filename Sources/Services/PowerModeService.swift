import Foundation
import Combine

public final class PowerModeService: ObservableObject {
    public static let shared = PowerModeService()

    @Published public var isAuthorized: Bool = false

    private init() {
        self.isAuthorized = checkAuthorization()
    }

    public var isLowPowerModeActive: Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("lowpowermode") {
                        return trimmed.contains("1")
                    }
                }
            }
        } catch {
            return false
        }
        return false
    }

    public func checkAuthorization() -> Bool {
        if FileManager.default.fileExists(atPath: "/etc/sudoers.d/ijustlikeordinary") {
            return true
        }

        let task = Process()
        task.launchPath = "/usr/bin/sudo"
        task.arguments = ["-n", "/usr/bin/pmset", "-a", "lowpowermode", isLowPowerModeActive ? "1" : "0"]
        task.standardOutput = Pipe()
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    public var isPasswordlessSudoConfigured: Bool {
        return checkAuthorization()
    }

    public static let sudoersCommand: String = """
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pmset -a lowpowermode *" | sudo tee /etc/sudoers.d/ijustlikeordinary && sudo chmod 0440 /etc/sudoers.d/ijustlikeordinary
    """

    @discardableResult
    public func requestOneTimeAuthorization() -> Bool {
        let user = NSUserName()
        let command = "echo '\(user) ALL=(ALL) NOPASSWD: /usr/bin/pmset -a lowpowermode *' > /etc/sudoers.d/ijustlikeordinary && chmod 0440 /etc/sudoers.d/ijustlikeordinary"
        let script = "do shell script \"\(command)\" with administrator privileges"

        let osa = Process()
        osa.launchPath = "/usr/bin/osascript"
        osa.arguments = ["-e", script]
        osa.standardOutput = Pipe()
        osa.standardError = Pipe()

        do {
            try osa.run()
            osa.waitUntilExit()
            let success = (osa.terminationStatus == 0) && checkAuthorization()
            DispatchQueue.main.async {
                self.isAuthorized = self.checkAuthorization()
            }
            return success
        } catch {
            return false
        }
    }

    @discardableResult
    public func setLowPowerMode(enabled: Bool) -> Bool {
        let flag = enabled ? "1" : "0"

        // Try passwordless sudo first
        let task = Process()
        task.launchPath = "/usr/bin/sudo"
        task.arguments = ["-n", "/usr/bin/pmset", "-a", "lowpowermode", flag]
        task.standardOutput = Pipe()
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                return true
            }
        } catch {}

        // Fallback: osascript with administrator privileges
        let script = "do shell script \"pmset -a lowpowermode \(flag)\" with administrator privileges"
        let osa = Process()
        osa.launchPath = "/usr/bin/osascript"
        osa.arguments = ["-e", script]
        osa.standardOutput = Pipe()
        osa.standardError = Pipe()

        do {
            try osa.run()
            osa.waitUntilExit()
            return osa.terminationStatus == 0
        } catch {
            return false
        }
    }
}
