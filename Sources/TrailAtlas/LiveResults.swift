import Foundation
import FoundationNetworking

// The old HTML accepted arbitrary JSON timing endpoints in the browser. A public
// server cannot safely fetch arbitrary visitor-supplied URLs (SSRF risk).
// These vetted providers are permitted when they publish JSON over HTTPS;
// other links remain available as direct links/iframes.
enum LiveResults {
    static func isAllowedJSON(_ raw:String)->Bool {
        guard PublicHTTP.validURL(raw) != nil, let url=URLComponents(string:raw),url.scheme=="https",let host=url.host?.lowercased(),url.user==nil,url.password==nil else {return false}
        let allowed=["raceresult.com","livetrail.net","utmb.world"]
        guard allowed.contains(where:{host==$0 || host.hasSuffix("."+$0)}) else{return false}
        return url.path.lowercased().hasSuffix(".json") || (url.queryItems ?? []).contains(where:{$0.name=="format" && $0.value=="json"})
    }
    static func collectRows(_ json:Any) -> [[String:Any]]? {
        if let arr=json as? [[String:Any]]{return arr}
        guard let obj=json as? [String:Any] else {return nil}
        for key in ["results","participants","ranking","rankings","runners","entries","data"] {
            if let v=obj[key] as? [[String:Any]]{return v}
            if let nested=obj[key] as? [String:Any] {
                for inner in ["results","items","participants","data"] {
                    if let values=nested[inner] as? [[String:Any]]{return values}
                }
            }
        }
        return nil
    }
    static func safeValue(_ item:[String:Any],_ keys:[String])->String {
        for k in keys {
            if let val=item[k],!(val is [String:Any]),!(val is [Any]),!(val is NSNull) {return esc(String(describing:val))}
        }
        return "—"
    }
    static func fetch(_ raw:String) async -> String? {
        guard isAllowedJSON(raw) else{return nil}
        return await InlineResults.fetch(raw)
    }
}
