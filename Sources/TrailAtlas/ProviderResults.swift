import Foundation

/// Public endpoints used by the provider's own public site, verified against
/// real responses. No credentials, private mini-programs or paywall bypass.
enum ProviderResults {
    static func utmb(_ url:URL) async -> String? {
        let parts=url.path.split(separator:"/").map(String.init)
        guard parts.count>=2,parts[0].range(of:#"^[a-z0-9-]+$"#,options:.regularExpression) != nil,
              parts[1].range(of:#"^20\d{2}$"#,options:.regularExpression) != nil else{return nil}
        let headers=["X-Tenant":parts[0]+"_"+parts[1],"Accept":"application/json"]
        do {
            let page=try await PublicHTTP.fetch("https://utmblive-api.utmb.world/homepage",trusted:true,headers:headers)
            guard page.status==200,let object=try JSONSerialization.jsonObject(with:page.data) as? [String:Any],
                  let races=object["races"] as? [[String:Any]],!races.isEmpty else{return nil}
            var output=""
            for race in races.prefix(8) {
                guard let id=race["raceId"] as? String,id.range(of:#"^[a-zA-Z0-9_-]+$"#,options:.regularExpression) != nil else{continue}
                let status=race["status"] as? String ?? ""
                let type=status=="FINISHED" ? "FINAL_RANKING" : "LIVE_RANKING"
                let endpoint="https://utmblive-api.utmb.world/races/\(id)?type=\(type)&page=0&limit=30"
                var runners:[[String:Any]]=[]
                if let rankingPage=try? await PublicHTTP.fetch(endpoint,trusted:true,headers:headers),rankingPage.status==200,
                   let ranking=try? JSONSerialization.jsonObject(with:rankingPage.data) as? [String:Any] {
                    let progressive=ranking["raceProgressive"] as? [String:Any] ?? [:]
                    runners=(ranking["runners"] as? [[String:Any]]) ?? (progressive["runners"] as? [[String:Any]]) ?? []
                }
                var isTop3=false
                if runners.isEmpty,let top=race["top3scratch"] as? [String:Any] {
                    runners=(top["runners"] as? [[String:Any]]) ?? [];isTop3=true
                }
                guard !runners.isEmpty else{continue}
                let rows=runners.prefix(30).compactMap { runner -> [String]? in
                    let info=runner["info"] as? [String:Any] ?? [:]
                    guard info["isAnonymous"] as? Bool != true,let name=info["fullname"] as? String else{return nil}
                    let ranking=runner["ranking"] as? [String:Any] ?? [:]
                    let raw=runner["status"] as? String ?? ""
                    let state=["f":"Ziel","d":"DNF","a":"Im Rennen","n":"Nicht gestartet"][raw] ?? raw
                    return [String(describing:ranking["scratch"] ?? "—"),name,info["countryCode"] as? String ?? "—",runner["raceTime"] as? String ?? "—",state]
                }
                let name=race["name"] as? String ?? id
                output += "<h5>\(esc(name)) · \(status=="FINISHED" ? "Endergebnis" : "Live-Zwischenstand")\(isTop3 ? " · veröffentlichte Top 3" : " · erste 30")</h5>"
                output += InlineResults.makeTable(header:["Platz","Athlet*in","Land","Zeit","Status"],rows:rows)
            }
            return output.isEmpty ? nil : output
        } catch{return nil}
    }
}

actor ResultCache {
    private struct Entry:Sendable {let html:String?;let fetched:Date}
    private var cache:[String:Entry]=[:]
    private var loading:[String:Task<String?,Never>]=[:]
    func fetch(_ url:String,year:String?=nil) async -> String? {
        guard InlineResults.allowed(url) else{return nil}
        let key=url+"|"+(year ?? "")
        if let entry=cache[key],Date().timeIntervalSince(entry.fetched)<80{return entry.html}
        if let task=loading[key]{return await task.value}
        let task=Task {await InlineResults.fetch(url,expectedYear:year)}
        loading[key]=task
        let html=await task.value
        loading.removeValue(forKey:key)
        if let html{cache[key]=Entry(html:html,fetched:Date())}
        else if let prior=cache[key],let old=prior.html {
            return "<p class=\"live-notice\">Aktueller Abruf fehlgeschlagen. Letzter erfolgreicher Stand: \(esc(ISO8601DateFormatter().string(from:prior.fetched)))</p>"+old
        }else{cache[key]=Entry(html:nil,fetched:Date())}
        if cache.count>150{cache=cache.filter{Date().timeIntervalSince($0.value.fetched)<3600}}
        return html
    }
}
