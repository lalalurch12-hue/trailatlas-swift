// Used exclusively for standalone Core/UI typechecking when package dependencies
// cannot be fetched. The deployed application uses ElementaryParts.swift.
func tagHTML(_ text: String, klass: String = "") -> String {
    "<span class=\"tag \(klass)\">\(esc(text))</span>"
}
func noticeHTML(_ text: String) -> String {"<p class=\"live-notice\">\(esc(text))</p>"}
