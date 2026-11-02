import Foundation
import FoundationNetworking

// No speculative result data. Only documented, publicly reachable data on a
// strict timing-provider allowlist is parsed. No login, anti-bot bypass or API keys.
enum InlineResults {
    static let hosts = TrackingMatcher.providers.map{$0.0} + ["utmb.world", "ultimate.dk"]
    static func allowed(_ raw: String) -> Bool {
        guard let u = URLComponents(string: raw),u.scheme == "https",let h = u.host?.lowercased(),
              u.user == nil,u.password == nil,u.port == nil || u.port == 443 else {return false}
        return hosts.contains {h == $0 || h.hasSuffix("." + $0)}
    }
    static func stripHTML(_ raw:String) -> String {
        var s = raw.replacingOccurrences(of:"(?is)<(script|style|svg)\\b[^>]*>.*?</\\1>",with:" ",options:.regularExpression)
        s = s.replacingOccurrences(of:"<[^>]*>",with:" ",options:.regularExpression)
        for (a,b) in [("&nbsp;"," "),("&amp;","&"),("&lt;","<"),("&gt;",">"),("&quot;","\""),("&#39;","'"),("&ndash;","–")] {s=s.replacingOccurrences(of:a,with:b)}
        return s.replacingOccurrences(of:"\\s+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
    }
    static func matchGroups(_ raw:String,_ pattern:String)->[[String]] {
        guard let regex = try? NSRegularExpression(pattern:pattern,options:[.caseInsensitive,.dotMatchesLineSeparators]) else {return []}
        let ns=raw as NSString
        return regex.matches(in:raw,range:NSRange(location:0,length:ns.length)).map{m in
            (0..<m.numberOfRanges).map{m.range(at:$0).location==NSNotFound ? "" : ns.substring(with:m.range(at:$0))}
        }
    }
    static func parseTable(_ raw:String) -> String? {
        // Genuine results usually contain athlete identifiers and times, not
        // just registration tables. Reject unclear pages instead of guessing.
        for table in matchGroups(raw,#"<table\b[^>]*>.*?</table>"#).prefix(8) {
            let inner=table[0];let rows=matchGroups(inner,#"<tr\b[^>]*>.*?</tr>"#)
            guard rows.count >= 2 else {continue}
            let allHead=stripHTML(rows.prefix(2).map{$0[0]}.joined()).lowercased()
            let hasRank=["rang","rank","place","position","排名","名次","platz"].contains{allHead.contains($0)}
            let hasBib=["bib","startnummer","号码","编号"].contains{allHead.contains($0)}
            let hasRunner=["name","athlete","participant","runner","选手","姓名","运动员"].contains{allHead.contains($0)}
            let hasTime=["zeit","time","finish","成绩","用时","时间","split","pace","chip"].contains{allHead.contains($0)}
            guard (hasRank || hasBib) && hasRunner && hasTime else {continue}
            var validated=[[String]]()
            for row in rows.dropFirst().prefix(101) {
                let cells=matchGroups(row[0],#"<t[dh]\b[^>]*>.*?</t[dh]>"#).map{stripHTML($0[0])}
                guard cells.count>=3 && cells.count<=15 && cells.contains(where:{$0.rangeOfCharacter(from:.decimalDigits) != nil}) else {continue}
                validated.append(cells)
            }
            guard !validated.isEmpty else {continue}
            if !hasRank && !validated.contains(where:{row in row.contains{$0.range(of:#"\b\d{1,3}:\d{2}(?::\d{2})?(?:[.,]\d+)?\b"#,options:.regularExpression) != nil}}) {continue}
            let header=matchGroups(rows[0][0],#"<t[dh]\b[^>]*>.*?</t[dh]>"#).map{stripHTML($0[0])}
            return makeTable(header:header,rows:validated)
        }
        return nil
    }
    static func makeTable(header:[String],rows:[[String]]) -> String {
        let cols=Array(header.prefix(8))
        let headings=cols.isEmpty ? ["Daten"] : cols
        var body="<div class=\"live-inline-scroller\"><table class=\"live-inline-table\"><thead><tr>"
        body += headings.map{"<th>\(esc($0))</th>"}.joined() + "</tr></thead><tbody>"
        for row in rows.prefix(100) {
            body+="<tr>"+row.prefix(headings.count).map{"<td>\(esc($0))</td>"}.joined()+"</tr>"
        }
        return body+"</tbody></table></div>"
    }
    static func parseJSON(_ data:Data) -> String? {
        guard let obj=try? JSONSerialization.jsonObject(with:data),let rows=LiveResults.collectRows(obj) else {return nil}
        if rows.isEmpty {return nil}
        let cols:[[String]]=[["rank","position","place","pos","ranking","排名"],["name","full_name","fullname","athlete","runner","participant","姓名"],["time","elapsed","elapsed_time","finish_time","split_time","成绩"],["status","state","race_status"]]
        let validRows=rows.filter{item in
            let keys=Set(item.keys.map{$0.lowercased()})
            return !keys.isDisjoint(with:Set(cols[1])) && (!keys.isDisjoint(with:Set(cols[0])) || !keys.isDisjoint(with:Set(cols[2])))
        }
        guard !validRows.isEmpty else{return nil}
        let out=validRows.prefix(100).map{item in cols.map{keys in
            for key in keys {if let x=item[key],!(x is NSNull),!(x is [Any]),!(x is [String:Any]) {return String(describing:x)}}
            return "—"
        }}
        return makeTable(header:["Platz","Athlet*in","Zeit / Split","Status"],rows:out)
    }
    final class NoRedirect: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {completionHandler(nil)}
    }
    static func fetch(_ raw:String,expectedYear:String?=nil) async -> String? {
        guard allowed(raw),let url=URL(string:raw) else{return nil}
        if url.host=="live.utmb.world",let table=await ProviderResults.utmb(url){return table}
        do {
            let page=try await PublicHTTP.fetch(raw,trusted:true)
            let data=page.data
            guard page.status==200 else{return nil}
            let mime=page.contentType.lowercased()
            if let year=expectedYear,!year.isEmpty,!raw.contains(year) {
                let html=String(decoding:data,as:UTF8.self)
                let headings=matchGroups(html,#"<(?:title|h1|h2)\b[^>]*>(.*?)</(?:title|h1|h2)>"#).map{stripHTML($0[1])}.joined(separator:" ")
                guard headings.contains(year) else{return nil}
            }
            if mime.contains("json") || raw.contains(".json") {return parseJSON(data)}
            guard mime.isEmpty || mime.contains("html") else{return nil}
            return parseTable(String(decoding:data,as:UTF8.self))
        } catch {return nil}
    }
}

// A deliberately narrow screenshot fallback: a time-limited snapshot of a
// publicly visible official timing page. Never claim it is extracted ranking
// data. No arbitrary URL or authentication is accepted.
actor LiveScreenshots {
    let folder:URL
    private var last:[String:Date]=[:]
    init(directory:String) {
        folder=URL(fileURLWithPath:directory,isDirectory:true).appendingPathComponent("public-live-screens")
        try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    }
    func shot(raceID:String,url:String) -> Data? {
        guard ProcessInfo.processInfo.environment["ENABLE_LIVE_SNAPSHOTS"] == "1",
              InlineResults.allowed(url),
              raceID.range(of:#"^[A-Za-z0-9_-]{1,80}$"#,options:.regularExpression) != nil else {return nil}
        let bin=ProcessInfo.processInfo.environment["CHROMIUM_BIN"] ?? "/usr/bin/chromium"
        guard FileManager.default.isExecutableFile(atPath:bin) else{return nil}
        let dest=folder.appendingPathComponent(raceID+".png")
        let now=Date()
        let expired=last[raceID].map{now.timeIntervalSince($0)>90} ?? true
        if expired {
            last[raceID]=now
            let temp=folder.appendingPathComponent(raceID+".new.png")
            let proc=Process();proc.executableURL=URL(fileURLWithPath:bin)
            proc.arguments=["--headless","--no-sandbox","--disable-gpu","--disable-dev-shm-usage","--no-first-run","--disable-extensions","--hide-scrollbars","--window-size=1280,1000","--virtual-time-budget=5000","--screenshot=\(temp.path)",url]
            proc.standardOutput=Pipe();proc.standardError=Pipe()
            // Snapshot only the public page; never submit credentials or defeat
            // paywalls. This synchronous capture is confined to the image route.
            if (try? proc.run()) != nil {
                proc.waitUntilExit()
                if let dat=try? Data(contentsOf:temp),dat.count>3000,dat.starts(with:[137,80,78,71,13,10,26,10]) {
                    try? FileManager.default.removeItem(at:dest)
                    try? FileManager.default.moveItem(at:temp,to:dest)
                } else {try? FileManager.default.removeItem(at:temp)}
            }
        }
        return try? Data(contentsOf:dest)
    }
}
