import Foundation
import FoundationNetworking

struct Race: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let dateLabel: String
    let start: String
    let end: String?
    let country: String
    let isoCountry: String
    let distance: String
    let category: String
    let status: String
    let eliteVerified: Bool
    let details: String
    let sourceURL: String
    let origin: String

    enum CodingKeys: String, CodingKey {
        case id, name, start, end, country, distance, category, status, details, origin
        case dateLabel = "date_label", isoCountry = "iso_country", eliteVerified = "elite_verified", sourceURL = "source_url"
    }
    var year: String { start.count >= 4 ? String(start.prefix(4)) : "" }
    var month: Int { start.count >= 7 ? Int(start.dropFirst(5).prefix(2)) ?? 0 : 0 }
    var countryName: String { Self.countries[country] ?? (country.isEmpty ? "International" : country) }
    var countryCode:String {
        if isoCountry.count==2{return isoCountry}
        let scalars=country.unicodeScalars.map{$0.value}
        guard scalars.count==2,scalars.allSatisfy({(0x1F1E6...0x1F1FF).contains($0)}) else{return ""}
        return scalars.compactMap{UnicodeScalar($0-0x1F1E6+65).map{String($0)}}.joined()
    }
    static func flag(_ code:String)->String {
        guard code.count==2,code.unicodeScalars.allSatisfy({(65...90).contains($0.value)}) else{return ""}
        return code.unicodeScalars.compactMap{UnicodeScalar($0.value+0x1F1E6-65).map{String($0)}}.joined()
    }
    var searchText: String { "\(name) \(countryName) \(distance) \(status) \(details)".folded }
    var distancesKM:[Double] {
        let text=distance as NSString
        // A shared suffix applies to every slash-separated course: 10 / 30 / 50 km.
        // Lowercase m denotes elevation/metres; uppercase M is the usual mile shorthand.
        let pattern = #"((?:\d+(?:[.,]\d+)?\+?\s*[/–-]\s*)*\d+(?:[.,]\d+)?\+?)\s*(kilometers?|kilometres?|kilometer|km|miles?|meilen|mi|k|m)(?![a-zäöü])"#
        let matches=(try? NSRegularExpression(pattern:pattern,options:.caseInsensitive))?.matches(in:distance,range:NSRange(location:0,length:text.length)) ?? []
        var values:[Double]=[]
        for match in matches {
            let rawUnit=text.substring(with:match.range(at:2)),unit=rawUnit.lowercased()
            if unit=="m" && rawUnit != "M"{continue}
            let series=text.substring(with:match.range(at:1))
            let numbers=InlineResults.matchGroups(series,#"\d+(?:[.,]\d+)?"#).map{$0[0]}
            for number in numbers {
                guard var km=Double(number.replacingOccurrences(of:",",with:".")),km>0 else{continue}
                if ["mi","mile","miles","meilen","m"].contains(unit){km *= 1.609344}
                if km<=5000{values.append(km)}
            }
        }
        let lower=distance.lowercased()
        if lower.contains("half marathon") || lower.contains("halbmarathon"){values.append(21.0975)}
        let withoutHalf=lower.replacingOccurrences(of:"half marathon",with:"").replacingOccurrences(of:"halbmarathon",with:"")
        if withoutHalf.contains("marathon"){values.append(42.195)}
        return Array(Set(values)).sorted()
    }
    static let countries: [String: String] = [
        "🇦🇲":"Armenien", "🇦🇶":"Antarktis", "🇧🇹":"Bhutan", "🇨🇷":"Costa Rica", "🇪🇹":"Äthiopien", "🇰🇬":"Kirgisistan", "🇱🇦":"Laos", "🇲🇪":"Montenegro", "🇲🇲":"Myanmar", "🇲🇳":"Mongolei", "🇳🇦":"Namibia", "🇷🇪":"Réunion", "🇷🇸":"Serbien", "🇷🇼":"Ruanda", "🇸🇬":"Singapur", "🇸🇹":"São Tomé und Príncipe", "🇹🇯":"Tadschikistan", "🇹🇿":"Tansania", "🇺🇿":"Usbekistan", "🌍":"International",
        "🇩🇪":"Deutschland", "🇦🇹":"Österreich", "🇨🇭":"Schweiz", "🇮🇹":"Italien", "🇫🇷":"Frankreich", "🇪🇸":"Spanien", "🇵🇹":"Portugal", "🇬🇧":"Großbritannien", "🇺🇸":"USA", "🇨🇳":"China", "🇯🇵":"Japan", "🇰🇷":"Südkorea", "🇳🇵":"Nepal", "🇮🇳":"Indien", "🇹🇭":"Thailand", "🇹🇼":"Taiwan", "🇳🇿":"Neuseeland", "🇦🇺":"Australien", "🇨🇦":"Kanada", "🇷🇺":"Russland", "🇵🇱":"Polen", "🇸🇪":"Schweden", "🇳🇴":"Norwegen", "🇫🇮":"Finnland", "🇹🇷":"Türkei", "🇧🇷":"Brasilien", "🇲🇽":"Mexiko", "🇦🇷":"Argentinien", "🇿🇦":"Südafrika", "🇬🇷":"Griechenland", "🇸🇮":"Slowenien", "🇭🇷":"Kroatien", "🇨🇿":"Tschechien", "🇷🇴":"Rumänien", "🇮🇩":"Indonesien", "🇻🇳":"Vietnam", "🇲🇦":"Marokko", "🇨🇱":"Chile", "🇵🇪":"Peru", "🇭🇰":"Hongkong", "🇸🇰":"Slowakei", "🇮🇸":"Island", "🇧🇪":"Belgien", "🇳🇱":"Niederlande", "🇧🇬":"Bulgarien", "🇦🇩":"Andorra", "🇵🇭":"Philippinen", "🇦🇪":"VAE", "🇸🇦":"Saudi-Arabien", "🇺🇦":"Ukraine", "🇪🇨":"Ecuador", "🇨🇴":"Kolumbien", "🇲🇾":"Malaysia", "🇬🇪":"Georgien", "🇭🇺":"Ungarn", "🇮🇪":"Irland", "🇲🇰":"Nordmazedonien", "🇰🇪":"Kenia"
    ]
}

