import Foundation
import FoundationNetworking

// Automatically locate event-specific, HTTPS tracking/results pages. Verified
// editorial seeds are kept distinct from results of the background search.
// Searching can fail (network / RSS changes). Fail closed: no invented links.
struct TrackingLink: Codable, Sendable, Equatable {
    let raceID: String
    let url: String
    let provider: String
    let evidence: String
    let verifiedOn: String
}
// A successful search and a reachable link are two separate facts. Keep both
// across restarts so failures never silently remove an existing tracking link.
struct TrackingVerification: Codable, Sendable, Equatable {
    var checkedAt: String = ""
    var status: String = "noch_ungeprueft" // erreichbar / nicht_gefunden / blockiert / ungeprueft
    var failedChecks: Int = 0
    var httpStatus: Int? = nil
}
struct TrackingState: Codable, Sendable {
    var links: [String: TrackingLink] = [:]
    var checked: [String: String] = [:] // last discovery search per race
    var verification: [String: TrackingVerification] = [:]
    var lastAttempt: String = ""
    var lastError: String = ""

    // Migrate older tracking-discovery.json state without discarding found links.
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        links = try c.decodeIfPresent([String:TrackingLink].self, forKey:.links) ?? [:]
        checked = try c.decodeIfPresent([String:String].self, forKey:.checked) ?? [:]
        verification = try c.decodeIfPresent([String:TrackingVerification].self, forKey:.verification) ?? [:]
        lastAttempt = try c.decodeIfPresent(String.self, forKey:.lastAttempt) ?? ""
        lastError = try c.decodeIfPresent(String.self, forKey:.lastError) ?? ""
    }
}
struct TrackingSnapshot: Sendable {
    let links: [String: TrackingLink]
    let verification: [String: TrackingVerification]
    let checkedCount: Int
    let lastAttempt: String
    let lastError: String
    let running: Bool
}

