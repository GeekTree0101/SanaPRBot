import Foundation

extension Dictionary {
    var queryString: String? {
        var output: String = ""
        for (key,value) in self {
            output +=  "\(key)=\(value)&"
        }
        if output.last == "&" {
            output.removeLast()
        }
        return output.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}

extension Encodable {
    var dictionary: Dictionary<String, Any>? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap {  $0 as? Dictionary<String, Any> }
    }
    
    var arrayDictionary: [Dictionary<String, Any>]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap { $0 as? [Dictionary<String, Any>] }
    }
}