struct RaceSource: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let country: String
    let url: String
}
struct Finding: Codable, Sendable, Identifiable {
    let id: String
    let sourceID: String
    let sourceName: String
    let sourceURL: String
    let start: String
    let evidence: String
    let inspectedAt: String
    var end: String? = nil
    var confidence: String? = nil
    var ownerID: String? = nil
}
struct SourceCheck: Codable, Sendable {
    let name: String
    let message: String
    let checkedAt: String
    var ownerID: String? = nil
}
struct Session: Codable, Sendable {
    var favorites: [String] = []
    var liveLinks: [String: String] = [:]
    var approved: [String: String] = [:]
    var ignored: [String] = []
    var customSources: [RaceSource] = []
    var dateOverrides: [String:DateUpdate]? = nil
}
struct Persisted: Codable, Sendable {
    var sessions: [String: Session] = [:]
    var findings: [Finding] = []
    var checks: [SourceCheck] = []
    var lastScan: String = ""
    var automaticDates: [String:DateUpdate] = [:]
    var sourceCursor: Int = 0
    init() {}
    init(from decoder:Decoder) throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        sessions=try c.decodeIfPresent([String:Session].self,forKey:.sessions) ?? [:]
        findings=try c.decodeIfPresent([Finding].self,forKey:.findings) ?? []
        checks=try c.decodeIfPresent([SourceCheck].self,forKey:.checks) ?? []
        lastScan=try c.decodeIfPresent(String.self,forKey:.lastScan) ?? ""
        automaticDates=try c.decodeIfPresent([String:DateUpdate].self,forKey:.automaticDates) ?? [:]
        sourceCursor=try c.decodeIfPresent(Int.self,forKey:.sourceCursor) ?? 0
    }
}
struct Snapshot: Sendable {
    let session: Session
    let findings: [Finding]
    let checks: [SourceCheck]
    let lastScan: String
    let isScanning: Bool
    let sources: [RaceSource]
    var automaticDates: [String:DateUpdate] = [:]
}