enum TrackingMatcher {
    // Explicit provider-only allowlist: never treat an arbitrary search result,
    // advertising page, or old event as a confirmed race tracker.
    static let providers: [(String,String)] = [
        ("live.utmb.world", "UTMB Live"),
        ("livetrail.net", "LiveTrail"),
        ("raceresult.com", "RACE RESULT"),
        ("live.ultimate.dk", "UltimateLIVE"),
        ("live.aravaiparunning.com", "Aravaipa Live"),
        ("aravaiparunning.com", "Aravaipa Running"),
        ("rtrt.me", "RTRT.me"),
        ("trackleaders.com", "Trackleaders"),
        ("werun.hk", "WeRun"),
        ("gusto.cn", "GUSTO / 第一赛道"),
        ("zuicool.com", "ZUICOOL / 最酷"),
        ("saihuitong.com", "赛会通"),
        ("chipskill.com", "ChipSkill / 成绩查询"),
        ("sportmaniacs.com", "Sportmaniacs"),
        ("racetek-live.co.uk", "RaceTek"),
        ("racetek-live.com", "RaceTek"),
        ("results.xterraplanet.com", "XTERRA Results")
    ]
    static func provider(_ url: String) -> String? {
        guard let u = URLComponents(string: url),u.scheme == "https",
              let host=u.host?.lowercased(),u.user == nil,u.password == nil,
              u.port == nil || u.port == 443 else { return nil }
        return providers.first { host == $0.0 || host.hasSuffix("."+$0.0) }?.1
    }
    static func normalize(_ s: String) -> String {
        let plain = s.folding(options: [.caseInsensitive,.diacriticInsensitive],locale: Locale(identifier:"en_US_POSIX")).lowercased()
        return plain.replacingOccurrences(of:"[^\\p{L}\\p{N}]+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
    }
    static let common = Set(["ultra","trail","the","race","run","marathon","by","world","series","sky","skyrace","running","festival","of","de","des","der","la","le","and","international","100","50","2026","2027"])
    static func tokens(_ name:String) -> [String] {
        Array(Set(normalize(name).split(separator:" ").map(String.init).filter { $0.count >= 3 && !common.contains($0) })).sorted()
    }
    static func xmlText(_ raw:String) -> String {
        raw.replacingOccurrences(of:"<![CDATA[",with:"")
          .replacingOccurrences(of:"]]>",with:"")
          .replacingOccurrences(of:"&amp;",with:"&")
          .replacingOccurrences(of:"&quot;",with:"\"")
          .replacingOccurrences(of:"&#39;",with:"'")
          .replacingOccurrences(of:"&lt;",with:"<")
          .replacingOccurrences(of:"&gt;",with:">")
    }
    // Small, standalone RSS parser. No remote dependency, no browser JS.
    static func matchesRSS(_ xml:String,race:Race) -> TrackingLink? {
        let year=race.year.isEmpty ? String(dateOnly().prefix(4)) : race.year
        guard !year.isEmpty else {return nil}
        let nameTokens=tokens(race.name)
        guard !nameTokens.isEmpty else{return nil}
        let items=xml.matches(pattern:#"(?is)<item\b[^>]*>(.*?)</item>"#)
        var candidates:[(Int,TrackingLink)] = []
        for item in items.prefix(30) {
            func field(_ tag:String)->String {
                guard let group=item.matches(pattern:"(?is)<"+tag+"(?:\\s[^>]*)?>(.*?)</"+tag+">").first else {return ""}
                return xmlText(group.replacingOccurrences(of:"<[^>]+>",with:" ",options:.regularExpression))
                    .trimmingCharacters(in:.whitespacesAndNewlines)
            }
            let title=field("title"),link=field("link"),desc=field("description")
            guard let provider=provider(link),let u=URLComponents(string:link),
                  let path=u.path.removingPercentEncoding,
                  !path.isEmpty && path != "/" else {continue}
            let titleWords=Set(normalize(title).split(separator:" ").map(String.init))
            let urlWords=Set(normalize(path).split(separator:" ").map(String.init))
            let needed=nameTokens.count==1 ? 1 : max(2, Int(ceil(Double(nameTokens.count)*0.65)))
            let alias=TrackingDiscovery.chineseAliases[race.id].map{normalize(title+" "+path).contains(normalize($0))} ?? false
            let matched=alias ? needed : nameTokens.filter{titleWords.contains($0)||urlWords.contains($0)}.count
            guard matched>=needed else {continue}
            // The correct edition is essential: do not offer a 2025 ranking as 2026 live tracking.
            let yearInTitle=title.contains(year),yearInURL=path.contains(year)
            guard yearInTitle || yearInURL else {continue}
            let contradictingYear=(2020...2031).map(String.init).filter{$0 != year}
                .contains{other in (title.contains(other) || path.contains(other))}
            if contradictingYear {continue}
            let lowerTitle=title.lowercased(),lowerPath=path.lowercased()
            guard ["live","tracking","results","ergebnis","rankings","leaderboard","timing","成绩","直播","实时","名次","排名","计时"].contains(where:{lowerTitle.contains($0)||lowerPath.contains($0)}) || provider=="UTMB Live" else {continue}
            let score=matched*10 + (yearInURL ? 8 : 0) + (titleWords.isSuperset(of: Set(nameTokens)) ? 5 : 0)
            let found=TrackingLink(raceID:race.id,url:link,provider:provider,evidence:"Automatischer Treffer: \(title.prefix(150))",verifiedOn:dateOnly())
            candidates.append((score,found))
            _ = desc
        }
        return candidates.sorted{$0.0>$1.0}.first?.1
    }
}

private extension String {
    func matches(pattern:String) -> [String] {
        guard let re=try? NSRegularExpression(pattern:pattern,options:[]),
              let range=Range(NSRange(location:0,length:(self as NSString).length),in:self) else {return []}
        return re.matches(in:self,range:NSRange(range,in:self)).compactMap { m in
            let target=m.numberOfRanges>1 ? m.range(at:1) : m.range
            guard let r=Range(target,in:self) else {return nil}
            return String(self[r])
        }
    }
}

actor TrackingDiscovery {
    private var state: TrackingState
    private let file: URL
    private var races: [Race]
    private let seedIDs: Set<String>
    private var scanning = false
    private var directoryHTML:String=""
    private var directoryChecked:Date?
    // Same 96-minute rhythm as the date radar: 15 checks per 24 hours, while
    // the hosting service is awake. Not a promise of 15 checks on sleeping hosts.
    static let scanInterval: TimeInterval = 96 * 60
    init(races:[Race], seeds:[TrackingLink], directory:String) {
        self.races = races
        seedIDs = Set(seeds.map(\.raceID))
        let dir=URL(fileURLWithPath:directory,isDirectory:true)
        try? FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        file=dir.appendingPathComponent("tracking-discovery.json")
        state=(try? Data(contentsOf:file)).flatMap{try? JSONDecoder().decode(TrackingState.self,from:$0)} ?? TrackingState()
        let ids=Set(races.map(\.id))
        for seed in seeds where ids.contains(seed.raceID) && URL(string:seed.url)?.scheme == "https" {
            // Preserve a previously updated URL after a restart; seeds initialise
            // only genuinely empty records.
            if state.links[seed.raceID] == nil {state.links[seed.raceID] = seed}
        }
    }
    func snapshot()->TrackingSnapshot {
        TrackingSnapshot(links:state.links,verification:state.verification,checkedCount:state.checked.count,lastAttempt:state.lastAttempt,lastError:state.lastError,running:scanning)
    }
    func updateRaces(_ updated:[Race]) {races=updated}
    func ingest(_ data:Data) {
        guard let remote=try? JSONDecoder().decode(TrackingState.self,from:data) else{return}
        for (id,link) in remote.links where (state.checked[id] ?? "") <= (remote.checked[id] ?? "") {
            state.links[id]=link
            state.checked[id]=remote.checked[id]
            if let verification=remote.verification[id]{state.verification[id]=verification}
        }
        for (id,checked) in remote.checked where (state.checked[id] ?? "") < checked{state.checked[id]=checked}
        if remote.lastAttempt>state.lastAttempt{state.lastAttempt=remote.lastAttempt;state.lastError=remote.lastError}
        save()
    }
    func exportPublic(to path:URL) throws {
        let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
        try encoder.encode(state).write(to:path,options:.atomic)
    }
    private func save() {
        if let data=try? JSONEncoder().encode(state){try? data.write(to:file,options:.atomic)}
    }
    private func elapsed(_ stamp:String,now:Date) -> TimeInterval {
        guard let date=ISO8601DateFormatter().date(from:stamp) else{return .infinity}
        return now.timeIntervalSince(date)
    }
    private func upcoming(_ race:Race,now:String) -> Bool {
        guard !race.start.isEmpty else{return false}
        let day=Calendar(identifier:.gregorian).date(byAdding:.day,value:21,to:Date()).map{dateOnly($0)} ?? now
        return race.start>=now && race.start<=day || race.start<=now && (race.end ?? race.start)>=now
    }
    private func rssURL(for race:Race)->URL? {
        var c=URLComponents(string:"https://www.bing.com/search")!
        let words=race.countryName == "China" ? "越野跑 实时成绩 成绩查询 直播" : "live tracking results classement resultados"
        let alias=Self.chineseAliases[race.id] ?? race.name
        let year=race.year.isEmpty ? String(dateOnly().prefix(4)) : race.year
        c.queryItems=[URLQueryItem(name:"format",value:"rss"), URLQueryItem(name:"q",value:"\"\(alias)\" \(year) \(words)")]
        return c.url
    }
    private func lookup(_ race:Race) async -> (TrackingLink?,String?) {
        if let official=await officialLink(race){return (official,nil)}
        if ["China","Hongkong","Taiwan"].contains(race.countryName),let direct=await directoryLink(race){return (direct,nil)}
        guard let url=rssURL(for:race) else{return (nil,"Ungültige Suchanfrage")}
        do {
            let page=try await PublicHTTP.fetch(url.absoluteString,trusted:true,maxBytes:500_000)
            guard page.status==200 else{return (nil,"Suche nicht erreichbar")}
            let xml=String(decoding:page.data,as:UTF8.self)
            guard xml.lowercased().contains("<rss") || xml.lowercased().contains("<item") else{return (nil,"Suchdienst lieferte kein RSS")}
            if let match=TrackingMatcher.matchesRSS(xml,race:race){return (match,nil)}
            return (nil,"Keine eindeutige Quelle für diese Rennausgabe im öffentlichen Suchindex gefunden")
        } catch{return (nil,"Suchdienst zurzeit nicht erreichbar")}
    }
    static let chineseAliases:[String:String]=[
        "old-0193":"连云港168越野赛", "old-0199":"玉龙雪山超级越野赛", "old-0202":"环四姑娘山超级越野赛",
        "old-0208":"阳羡100越野挑战赛",
        "old-0212":"可隆宁海越野挑战赛", "old-0242":"广州100越野赛", "old-0282":"崇礼168超级越野赛",
        "old-0291":"贡嘎100越野赛", "old-0324":"深圳100越野赛", "old-0336":"柴古唐斯越野赛",
        "old-0300":"九寨沟100越野赛", "old-0341":"武功山越野赛"
    ]
    private func directoryLink(_ race:Race) async -> TrackingLink? {
        if directoryChecked.map({Date().timeIntervalSince($0)>300}) ?? true {
            directoryChecked=Date()
            if let page=try? await PublicHTTP.fetch("https://werun.hk/game",trusted:true),page.status==200 {
                directoryHTML=String(decoding:page.data,as:UTF8.self)
            }
        }
        let items=InlineResults.matchGroups(directoryHTML,#"<a\b[^>]*href\s*=\s*["']([^"']+)["'][^>]*>(.*?)</a>"#).compactMap { anchor -> String? in
            guard let url=URL(string:TrackingMatcher.xmlText(anchor[1]),relativeTo:URL(string:"https://werun.hk/game"))?.absoluteURL,
                  url.path.hasPrefix("/game/"),TrackingMatcher.provider(url.absoluteString)=="WeRun" else{return nil}
            let title=InlineResults.stripHTML(anchor[2])
            return "<item><title>\(esc(title)) · Results 成绩</title><link>\(esc(url.absoluteString))</link></item>"
        }.joined()
        guard let found=TrackingMatcher.matchesRSS("<rss><channel>"+items+"</channel></rss>",race:race) else{return nil}
        return TrackingLink(raceID:found.raceID,url:found.url,provider:found.provider,evidence:"Direkt aus dem öffentlichen WeRun-Ergebnisverzeichnis; Rennname und Ausgabe stimmen überein",verifiedOn:dateOnly())
    }
    private func officialLink(_ race:Race) async -> TrackingLink? {
        guard PublicHTTP.validURL(race.sourceURL) != nil,
              let page=try? await PublicHTTP.fetch(race.sourceURL,trusted:true),page.status==200 else{return nil}
        let html=String(decoding:page.data,as:UTF8.self)
        let year=race.year.isEmpty ? String(dateOnly().prefix(4)) : race.year
        let title=InlineResults.matchGroups(html,#"<title[^>]*>(.*?)</title>"#).first.map{$0[1]} ?? ""
        let body=TrackingMatcher.normalize(title+" "+String(InlineResults.stripHTML(html).prefix(3000)))
        let tokens=TrackingMatcher.tokens(race.name)
        guard tokens.filter({body.contains($0)}).count>=max(1,min(2,tokens.count)) else{return nil}
        for anchor in InlineResults.matchGroups(html,#"<a\b[^>]*href\s*=\s*["']([^"']+)["'][^>]*>(.*?)</a>"#) {
            let raw=TrackingMatcher.xmlText(anchor[1])
            guard let url=URL(string:raw,relativeTo:URL(string:page.url))?.absoluteURL,
                  let provider=TrackingMatcher.provider(url.absoluteString),
                  url.path != "/",(url.path+"?"+(url.query ?? "")).contains(year) else{continue}
            return TrackingLink(raceID:race.id,url:url.absoluteString,provider:provider,evidence:"Direkt auf Veranstalterseite verlinkt: \(InlineResults.stripHTML(anchor[2]).prefix(100)) · \(year)",verifiedOn:dateOnly())
        }
        return nil
    }
    // Check only the address itself: following a redirect to an arbitrary URL
    // could expose the server to untrusted hosts. HEAD first avoids big bodies.
    // 403/429 and intermittent errors NEVER prove a link is gone.
    private func checkLink(_ raw:String,year:String="") async -> (String,Int?) {
        guard InlineResults.allowed(raw) else{return ("ungeprueft",nil)}
        do {
            let page=try await PublicHTTP.fetch(raw,trusted:true)
            if (200..<300).contains(page.status){
                if !year.isEmpty,!raw.contains(year) {
                    let html=String(decoding:page.data,as:UTF8.self)
                    let heading=InlineResults.matchGroups(html,#"<(?:title|h1|h2)\b[^>]*>(.*?)</(?:title|h1|h2)>"#).prefix(5).map{InlineResults.stripHTML($0[1])}.joined(separator:" ")
                    let editions=InlineResults.matchGroups(heading,#"\b(20\d{2})\b"#).map{$0[1]}
                    if !editions.isEmpty && !editions.contains(year){return ("andere_ausgabe",page.status)}
                }
                return ("erreichbar",page.status)
            }
            if [404,410].contains(page.status){return ("nicht_gefunden",page.status)}
            if [401,403,429].contains(page.status){return ("blockiert",page.status)}
            return ("ungeprueft",page.status)
        } catch {return ("ungeprueft",nil)}
    }
    // Explicit selection can request immediate work for one event, but regular
    // visits only run checks when due and don't fetch all 352 at once.
    func discoverIfDue(priorityID:String?=nil,force:Bool=false) async {
        guard !scanning else{return}
        if priorityID==nil && !force && elapsed(state.lastAttempt,now:Date())<Self.scanInterval{return}
        if force,let id=priorityID,let checked=state.checked[id],elapsed(checked,now:Date())<60{return}
        scanning=true
        defer{scanning=false;save()}
        let now=Date(),today=dateOnly(now)
        let ids=Set(races.map(\.id))
        let priority=priorityID.flatMap{ids.contains($0) ? $0 : nil}
        func rank(_ r:Race) -> (Int,String) {
            if r.id==priority {return (-1,"")}
            if upcoming(r,now:today) {return (0,r.start)}
            if !r.start.isEmpty && r.start>today {return (1,r.start)}
            return (2,r.start.isEmpty ? "9999":r.start)
        }
        let ordered=races.sorted { a,b in
            let x=rank(a),y=rank(b)
            return x.0 == y.0 ? x.1 < y.1 : x.0 < y.0
        }
        let linkDue:[Race]=ordered.filter { race in
            guard state.links[race.id] != nil else{return false}
            let recent=upcoming(race,now:today)
            let interval:TimeInterval=recent ? Self.scanInterval : 24*60*60
            return (force && race.id==priority) || elapsed(state.verification[race.id]?.checkedAt ?? "",now:now)>=interval
        }
        let discoveryDue:[Race]=ordered.filter { race in
            let recent=upcoming(race,now:today)
            let missingTwice=(state.verification[race.id]?.failedChecks ?? 0) >= 2
            let interval:TimeInterval = missingTwice || recent ? Self.scanInterval : (state.links[race.id] == nil ? 24*60*60 : 7*24*60*60)
            return (force && race.id==priority) || elapsed(state.checked[race.id] ?? "",now:now)>=interval
        }.sorted { a,b in
            let x=state.checked[a.id] ?? "",y=state.checked[b.id] ?? ""
            if x != y{return x<y}
            let ar=rank(a),br=rank(b)
            return ar.0==br.0 ? ar.1<br.1 : ar.0<br.0
        }
        // Alternate known links and new candidates: existing links must not
        // exclude the rest of the international calendar from being searched.
        let budget=priority == nil ? 12 : 1
        var chosen:[(Race,Bool)]=[]
        if let priority,let r=ordered.first(where:{$0.id==priority}),
           force || linkDue.contains(where:{$0.id==priority}) || discoveryDue.contains(where:{$0.id==priority}) {
            chosen.append((r,state.links[priority] != nil))
        }
        var seen=Set(chosen.map{$0.0.id})
        var known=linkDue.makeIterator(),fresh=discoveryDue.makeIterator()
        var takeKnown=true
        while chosen.count<budget {
            let next=takeKnown ? known.next() : fresh.next()
            takeKnown.toggle()
            let fallback=next == nil ? (takeKnown ? known.next() : fresh.next()) : nil
            guard let r=next ?? fallback else{break}
            if seen.insert(r.id).inserted {chosen.append((r,state.links[r.id] != nil))}
        }
        // A race with an existing link may also need a *new* search; do that
        // after its availability check when its discovery search is due.
        guard !chosen.isEmpty else{return}
        state.lastError=""
        for (race,hasLink) in chosen {
            if hasLink,let link=state.links[race.id] {
                let (status,code)=await checkLink(link.url,year:race.year)
                var record=state.verification[race.id] ?? TrackingVerification()
                record.checkedAt=ISO8601DateFormatter().string(from:Date())
                record.status=status
                record.httpStatus=code
                record.failedChecks=status=="andere_ausgabe" ? 2 : status=="nicht_gefunden" ? record.failedChecks+1 : 0
                state.verification[race.id]=record
            }
            let shouldSearch=force && race.id==priority || discoveryDue.contains(where:{$0.id==race.id})
            if shouldSearch {
                let (found,error)=await lookup(race)
                state.checked[race.id]=ISO8601DateFormatter().string(from:Date())
                if let found {
                    let previous=state.links[race.id]
                    // Keep a known healthy/verified page over an unverified search
                    // match. Replace only when the original is repeatedly 404/410,
                    // or the match is the same canonical URL.
                    let bad=state.verification[race.id]?.failedChecks ?? 0
                    let replaceDiscovered = !seedIDs.contains(race.id) && previous?.provider == found.provider
                    if previous == nil || previous?.url == found.url || bad>=2 || replaceDiscovered {
                        if previous?.url != found.url {state.verification.removeValue(forKey:race.id)}
                        state.links[race.id]=found
                    }
                }
                if let error {state.lastError=error}
            }
            save()
        }
        state.lastAttempt=ISO8601DateFormatter().string(from:Date())
    }
}
