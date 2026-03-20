import Foundation

// Release builds should not emit verbose console logs that may contain user-entered
// devotional prompts, auth diagnostics, or backend payload fragments.
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { String(describing: $0) }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    #else
    _ = items
    _ = separator
    _ = terminator
    #endif
}
