import Foundation

// Generated page uses the unchanged original CSS and DOM skeleton. Dynamic components
// are rendered in Swift; `tagHTML` and `noticeHTML` are provided by ElementaryParts.swift.
struct TrailUI: Sendable {
    let template: String
    let races: [Race]

    func page(filters f: Filters, state: Snapshot, sessionID: String, autoTracking: TrackingSnapshot, livePayload: String? = nil) -> String {
        let favs=Set(state.session.favorites)
        let allRaces=CalendarRaces.materialize(races,snapshot:state)
        let filtered=allRaces.filter{f.matches($0,favorites:favs)}.sorted { a,b in
            if f.sort == "name-asc" {return a.name.localizedStandardCompare(b.name)==ComparisonResult.orderedAscending}
            if a.start.isEmpty != b.start.isEmpty{return !a.start.isEmpty}
            if f.sort == "date-desc" {return a.start==b.start ? a.name.localizedStandardCompare(b.name)==ComparisonResult.orderedAscending : a.start>b.start}
            return (a.start.isEmpty ? "9999" : a.start) < (b.start.isEmpty ? "9999" : b.start)
        }
        let limit = max(44, min(1000, f.page*44))
        let shown=Array(filtered.prefix(limit))
        let (wstart,wend)=nextWeekend()
        let onWeekend=allRaces.filter{r in
            let start=effectiveStart(r,state.session)
            return !start.isEmpty && start<=wend && effectiveEnd(r,start:start)>=wstart
        }.sorted{effectiveStart($0,state.session)<effectiveStart($1,state.session)}
        let running=allRaces.filter{r in
            let start=effectiveStart(r,state.session);return !start.isEmpty && start<=dateOnly() && effectiveEnd(r,start:start)>=dateOnly()
        }
        let activeLive=allRaces.first{$0.id == f.liveRace}
        let officialLive = activeLive.flatMap { race -> String? in
            let u = race.sourceURL.lowercased()
            if u.contains("raceresult.com/") || u.contains("livetrail.net/") || u.contains("live.utmb.world/") { return race.sourceURL }
            return nil
        }
        let autoLink=activeLive.flatMap{autoTracking.links[$0.id]}
        let safeAutoURL=autoLink.flatMap{autoTracking.verification[$0.raceID]?.status=="andere_ausgabe" ? nil : $0.url}
        let selectedLiveURL=activeLive.flatMap{state.session.liveLinks[$0.id]} ?? safeAutoURL ?? officialLive ?? ""
        let checkedLinks=autoTracking.verification.values.filter{$0.status == "erreichbar"}.count
        let autoSummary="\(autoTracking.links.count) Quellen gefunden · \(autoTracking.checkedCount) Rennen durchsucht · \(checkedLinks) Quellen erreichbar · Prüfung alle 96 Min. (während Server läuft)"
        let selectedLiveInfo: String
        if let a=autoLink {
            let check=autoTracking.verification[a.raceID]
            let status:String
            switch check?.status {
            case "erreichbar": status="Quelle erreichbar, geprüft am \(check?.checkedAt ?? "—")"
            case "nicht_gefunden": status="Quelle derzeit nicht erreichbar (HTTP \(check?.httpStatus ?? 404)), Ersatz wird gesucht"
            case "blockiert": status="Anbieter verhindert automatischen Zugriff; Link bleibt erhalten"
            case "andere_ausgabe": status="Quelle zeigt inzwischen eine andere Jahresausgabe und wird deshalb nicht eingebettet; passender Ersatz wird gesucht"
            default: status="Quellenadresse noch nicht erneut überprüft"
            }
            selectedLiveInfo="Automatisch zugeordnet: \(a.provider) · \(status) · \(a.evidence)"
        } else if selectedLiveURL.isEmpty {
            selectedLiveInfo="Noch kein bestätigter Trackinglink. Die serverseitige Websuche läuft bei Bedarf automatisch."
        } else {
            selectedLiveInfo="Ergebnisquelle aus dem Kalender übernommen."
        }
        let months=["Alle","Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]
        let replacements:[String:String] = [
            "@@RACES@@":renderRaces(shown,whole:filtered,filters:f,favorites:favs,inlineContent:livePayload,selectedURL:selectedLiveURL),
            "@@WEEKEND@@":renderWeekend(f.weekendAll ? onWeekend : Array(onWeekend.prefix(10)), f:f, tracking:autoTracking),
            "@@RUNNING@@":renderRunning(running, f:f),
            "@@LIVE_FEED@@":renderUnifiedFeed(selectedURL:selectedLiveURL,payload:livePayload,raceID:f.liveRace),
            "@@ACTIVE_FILTERS@@":renderActiveFilters(f),
            "@@YEAR_CHIPS@@":chipLinks([("all","Alle"),("2026","2026"),("2027","2027")],field:"year",selected:f.year,f:f,klass:"year-pills"),
            "@@MONTH_CHIPS@@":chipLinks(months.enumerated().map{(String($0.offset),$0.element)},field:"month",selected:String(f.month),f:f,klass:"month-grid"),
            "@@DISTANCE_CHIPS@@":chipLinks([("all","Alle"),("short","10–20 km"),("medium","20–35 km"),("long","35+ km")],field:"distance",selected:f.distance,f:f,klass:"chip-grid"),
            "@@COUNTRIES@@":countryOptions(f,allRaces),
            "@@LIVE_OPTIONS@@":liveOptions(allRaces,f),
            "@@HERO_COUNT@@":String(allRaces.count),
            "@@HERO_COUNTRIES@@":String(Set(allRaces.map{$0.countryName}).count),
            "@@HERO_ELITE@@":String(allRaces.filter{$0.category=="elite" || $0.category=="series"}.count),
            "@@RESULTCOUNT@@":"\(filtered.count) Rennen",
            "@@LIST_SUBTITLE@@":filtered.count==allRaces.count ? "Deine gesamte internationale Sammlung · chronologisch nach Datum" : "Gefilterte Auswahl aus \(allRaces.count) Kalendereinträgen",
            "@@WEEKEND_COUNT@@":"\(onWeekend.count) Rennen",
            "@@WEEKEND_DATES@@":"\(germanDate(wstart)) – \(germanDate(wend)) · Kommendes Wochenende",
            "@@LIVE_CONNECTION@@":selectedLiveURL.isEmpty ? "Noch keine verifizierte Live-Quelle für dieses Rennen gefunden. Es werden keine Ergebnisse erfunden." : "Ergebnisquelle gefunden · Anzeige wird im Live-Bereich etwa alle 90 Sekunden neu geladen.",
            "@@LIVE_DISCOVERY_STATUS@@":esc(autoSummary + (autoTracking.lastAttempt.isEmpty ? " · Noch keine laufende Kontrolle abgeschlossen" : " · Letzter Tracking-Abgleich: " + autoTracking.lastAttempt) + (autoTracking.running ? " · Prüfung läuft …" : "") + (!autoTracking.lastError.isEmpty ? " · Suchdienst teilweise nicht erreichbar" : "")),
            "@@LIVE_DISCOVERY_SOURCE@@":esc(selectedLiveInfo),
            "@@LIVE_MANUAL_RACE@@":esc(f.liveRace),
            "@@LIVE_SEARCH_URL@@":f.link(["action":"discover-live","section":"live","race":f.liveRace],fragment:"#live-panel"),
            "@@RADAR_STATUS@@":state.isScanning ? "Prüfung läuft" : "Bereit",
            "@@RADAR_MONITORED@@":"\(state.sources.count) Quellen",
            "@@RADAR_DATE@@":state.lastScan.isEmpty ? "Noch kein Prüflauf" : esc(state.lastScan),
            "@@RADAR_CHANGES@@":"\(state.findings.filter{!state.session.ignored.contains($0.id)}.count) offen",
            "@@RADAR_PROGRESS@@":state.isScanning ? "Veranstalterseiten werden geprüft …" : "Letzter Prüflauf abgeschlossen oder noch nicht gestartet",
            "@@RADAR_PENDING@@":renderFindings(state,f:f),
            "@@RADAR_CONFIRMED@@":renderApproved(state),
            "@@RADAR_HISTORY@@":state.checks.suffix(10).reversed().map{"<li>\(esc($0.checkedAt)): \(esc($0.name)) – \(esc($0.message))</li>"}.joined(),
            "@@RADAR_CUSTOM_LIST@@":state.session.customSources.map{source in
                "<li>\(esc(source.name)) · <a href=\"\(esc(source.url))\" target=\"_blank\" rel=\"noopener noreferrer\">Quelle ↗</a> · <a href=\"\(f.link(["section":"radar","action":"remove-source","sourceID":source.id]))\">Entfernen</a></li>"
            }.joined(),
            "@@RADAR_CHECKS@@":state.checks.map{"<li>\(esc($0.name)) · \(esc($0.message))</li>"}.joined(),
            "@@INSTANT_SYNC_MESSAGE@@":state.isScanning ? "Die Terminprüfung läuft im Hintergrund …" : "Termine werden beim Aufruf serverseitig überprüft, falls eine Kontrolle fällig ist.",
            "@@INSTANT_SYNC_DETAIL@@":state.lastScan.isEmpty ? "Noch keine Quellenkontrolle – Internetverbindung des Servers erforderlich." : "Letzte Prüfung: \(esc(state.lastScan)). Eindeutige Veranstaltertermine werden automatisch übernommen; mehrdeutige Hinweise bleiben zur Prüfung offen.",
            "@@MINI_RADAR_STATUS@@":state.isScanning ? "Aktualisiert …" : "\(state.findings.count) mögliche Termine",
            "@@HIDDEN_FILTERS@@":hidden(["year":f.year,"month":String(f.month),"distance":f.distance,"sort":f.sort,"view":f.view,"section":"calendar"]),
            "@@SORT_HIDDEN@@":hidden(f.params.filter{$0.key != "sort"}),
            "@@LIVE_DIRECT@@":selectedLiveURL.isEmpty ? "#live-panel" : esc(selectedLiveURL),
            "@@LIVE_REMOVE@@":f.link(["action":"remove-live","section":"live","race":f.liveRace]),
            "@@LIVE_REFRESH@@":f.link(["section":"live"],fragment:"#live-panel"),
            "@@LOAD_MORE@@":f.link(["page":String(f.page+1)],fragment:"#race-results"),
            "@@QUICK_ELITE@@":f.link(["elite":f.elite ? nil : "1","page":nil]),
            "@@QUICK_TBA@@":f.link(["tba":f.tba ? nil : "1","page":nil]),
            "@@VIEW_LIST@@":f.link(["view":nil]),
            "@@VIEW_GRID@@":f.link(["view":"grid"]),
        ]
        var result=template
        for (key,value) in replacements {result=result.replacingOccurrences(of:key,with:value)}
        let jumps = ["ALL":"", "Deutschland":"Deutschland", "Österreich":"Österreich", "Schweiz":"Schweiz", "Italien":"Italien", "Frankreich":"Frankreich", "Spanien":"Spanien", "USA":"USA", "China":"China", "Japan":"Japan"]
        for (key,value) in jumps { result=result.replacingOccurrences(of:"@@COUNTRY_JUMP_\(key)@@",with:esc(f.link(["country": value.isEmpty ? nil : value,"page":nil]))) }

        // The old website hid controls and sections until JavaScript booted. Swift now supplies state.
        if f.section == "radar" {
            result=result.replacingOccurrences(of:"class=\"radar-panel\"",with:"class=\"radar-panel show\"")
            result=result.replacingOccurrences(of:"id=\"main-list-panel\"",with:"id=\"main-list-panel\" style=\"display:none\"")
        }
        func setClass(_ id:String,_ name:String,_ enabled:Bool=true) {
            let tagPattern="<[a-zA-Z][^>]*\\bid=\""+NSRegularExpression.escapedPattern(for:id)+"\"[^>]*>"
            guard let range=result.range(of:tagPattern,options:.regularExpression) else{return}
            var tag=String(result[range])
            if let old=tag.range(of:#"class="[^"]*""#,options:.regularExpression) {
                let raw=String(tag[old].dropFirst(7).dropLast())
                var classes=raw.split(separator:" ").map(String.init).filter{$0 != name}
                if enabled{classes.append(name)}
                tag.replaceSubrange(old,with:"class=\""+classes.joined(separator:" ")+"\"")
            }else if enabled{tag.insert(contentsOf:" class=\"\(name)\"",at:tag.index(before:tag.endIndex))}
            result.replaceSubrange(range,with:tag)
        }
        if f.view == "grid" {setClass("race-results","events-grid");setClass("view-grid","on");setClass("view-list","on",false)}
        if f.elite{setClass("quick-elite","on")}
        if f.tba{setClass("quick-tba","on")}
        if filtered.count <= limit{result=result.replacingOccurrences(of:"id=\"load-more\"",with:"hidden=\"\" id=\"load-more\"")}
        if onWeekend.count<=10 {result=result.replacingOccurrences(of:"id=\"weekend-more\"",with:"hidden=\"\" id=\"weekend-more\"")}
        if f.weekendAll {result=result.replacingOccurrences(of:"Weitere Wochenendrennen anzeigen ↓",with:"Weniger anzeigen ↑")}
        if !f.q.isEmpty {result=result.replacingOccurrences(of:"id=\"search-input\"",with:"id=\"search-input\" value=\"\(esc(f.q))\"")}
        if let min=f.minKm{result=result.replacingOccurrences(of:"id=\"distance-min\"",with:"id=\"distance-min\" value=\"\(min)\"")}
        if let max=f.maxKm{result=result.replacingOccurrences(of:"id=\"distance-max\"",with:"id=\"distance-max\" value=\"\(max)\"")}
        for (flag,on) in [("category-elite",f.elite),("category-series",f.series),("category-tba",f.tba),("only-favs",f.favs),("only-upcoming",f.upcoming)] where on {
            result=result.replacingOccurrences(of:"id=\"\(flag)\"",with:"checked=\"\" id=\"\(flag)\"")
        }
        result=result.replacingOccurrences(of:"value=\"\(f.sort)\">",with:"selected=\"\" value=\"\(f.sort)\">")
        if !f.liveRace.isEmpty {result=result.replacingOccurrences(of:"id=\"live-source-url\"",with:"id=\"live-source-url\" value=\"\(esc(selectedLiveURL))\"")}
        if !selectedLiveURL.isEmpty {result=result.replacingOccurrences(of:"hidden=\"\" id=\"live-direct\"",with:"id=\"live-direct\"")}
        if !f.liveRace.isEmpty && (f.section == "live" || f.detail == f.liveRace) {
            result=result.replacingOccurrences(of:"@@META_REFRESH@@",with:"\(selectedLiveURL.isEmpty ? 30 : 90);url=\(f.link([:],fragment: f.section == "live" ? "#live-panel" : "#details-\(encoded(f.liveRace))"))")
        } else if f.section == "radar" && state.isScanning {
            result=result.replacingOccurrences(of:"@@META_REFRESH@@",with:"20;url=\(f.link(["section":"radar"]))")
        } else {
            result=result.replacingOccurrences(of:#"<meta content="@@META_REFRESH@@" http-equiv="refresh" id="server-refresh"/>"#,with:"")
            result=result.replacingOccurrences(of:"@@META_REFRESH@@",with:"86400") // fallback only
        }
        // Pending state label should not imply automatic live confirmation.
        result=result.replacingOccurrences(of:"Offline nutzbar",with:"Ohne Browser-JavaScript")
        return result
    }

    private func effectiveStart(_ race:Race,_ session:Session)->String {
        applyApprovedDate(race, session).start
    }
    // Match exact official-source IDs to their 2027 seed entry. Never modify
    // another event edition merely because a substring happens to match.
    private func applyApprovedDate(_ race:Race,_ session:Session)->Race {
        let legacyKey=race.id.hasPrefix("seed-") ? String(race.id.dropFirst(5)) : ""
        guard let newStart=session.approved[race.id] ?? session.approved[legacyKey],
              DateExtraction.iso(newStart)==newStart else{return race}
        return race.replacingDates(start:newStart)
    }
    private func effectiveEnd(_ race:Race,start:String)->String {
        // End date can sometimes appear in an original date label (multiple days).
        // Conservative: do not invent duration for date-only records.
        return race.end ?? start
    }
    private func hidden(_ params:[String:String])->String {
        params.sorted{$0.key<$1.key}.map{"<input type=\"hidden\" name=\"\(esc($0.key))\" value=\"\(esc($0.value))\">"}.joined()
    }
    private func renderRaces(_ shown:[Race],whole:[Race],filters f:Filters,favorites:Set<String>,inlineContent:String?,selectedURL:String)->String {
        if shown.isEmpty{return "<div class=\"empty-state\"><div class=\"emoji\">🏔️</div><h3>Keine passenden Rennen</h3><p>Ändere deine Filter oder setze die Suche zurück.</p><a href=\"/\">Filter zurücksetzen</a></div>"}
        var sections:[String:[Race]] = [:];var order:[String]=[]
        for race in shown {
            let group=f.sort=="name-asc" ? "name" : (race.start.isEmpty ? "TBA" : String(race.start.prefix(7)))
            if sections[group]==nil{sections[group]=[];order.append(group)}
            sections[group,default:[]].append(race)
        }
        return order.map{group in
            let elements=sections[group] ?? []
            let title: String
            if group=="name"{title="Name A – Z"}
            else if group=="TBA"{title="Termin noch offen"}
            else {
                let month=Int(group.suffix(2)) ?? 1
                title="\(longMonths[max(0,min(11,month-1))]) \(group.prefix(4))"
            }
            let count=group=="name" ? whole.count : whole.filter{r in r.start.isEmpty ? group=="TBA" : String(r.start.prefix(7))==group}.count
            return "<section class=\"month-section\"><div class=\"month-title\"><h3>\(esc(title))</h3><div class=\"month-line\"></div><span class=\"month-total\">\(count) Rennen</span></div><div class=\"event-stack\">\(elements.map{raceCard($0,f:f,favorites:favorites,inlineContent:inlineContent,selectedURL:selectedURL)}.joined())</div></section>"
        }.joined()
    }
    private func raceCard(_ r:Race,f:Filters,favorites:Set<String>,inlineContent:String?,selectedURL:String)->String {
        let d=r.start;let month=r.month;let dateStamp=d.isEmpty ? "<span class=\"date-short\">TBA</span><span class=\"date-weekday\">—</span>" : "<span class=\"date-short\">\(shortMonths[max(0,min(11,month-1))]) <b>\(Int(d.suffix(2)) ?? 0)</b></span><span class=\"date-weekday\">\(weekday(d))</span>"
        let type=r.category=="elite" ? "Elitefeld" : r.category=="series" ? "Rennserie" : "Trailrun"
        var tags=tagHTML(type,klass:r.category)
        if r.origin=="2027-seed" {tags+=tagHTML("Terminquelle hinterlegt",klass:"verified")}
        if r.origin=="automatic-date" {tags+=tagHTML("Veranstaltertermin",klass:"verified")}
        if r.status.folded.contains("championship") || r.status.folded.contains("meisterschaft") {tags+=tagHTML("Championship",klass:"series")}
        for seg in r.distance.components(separatedBy:"/").prefix(5) where seg.count<46 {tags+=tagHTML(seg.trimmingCharacters(in:.whitespacesAndNewlines),klass:"")}
        let toggle=f.link(["action":"toggle-fav","id":r.id],fragment:"#details-\(encoded(r.id))")
        let live=f.link(["section":"calendar","race":r.id,"detail":r.id],fragment:"#details-\(encoded(r.id))")
        let detail=f.link(["detail":f.detail == r.id ? nil : r.id],fragment:"#details-\(encoded(r.id))")
        let origin=r.details.isEmpty ? "" : "<div class=\"event-note\">\(esc(String(r.details.prefix(200))))</div>"
        let link=r.sourceURL.isEmpty ? "<span>Keine offizielle Quelle in der Masterliste hinterlegt.</span>" : "<a href=\"\(esc(r.sourceURL))\" rel=\"noopener noreferrer\" target=\"_blank\">\(esc(r.sourceURL)) ↗</a>"
        // The right-facing arrow must be an actual link. Do not invent an official
        // website when the source data only contains an external reference or no URL.
        let websiteArrow=raceWebsiteArrow(r)
        let expanded=f.detail == r.id
        let embedded=(expanded && f.liveRace == r.id) ? "<section class=\"race-inline-live\"><h5>◉ Live-Ergebnisse · \(esc(r.name))</h5>\(renderUnifiedFeed(selectedURL:selectedURL,payload:inlineContent,raceID:r.id))</section>" : ""
        return """
        <article class="event-wrap"><div class="event-row"><div class="datebox \(d.isEmpty ? "tba" : "")">\(dateStamp)</div><div class="event-main"><div class="event-name-line"><h4 class="event-name">\(esc(r.name))</h4></div><div class="event-meta"><span class="flag">\(esc(r.country))</span><span>\(esc(r.countryName))</span><span class="meta-sep">·</span><span>\(esc(germanDate(d)))</span></div><div class="tags">\(tags)</div>\(origin)</div><div class="event-side"><a class="fav-btn \(favorites.contains(r.id) ? "on" : "")" href="\(esc(toggle))" title="Merken" aria-label="Merken">\(favorites.contains(r.id) ? "★" : "☆")</a><a class="detail-btn live-mini-btn" href="\(esc(live))">◉ Live</a><a class="detail-btn" href="\(esc(detail))" aria-expanded="\(expanded)">Details ▾</a>\(websiteArrow)</div></div><div class="event-extra \(expanded ? "open" : "")" id="details-\(esc(r.id))"><p><b>Strecken:</b> \(esc(r.distance))<br><b>Kategorie:</b> \(esc(r.status))</p><p>\(esc(r.details))</p>\(link)\(embedded)</div></article>
        """
    }
    // The original database has URLs for only some races; the URL may point to
    // an event's information source rather than its own official domain.
    // No misleading ↗ control is rendered for entries without a real URL.
    private func raceWebsiteArrow(_ race: Race) -> String {
        let raw=race.sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parts=URLComponents(string: raw),
              let scheme=parts.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host=parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil else { return "" }
        let label=esc("Rennseite oder Quelle zu \(race.name) öffnen (neuer Tab)")
        return "<a class=\"detail-btn race-website-arrow\" href=\"\(esc(raw))\" target=\"_blank\" rel=\"noopener noreferrer\" aria-label=\"\(label)\" title=\"Rennseite oder Quelle öffnen\">↗</a>"
    }

    private func weekday(_ d:String)->String {
        let fmt=DateFormatter();fmt.dateFormat="yyyy-MM-dd";fmt.timeZone=TimeZone(secondsFromGMT:0)
        if let dt=fmt.date(from:d){fmt.dateFormat="EE";fmt.locale=Locale(identifier:"de_DE");return fmt.string(from:dt).uppercased()}
        return ""
    }
    private func renderWeekend(_ selected:[Race],f:Filters,tracking:TrackingSnapshot)->String {
        if selected.isEmpty{return "<div class=\"weekend-empty\">Für dieses Wochenende ist in deiner Liste kein Rennen mit bekanntem Datum eingetragen.</div>"}
        return selected.map{r in
            let source = tracking.links[r.id] == nil ? "Tracking suchen" : "Ergebnisse ansehen"
            let tag = (r.category == "elite" || r.category == "series") ? "🏆 Elite / Serie" : "Trailrun"
            let live=f.link(["section":"live","race":r.id],fragment:"#live-panel")
            return "<article class=\"weekend-tile\"><div class=\"weekend-meta\">\(esc(r.country)) \(esc(germanDate(r.start)))</div><div class=\"weekend-title\">\(esc(r.name))</div><div class=\"weekend-meta\">\(esc(r.distance))</div><div class=\"weekend-bot\"><span class=\"tag\">\(tag)</span><a class=\"mini-live-button\" href=\"\(esc(live))\">◉ \(source)</a></div></article>"
        }.joined()
    }
    private func renderRunning(_ selected:[Race],f:Filters)->String {
        if selected.isEmpty{return "<span class=\"running-empty\">Heute sind keine Rennen mit laufendem Veranstaltungszeitraum in deiner Liste hinterlegt.</span>"}
        return "<span class=\"running-label\">Heute im Kalender (nicht live bestätigt):</span>"+selected.prefix(9).map{r in
            let live=f.link(["section":"live","race":r.id],fragment:"#live-panel")
            return "<a class=\"running-chip\" href=\"\(esc(live))\">\(esc(r.country)) \(esc(r.name))</a>"
        }.joined()
    }
    private func renderUnifiedFeed(selectedURL:String,payload:String?,raceID:String)->String {
        let status="<p class=\"live-notice\">Quelle: öffentliches Timing · Anzeige aktualisiert sich während des Betrachtens etwa alle 90 Sekunden. Ergebnisse können verzögert eintreffen.</p>"
        if let payload=payload {return status+payload}
        guard !selectedURL.isEmpty else {return "<p class=\"live-fallback\">Für dieses Rennen wurde noch keine eindeutige, öffentlich abrufbare Ergebnisquelle gefunden. Wir zeigen keine erfundenen Platzierungen.</p>"}
        // A public page may forbid iframe framing, and a screenshot needs a
        // Chromium-capable server. Give an in-site fallback, not a forced redirect.
        let screenshot=ProcessInfo.processInfo.environment["ENABLE_LIVE_SNAPSHOTS"] == "1" ? "<div class=\"live-shot-wrap\"><img src=\"/live-image?race=\(encoded(raceID))\" alt=\"Öffentliche Ergebnis-Momentaufnahme (falls verfügbar)\" loading=\"lazy\" /></div>" : ""
        return status+"<p class=\"live-notice\">Diese Quelle liefert keine öffentlich auslesbare Ergebnistabelle. Die Einbettung verwendet kein JavaScript; alternativ lässt sich die Originalquelle direkt öffnen.</p>"+screenshot+renderLiveFrame(selectedURL)
    }
    private func renderLiveFrame(_ url:String)->String {
        guard !url.isEmpty,let u=URLComponents(string:url),u.scheme=="https",u.host != nil else {
            return "<p class=\"live-fallback\">Noch kein Livetracking-Link hinterlegt. Die Website zeigt keine erfundenen Zwischenzeiten oder Platzierungen an.</p>"
        }
        // External providers can forbid iframe embedding (CSP / X-Frame-Options).
        return "<p class=\"live-notice\">Anzeige nur möglich, wenn der Zeitmessdienst Einbettung gestattet. Sonst die Originalquelle direkt öffnen.</p><div class=\"live-feed active-embed\"><iframe sandbox=\"\" loading=\"lazy\" referrerpolicy=\"no-referrer\" src=\"\(esc(url))\" title=\"Offizielle Ergebnisse\"></iframe></div>"
    }
    private func renderActiveFilters(_ f:Filters)->String {
        var active=[String]();if !f.q.isEmpty{active.append("Suche: \(f.q)")};if !f.country.isEmpty{active.append(f.country)}
        if f.year != "all"{active.append(f.year)};if f.month>0{active.append(shortMonths[f.month-1])}
        if f.distance != "all"{active.append(f.distance)};if f.elite{active.append("Elite")};if f.series{active.append("Serie")};if f.tba{active.append("TBA")};if f.favs{active.append("Merkliste")};if f.upcoming{active.append("Kommende")}
        return active.map{"<span>\(esc($0))</span>"}.joined()
    }
    private func chipLinks(_ opts:[(String,String)],field:String,selected:String,f:Filters,klass:String)->String {
        return opts.map{(value,label) in
            let on=value==selected ? " on" : ""
            let url=f.link([field:value,"page":nil])
            return "<a class=\"chip\(on)\" href=\"\(esc(url))\">\(esc(label))</a>"
        }.joined()
    }
    private func countryOptions(_ f:Filters,_ allRaces:[Race])->String {
        let names=Set(allRaces.map{$0.countryName}).sorted{$0.localizedStandardCompare($1)==ComparisonResult.orderedAscending}
        return "<option value=\"\">Alle Länder</option>"+names.map{c in
            "<option value=\"\(esc(c))\" \(f.country==c ? "selected" : "")>\(esc(c)) · \(allRaces.filter{$0.countryName==c}.count)</option>"
        }.joined()
    }
    private func liveOptions(_ races:[Race],_ f:Filters)->String {
        return "<option value=\"\">Bitte Rennen wählen</option>"+races.map{r in
            "<option value=\"\(esc(r.id))\" \(r.id==f.liveRace ? "selected" : "")>\(esc(r.name))</option>"
        }.joined()
    }
    private func renderFindings(_ snap:Snapshot,f:Filters)->String {
        let pending=snap.findings.filter { finding in
            !snap.session.ignored.contains(finding.id) && !snap.automaticDates.values.contains(where:{$0.start==finding.start && $0.sourceURL==finding.sourceURL}) && !(snap.session.dateOverrides ?? [:]).values.contains(where:{$0.start==finding.start && $0.sourceURL==finding.sourceURL})
        }
        if pending.isEmpty{return "<li>Keine unbestätigten Terminhinweise gefunden.</li>"}
        return pending.map{r in
            let approve=f.link(["section":"radar","action":"approve","finding":r.id])
            let ignore=f.link(["section":"radar","action":"ignore","finding":r.id])
            return "<li><strong>\(esc(r.sourceName))</strong> · \(esc(r.start)) <a href=\"\(esc(r.sourceURL))\" target=\"_blank\" rel=\"noopener noreferrer\">Quelle prüfen ↗</a><p>\(esc(r.evidence))</p><a class=\"radar-mini\" href=\"\(esc(approve))\">Termin nach Prüfung übernehmen</a> <a class=\"radar-mini\" href=\"\(esc(ignore))\">Verwerfen</a></li>"
        }.joined()
    }
    private func renderApproved(_ snap:Snapshot)->String {
        let automatic=snap.automaticDates.values.sorted{$0.raceID<$1.raceID}.map { update in
            let name=races.first{$0.id==update.raceID}?.name ?? update.raceID
            return "<li>\(esc(name)) · \(esc(update.start)) · automatisch aus Veranstalterquelle</li>"
        }.joined()
        if snap.session.approved.isEmpty && automatic.isEmpty{return "<li>Noch keine Termine bestätigt.</li>"}
        return automatic + snap.session.approved.sorted{$0.key<$1.key}.map{"<li>\(esc($0.key)) · \(esc($0.value))</li>"}.joined()
    }
}
