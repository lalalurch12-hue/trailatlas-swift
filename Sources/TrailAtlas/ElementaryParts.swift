import Elementary

/// Actual Elementary-rendered components embedded into the preserved page template.
/// All CSS classes come from the old JavaScript card() markup (unchanged styles).
func tagHTML(_ text: String, klass: String = "") -> String {
    span(.class("tag" + (klass.isEmpty ? "" : " " + klass))) { text }.render()
}
func noticeHTML(_ text: String) -> String {
    p(.class("live-notice")) { text }.render()
}
