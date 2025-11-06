extension Double {
    func clamped(_ lower: Double = 0, _ upper: Double = 1) -> Double {
        min(max(self, lower), upper)
    }
}
