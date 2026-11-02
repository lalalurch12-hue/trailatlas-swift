import Foundation

struct DateUpdate: Codable, Sendable {
    let raceID:String
    let start:String
    let end:String?
    let sourceURL:String
    let evidence:String
    let checkedAt:String
}

enum DateExtraction {
    static func valid(_ year:Int,_ month:Int,_ day:Int) -> String? {
        guard (2026...2035).contains(year),(1...12).contains(month),(1...31).contains(day) else{return nil}
        var cal=Calendar(identifier:.gregorian);cal.timeZone=TimeZone(secondsFromGMT:0)!
        let c=DateComponents(year:year,month:month,day:day)
        guard let date=cal.date(from:c),cal.dateComponents([.year,.month,.day],from:date)==c else{return nil}
        return String(format:"%04d-%02d-%02d",year,month,day)
    }
    static func iso(_ raw:String) -> String? {
        guard let g=InlineResults.matchGroups(raw,#"(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})"#).first else{return nil}
        return valid(Int(g[1]) ?? 0,Int(g[2]) ?? 0,Int(g[3]) ?? 0)
    }
    static func findings(_ html:String,source:RaceSource) -> [Finding] {
        var result:[Finding]=[]
        func add(_ start:String,_ end:String?,_ evidence:String,_ confidence:String) {
            let id=source.id+"|"+start
            guard !result.contains(where:{$0.id==id}) else{return}
            result.append(Finding(id:id,sourceID:source.id,sourceName:source.name,sourceURL:source.url,start:start,evidence:String(evidence.prefix(300)),inspectedAt:dateOnly(),end:end,confidence:confidence))
        }
        func walk(_ item:Any) {
            if let a=item as? [Any] {for x in a{walk(x)};return}
            guard let d=item as? [String:Any] else{return}
            let type=String(describing:d["@type"] ?? "")
            if type.contains("Event"),let raw=d["startDate"] as? String,let start=iso(raw) {
                let name=d["name"] as? String ?? source.name
                // Event JSON-LD must name this event; ticket dates and unrelated
                // events from a site's navigation never get auto-applied.
                let wanted=TrackingMatcher.tokens(source.name),actual=TrackingMatcher.normalize(name)
                let matched=wanted.filter{actual.contains($0)}.count
                let confidence = matched>=max(1,min(2,wanted.count)) ? "structured" : "hint"
                add(start,(d["endDate"] as? String).flatMap(iso),"\(name) · startDate=\(raw)",confidence)
            }
            for value in d.values where value is [String:Any] || value is [Any] {walk(value)}
        }
        for script in InlineResults.matchGroups(html,#"<script\b[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>"#) {
            if let data=script[1].data(using:.utf8),let obj=try? JSONSerialization.jsonObject(with:data){walk(obj)}
        }
        let text=InlineResults.stripHTML(html)
        let ns=text as NSString
        let months=["january":1,"jan":1,"januar":1,"february":2,"feb":2,"februar":2,"march":3,"mar":3,"märz":3,"maerz":3,"april":4,"apr":4,"may":5,"mai":5,"june":6,"jun":6,"juni":6,"july":7,"jul":7,"juli":7,"august":8,"aug":8,"september":9,"sep":9,"sept":9,"october":10,"oct":10,"oktober":10,"okt":10,"november":11,"nov":11,"december":12,"dec":12,"dezember":12,"dez":12,"juin":6,"juillet":7,"avril":4,"mayo":5,"junio":6,"julio":7,"octubre":10,"noviembre":11,"diciembre":12]
        let names=months.keys.sorted{$0.count>$1.count}.joined(separator:"|")
        var covered:[NSRange]=[]
        let ranges:[(String,Int)]=[
            (#"\b(\d{1,2})[.]?\s*[-–—]\s*(\d{1,2})[.]?\s*("#+names+#")[.]?[,]?\s*(20\d{2})\b"#,0),
            (#"\b("#+names+#")[.]?\s+(\d{1,2})\s*[-–—]\s*(\d{1,2})[,]?\s+(20\d{2})\b"#,1),
            (#"\b(\d{1,2})[.]?\s+("#+names+#")\s*[-–—]\s*(\d{1,2})[.]?\s+("#+names+#")\s+(20\d{2})\b"#,2),
            (#"\b(\d{1,2})[.](\d{1,2})[.]?\s*[-–—]\s*(\d{1,2})[.](\d{1,2})[.](20\d{2})\b"#,3)
        ]
        func context(_ range:NSRange)->(String,String) {
            let from=max(0,range.location-100),length=min(ns.length-from,range.length+200)
            let evidence=ns.substring(with:NSRange(location:from,length:length))
            let before=ns.substring(with:NSRange(location:from,length:range.location-from)).lowercased()
            let positive=["race date","event date","race weekend","renndatum","veranstaltungstermin","startdatum","比赛时间","赛事时间","开赛时间","race day"].contains{before.suffix(65).contains($0)}
            let negative=["registration","anmeldung","inscription","报名","lottery","抽签","copyright","newsletter"].contains{before.suffix(65).contains($0)}
            return (evidence,positive && !negative ? "official-label" : "hint")
        }
        for (pattern,kind) in ranges {
            let regex=try! NSRegularExpression(pattern:pattern,options:.caseInsensitive)
            for match in regex.matches(in:text,range:NSRange(location:0,length:ns.length)) {
                guard !covered.contains(where:{NSIntersectionRange($0,match.range).length>0}) else{continue}
                let g=(1..<match.numberOfRanges).map{ns.substring(with:match.range(at:$0)).lowercased()}
                let y=Int(g.last ?? "") ?? 0
                let firstDay=Int(g[kind==1 ? 1 : 0]) ?? 0
                let lastDay=Int(g[kind==0 ? 1 : 2]) ?? 0
                let firstMonth=kind==3 ? Int(g[1]) ?? 0 : months[g[kind==0 ? 2 : kind==1 ? 0 : 1]] ?? 0
                let lastMonth=kind==2 ? months[g[3]] ?? 0 : kind==3 ? Int(g[3]) ?? 0 : firstMonth
                guard let start=valid(y,firstMonth,firstDay),let end=valid(y,lastMonth,lastDay),end>=start else{continue}
                let (evidence,confidence)=context(match.range)
                let heroSources=Set(["oberaudorf-otf","innsbruck-iatf","grossglockner-mountain","grossglockner-ggut"])
                let preceding=ns.substring(with:NSRange(location:max(0,match.range.location-70),length:min(70,match.range.location))).lowercased()
                let registration=["registration","anmeldestart","anmeldezeitraum","inscription","报名"].contains{preceding.contains($0)}
                let officialHero=heroSources.contains(source.id) && match.range.location<2500 && covered.isEmpty && !registration
                add(start,end,evidence,officialHero ? "official-label" : confidence);covered.append(match.range)
            }
        }
        let patterns:[(String,Int)] = [
            (#"\b(20\d{2})[-/.年](\d{1,2})[-/.月](\d{1,2})日?"#,0),
            (#"\b(\d{1,2})[./](\d{1,2})[./](20\d{2})\b"#,1),
            (#"\b(\d{1,2})[.]?\s+("#+names+#")[.]?\s+(20\d{2})\b"#,2),
            (#"\b("#+names+#")[.]?\s+(\d{1,2})(?:st|nd|rd|th)?[,]?\s+(20\d{2})\b"#,3)
        ]
        for (pattern,kind) in patterns {
            let regex=try! NSRegularExpression(pattern:pattern,options:.caseInsensitive)
            for m in regex.matches(in:text,range:NSRange(location:0,length:ns.length)).prefix(60) {
                if covered.contains(where:{NSIntersectionRange($0,m.range).length>0}){continue}
                let a=(1...3).map{ns.substring(with:m.range(at:$0)).lowercased()}
                let y=Int(a[kind==0 ? 0 : 2]) ?? 0
                let mon=kind==0 || kind==1 ? Int(a[1]) ?? 0 : (months[a[kind==2 ? 1 : 0]] ?? 0)
                let day=Int(a[kind==0 ? 2 : kind==3 ? 1 : 0]) ?? 0
                guard let start=valid(y,mon,day) else{continue}
                let (evidence,confidence)=context(m.range)
                add(start,nil,evidence,confidence)
            }
        }
        let title=InlineResults.matchGroups(html,#"<title[^>]*>(.*?)</title>"#).first.map{TrackingMatcher.normalize($0[1])} ?? ""
        let sourceTokens=TrackingMatcher.tokens(source.name)
        if sourceTokens.filter({title.contains($0)}).count>=max(1,min(2,sourceTokens.count)) {
            for year in Set(result.map{String($0.start.prefix(4))}) where source.url.contains(year) {
                let indices=result.indices.filter{String(result[$0].start.prefix(4))==year}
                if indices.count==1,let index=indices.first,result[index].confidence=="hint" {
                    let evidence=result[index].evidence.lowercased()
                    if !["registration","anmeldung","inscription","报名","published","copyright"].contains(where:{evidence.contains($0)}) {result[index].confidence="official-label"}
                }
            }
        }
        return Array(result.prefix(40))
    }
    static func matchingRaces(source:RaceSource,races:[Race],year:String) -> [Race] {
        races.filter { race in
            let targetYear = race.year.isEmpty ? year : race.year
            guard targetYear==year else{return false}
            if race.id=="seed-"+source.id{return true}
            if !race.sourceURL.isEmpty,let a=URLComponents(string:race.sourceURL),let b=URLComponents(string:source.url),a.host==b.host,a.path==b.path{return true}
            let words=TrackingMatcher.tokens(race.name),name=TrackingMatcher.normalize(source.name)
            return !words.isEmpty && words.filter{name.contains($0)}.count>=max(1,min(3,words.count))
        }
    }
}

extension Race {
    func replacingDates(start newStart:String,end newEnd:String?=nil) -> Race {
        let formatter=DateFormatter();formatter.calendar=Calendar(identifier:.gregorian);formatter.timeZone=TimeZone(secondsFromGMT:0);formatter.locale=Locale(identifier:"en_US_POSIX");formatter.dateFormat="yyyy-MM-dd"
        var shiftedEnd=newEnd
        if shiftedEnd==nil,let old=formatter.date(from:start),let new=formatter.date(from:newStart),let e=end.flatMap({formatter.date(from:$0)}) {
            shiftedEnd=formatter.string(from:e.addingTimeInterval(new.timeIntervalSince(old)))
        }
        return Race(id:id,name:name,dateLabel:germanDate(newStart),start:newStart,end:shiftedEnd,country:country,isoCountry:isoCountry,distance:distance,category:category,status:status,eliteVerified:eliteVerified,details:details,sourceURL:sourceURL,origin:origin)
    }
}

enum CalendarRaces {
    static func materialize(_ races:[Race],snapshot:Snapshot) -> [Race] {
        let ids=Set(races.map(\.id))
        let dates=snapshot.automaticDates.merging(snapshot.session.dateOverrides ?? [:]){_,personal in personal}
        var result=races.map { original in
            var race=dates[original.id].map{original.replacingDates(start:$0.start,end:$0.end)} ?? original
            let legacy=race.id.hasPrefix("seed-") ? String(race.id.dropFirst(5)) : ""
            if let date=snapshot.session.approved[race.id] ?? snapshot.session.approved[legacy],DateExtraction.iso(date)==date {race=race.replacingDates(start:date)}
            return race
        }
        for update in dates.values.sorted(by:{$0.raceID<$1.raceID}) where !ids.contains(update.raceID) {
            guard let source=snapshot.sources.first(where:{$0.url==update.sourceURL}),DateExtraction.iso(update.start)==update.start else{continue}
            let prior=races.first{$0.sourceURL==source.url}
            let country=prior?.country ?? races.first{$0.countryCode==source.country}?.country ?? Race.flag(source.country)
            let year=String(update.start.prefix(4))
            let name=source.name.contains(year) ? source.name : source.name.replacingOccurrences(of:#"\s+20\d{2}\b"#,with:"",options:.regularExpression)+" "+year
            result.append(Race(id:update.raceID,name:name,dateLabel:germanDate(update.start),start:update.start,end:update.end,country:country,isoCountry:prior?.isoCountry ?? source.country,distance:"siehe Veranstalter",category:prior?.category ?? "trail",status:"Termin automatisch aus Veranstalterquelle",eliteVerified:false,details:update.evidence,sourceURL:source.url,origin:"automatic-date"))
        }
        return result
    }
}