extension String {
    var folded: String { folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE")).lowercased() }
}

func esc(_ text: String) -> String {
    var output = text
    for (a, b) in [("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"), ("'", "&#39;")] { output = output.replacingOccurrences(of: a, with: b) }
    return output
}
func encoded(_ s: String) -> String {
    var parts = URLComponents()
    parts.queryItems = [URLQueryItem(name: "x", value: s)]
    return (parts.percentEncodedQuery ?? "x=").replacingOccurrences(of: "x=", with: "")
}
func dateOnly(_ date: Date = Date()) -> String {
    let df = DateFormatter(); df.calendar = Calendar(identifier: .gregorian); df.timeZone = TimeZone(identifier: "Europe/Berlin"); df.dateFormat = "yyyy-MM-dd"
    return df.string(from: date)
}
func germanDate(_ iso: String) -> String {
    guard iso.count == 10 else { return "Termin noch nicht bekannt" }
    let df = DateFormatter();df.calendar = Calendar(identifier:.gregorian);df.timeZone = TimeZone(secondsFromGMT:0);df.dateFormat="yyyy-MM-dd"
    guard let d = df.date(from: iso) else {return iso}
    df.locale=Locale(identifier:"de_DE");df.dateFormat="d. MMMM yyyy"
    return df.string(from:d)
}
let shortMonths = ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]
let longMonths = ["Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember"]
func nextWeekend() -> (String,String) {
    let z=TimeZone(identifier:"Europe/Berlin")!; var c=Calendar(identifier:.gregorian);c.timeZone=z;c.firstWeekday=2
    let now=Date();let wd=c.component(.weekday,from:now);let untilSaturday=(7-wd+7)%7
    let start=c.date(byAdding:.day,value:untilSaturday,to:c.startOfDay(for:now))!;
    let end=c.date(byAdding:.day,value:1,to:start)!
    return (dateOnly(start),dateOnly(end))
}

struct Filters: Sendable {
    var q="", country="", distance="all", year="all", month=0, sort="date-asc", view="list", section="calendar", detail="", liveRace=""
    var elite=false, series=false, tba=false, upcoming=false, favs=false, weekendAll=false
    var minKm:Double?,maxKm:Double?
    var page=1
    var params: [String: String] {
        var p:[String:String]=[:]
        if !q.isEmpty {p["q"]=q};if !country.isEmpty{p["country"]=country}
        if distance != "all"{p["distance"]=distance};if year != "all"{p["year"]=year}
        if month>0{p["month"]=String(month)};if sort != "date-asc"{p["sort"]=sort}
        if view != "list"{p["view"]=view};if section != "calendar"{p["section"]=section}
        if elite{p["elite"]="1"};if series{p["series"]="1"};if tba{p["tba"]="1"}
        if upcoming{p["upcoming"]="1"};if favs{p["favs"]="1"}
        if let m=minKm{p["minKm"]=String(m)};if let m=maxKm{p["maxKm"]=String(m)}
        if page>1{p["page"]=String(page)}
        if weekendAll{p["weekendAll"]="1"}
        if !liveRace.isEmpty{p["race"]=liveRace}
        if !detail.isEmpty{p["detail"]=detail}
        return p
    }
    func link(_ changes: [String:String?] = [:], fragment: String = "") -> String {
        var p=params
        for (k,v) in changes{if let v=v{p[k]=v}else{p.removeValue(forKey:k)}}
        var c=URLComponents();c.path="/";c.queryItems=p.sorted{$0.key<$1.key}.map{URLQueryItem(name:$0.key,value:$0.value)}
        return (c.string ?? "/")+fragment
    }
    func matches(_ r: Race, favorites: Set<String>) -> Bool {
        if !q.isEmpty && !r.searchText.contains(q.folded){return false}
        if !country.isEmpty && r.countryName != country{return false}
        if year != "all" && r.year != year{return false}
        if month>0 && r.month != month{return false}
        if elite && r.category != "elite" && r.category != "series"{return false}
        if series && r.category != "series"{return false}
        if tba && !r.start.isEmpty{return false}
        if upcoming && (r.start.isEmpty || (r.end ?? r.start) < dateOnly()){return false}
        if favs && !favorites.contains(r.id){return false}
        let ds=r.distancesKM
        if minKm != nil || maxKm != nil {
            if !ds.contains(where:{d in (minKm == nil || d >= minKm!) && (maxKm == nil || d <= maxKm!)}){return false}
        }
        switch distance {
        case "short": if !ds.contains(where:{$0>=10 && $0<20}){return false}
        case "medium": if !ds.contains(where:{$0>=20 && $0<35}){return false}
        case "long": if !ds.contains(where:{$0>=35}){return false}
        default: break
        }
        return true
    }
}

