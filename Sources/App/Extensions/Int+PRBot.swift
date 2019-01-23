import Foundation

extension Int {
    struct Const {
        static let prUnitAvgLeadTime: Int = 15 // PR code review 평균 소요 시간: 15분
        static let koreaTimeZone: TimeZone? = TimeZone(secondsFromGMT: 3600 * 9)
    }
    
    var timeStamp: String {
        let leadTime = self * Const.prUnitAvgLeadTime
        let secUnit = leadTime * 60
        let fomatter = DateFormatter()
        fomatter.timeZone = Const.koreaTimeZone
        fomatter.dateStyle = .none
        fomatter.timeStyle = .short
        let stamp = Date(timeIntervalSinceNow: .init(secUnit))
        return fomatter.string(from: stamp)
    }
}

extension Date {
    static var now: String {
        return 0.timeStamp
    }
}