actor TrailStore {
    private var state=Persisted()
    private var running=false
    private var cancel=false
    private var scanOwner:String?
    let file:URL
    let sources:[RaceSource]
    let races:[Race]
    init(directory:String,sources:[RaceSource],races:[Race]=[]) {
        self.races=races
        var combined=sources
        var urls=Set(sources.map(\.url))
        for race in races where PublicHTTP.validURL(race.sourceURL) != nil && urls.insert(race.sourceURL).inserted {
            combined.append(RaceSource(id:"race-"+race.id,name:race.name,country:race.countryCode,url:race.sourceURL))
        }
        self.sources=combined
        let dir=URL(fileURLWithPath:directory,isDirectory:true)
        try? FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        file=dir.appendingPathComponent("state.json")
        if let data=try? Data(contentsOf:file),let s=try? JSONDecoder().decode(Persisted.self,from:data){state=s}
    }
    private func save() {
        do {try JSONEncoder().encode(state).write(to:file,options:.atomic)}
        catch {print("TrailAtlas: local cache could not be saved")}
    }
    func restore(_ session:Session,sessionID:String) {state.sessions[sessionID]=session}
    func snapshot(_ sessionID:String)->Snapshot {
        Snapshot(session:state.sessions[sessionID] ?? Session(),findings:state.findings.filter{$0.ownerID==nil || $0.ownerID==sessionID},checks:state.checks.filter{$0.ownerID==nil || $0.ownerID==sessionID},lastScan:state.lastScan,isScanning:running,sources:sources+(state.sessions[sessionID]?.customSources ?? []),automaticDates:state.automaticDates)
    }
    func toggleFavorite(_ id:String,sessionID:String) {
        var s=state.sessions[sessionID] ?? Session()
        if s.favorites.contains(id){s.favorites.removeAll{$0==id}}else{s.favorites.append(id)}
        state.sessions[sessionID]=s;save()
    }
    func saveLive(_ id:String,url:String,sessionID:String) {
        guard PublicHTTP.validURL(url) != nil else{return}
        var s=state.sessions[sessionID] ?? Session();s.liveLinks[id]=url;state.sessions[sessionID]=s;save()
    }
    func removeLive(_ id:String,sessionID:String) {
        var s=state.sessions[sessionID] ?? Session();s.liveLinks.removeValue(forKey:id);state.sessions[sessionID]=s;save()
    }
    func approve(_ findingID:String,sessionID:String) {
        guard let f=state.findings.first(where:{$0.id==findingID && ($0.ownerID==nil || $0.ownerID==sessionID)}) else{return}
        var s=state.sessions[sessionID] ?? Session()
        let matches=DateExtraction.matchingRaces(source:RaceSource(id:f.sourceID,name:f.sourceName,country:"",url:f.sourceURL),races:races,year:String(f.start.prefix(4)))
        var dates=s.dateOverrides ?? [:]
        if matches.isEmpty {
            s.approved[f.sourceID]=f.start
            let id="personal-"+f.sourceID+"-"+String(f.start.prefix(4))
            dates[id]=DateUpdate(raceID:id,start:f.start,end:f.end,sourceURL:f.sourceURL,evidence:f.evidence,checkedAt:ISO8601DateFormatter().string(from:Date()))
        }
        for race in matches {
            s.approved[race.id]=f.start
            dates[race.id]=DateUpdate(raceID:race.id,start:f.start,end:f.end,sourceURL:f.sourceURL,evidence:f.evidence,checkedAt:ISO8601DateFormatter().string(from:Date()))
        }
        s.dateOverrides=dates
        state.sessions[sessionID]=s;save()
    }
    func ignore(_ findingID:String,sessionID:String) {
        var s=state.sessions[sessionID] ?? Session()
        if !s.ignored.contains(findingID){s.ignored.append(findingID)}
        state.sessions[sessionID]=s;save()
    }
    func addSource(name:String,url:String,sessionID:String) {
        guard name.count>2,name.count<160,PublicHTTP.validURL(url) != nil else{return}
        var s=state.sessions[sessionID] ?? Session()
        if s.customSources.count>=40 || s.customSources.contains(where:{$0.url==url}){return}
        s.customSources.append(RaceSource(id:UUID().uuidString,name:name,country:"",url:url))
        state.sessions[sessionID]=s;save()
    }
    func removeSource(id:String,sessionID:String) {
        var s=state.sessions[sessionID] ?? Session();s.customSources.removeAll{$0.id==id};state.sessions[sessionID]=s;save()
    }
    func stop(sessionID:String) {if scanOwner==sessionID {cancel=true}}
    func ingest(_ data:Data) {
        guard let imported=try? JSONDecoder().decode(Persisted.self,from:data) else{return}
        for (id,value) in imported.automaticDates where (state.automaticDates[id]?.checkedAt ?? "") < value.checkedAt {state.automaticDates[id]=value}
        for finding in imported.findings where !state.findings.contains(where:{$0.id==finding.id}){state.findings.append(finding)}
        if imported.lastScan>state.lastScan {state.checks=imported.checks;state.lastScan=imported.lastScan;state.sourceCursor=imported.sourceCursor}
        save()
    }
    func exportPublic(to path:URL) throws {
        var copy=state;copy.sessions=[:]
        copy.findings.removeAll{$0.ownerID != nil}
        copy.checks.removeAll{$0.ownerID != nil}
        let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
        try encoder.encode(copy).write(to:path,options:.atomic)
    }
    func scanIfDue(force:Bool=false,sessionID:String?=nil,all:Bool=false) async {
        if running{return}
        let interval:TimeInterval=force ? 60 : 96*60
        if !all,let last=ISO8601DateFormatter().date(from:state.lastScan),Date().timeIntervalSince(last)<interval{return}
        running=true;cancel=false;scanOwner=sessionID
        defer{running=false;scanOwner=nil;state.lastScan=ISO8601DateFormatter().string(from:Date());save()}
        var selected:[RaceSource]=[]
        let count=all ? sources.count : min(12,sources.count)
        if !sources.isEmpty {
            for offset in 0..<count{selected.append(sources[(state.sourceCursor+offset)%sources.count])}
            state.sourceCursor=(state.sourceCursor+count)%sources.count
        }
        if let id=sessionID {selected += state.sessions[id]?.customSources ?? []}
        for source in selected {
            if cancel || Task.isCancelled{break}
            let trusted=sources.contains(where:{$0.url==source.url})
            let message:String
            do {
                let response=try await PublicHTTP.fetch(source.url,trusted:trusted)
                guard response.status==200 else{throw URLError(.badServerResponse)}
                let candidates=Self.extractDates(String(decoding:response.data,as:UTF8.self),source:source).map { item in
                    var item=item
                    if !trusted{item.ownerID=sessionID}
                    return item
                }
                for f in candidates where !state.findings.contains(where:{$0.id==f.id}){state.findings.append(f)}
                let good=candidates.filter{$0.confidence=="structured" || $0.confidence=="official-label"}
                var applied=0
                // Conflicting high-confidence dates remain reviewable hints.
                for year in Set(good.map{String($0.start.prefix(4))}) {
                    let dates=good.filter{String($0.start.prefix(4))==year}
                    guard Set(dates.map(\.start)).count==1,let finding=dates.first else{continue}
                    let matching=DateExtraction.matchingRaces(source:source,races:races,year:year)
                    for race in matching {
                        // A festival-wide JSON-LD range must not move a known
                        // individual race (e.g. Lavaredo 120K) to expo day.
                        if let end=finding.end,finding.start<race.start,race.start<=end,
                           race.end==nil || race.end==race.start {continue}
                        let update=DateUpdate(raceID:race.id,start:finding.start,end:finding.end,sourceURL:source.url,evidence:finding.evidence,checkedAt:ISO8601DateFormatter().string(from:Date()))
                        if trusted {state.automaticDates[race.id]=update;applied+=1}
                    }
                    if trusted && matching.isEmpty && year>=String(dateOnly().prefix(4)),["2026","2027"].contains(year) {
                        let id="auto-"+source.id+"-"+year
                        state.automaticDates[id]=DateUpdate(raceID:id,start:finding.start,end:finding.end,sourceURL:source.url,evidence:finding.evidence,checkedAt:ISO8601DateFormatter().string(from:Date()))
                        applied+=1
                    }
                }
                message="\(candidates.count) Datumshinweise · \(applied) eindeutig zugeordnete Termine automatisch übernommen"
            } catch {message="Abruf nicht möglich; gespeicherte Termine bleiben erhalten"}
            let check=SourceCheck(name:source.name,message:message,checkedAt:ISO8601DateFormatter().string(from:Date()),ownerID:trusted ? nil : sessionID)
            state.checks.removeAll{$0.name==source.name && $0.ownerID==check.ownerID};state.checks.append(check)
            save()
        }
        if state.findings.count>2000{state.findings=Array(state.findings.suffix(2000))}
    }
    static func extractDates(_ html:String,source:RaceSource)->[Finding] {DateExtraction.findings(html,source:source)}
}
