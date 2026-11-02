import Foundation
@main struct DateChecks {
    static func main() async throws {
        let source=RaceSource(id:"example",name:"Example Mountain Trail",country:"DE",url:"https://example.org/")
        let html=#"<script type="application/ld+json">{"@type":"SportsEvent","name":"Example Mountain Trail 2027","startDate":"2027-06-25T06:00:00+02:00","endDate":"2027-06-27"}</script><p>Registration starts 2027-01-15</p>"#
        let found=DateExtraction.findings(html,source:source)
        precondition(found.contains{$0.start=="2027-06-25" && $0.end=="2027-06-27" && $0.confidence=="structured"})
        precondition(!found.contains{$0.start=="2027-01-15" && $0.confidence != "hint"})
        let formats=["Race date: 25. Juni 2027","Race date: June 25, 2027","比赛时间：2027年6月25日","Event date: 25.06.2027"]
        for text in formats{precondition(DateExtraction.findings(text,source:source).contains{$0.start=="2027-06-25"},text)}
        let range=DateExtraction.findings("Race date: 25–27 June 2027",source:source)
        precondition(range.count==1 && range[0].start=="2027-06-25" && range[0].end=="2027-06-27","Never mistake the last day of a range for its start")
        let crossing=DateExtraction.findings("Race date: 30. September – 3. Oktober 2027",source:source)
        precondition(crossing.count==1 && crossing[0].start=="2027-09-30" && crossing[0].end=="2027-10-03")
        precondition(DateExtraction.iso("2027-02-30")==nil)
        precondition(DateExtraction.iso("2028-02-29")=="2028-02-29")
        for ip in ["127.0.0.1","10.0.0.1","172.16.0.1","169.254.169.254","192.168.1.1","::1","fd00::1","::ffff:127.0.0.1"]{precondition(!PublicHTTP.publicAddress(ip))}
        for url in ["https://127.0.0.1/","http://example.org/","https://user:pass@example.org/","https://example.org:8080/","https://example.local/"]{precondition(PublicHTTP.validURL(url)==nil)}
        precondition(InlineResults.parseJSON(Data(#"{"data":[{"unrelated":"value"}]}"#.utf8))==nil)
        precondition(InlineResults.parseJSON(Data(#"{"results":[{"rank":1,"name":"Runner","time":"01:00:00"}]}"#.utf8)) != nil)
        let chinese="<table><tr><th>排名</th><th>姓名</th><th>成绩</th></tr><tr><td>1</td><td>测试</td><td>02:34:00</td></tr></table>"
        precondition(InlineResults.parseTable(chinese)?.contains("测试")==true)
        let bibTimes="<table><tr><th>Bib No.</th><th>Name</th><th>Chip Time</th></tr><tr><td>123</td><td>测试</td><td>02:34:00</td></tr></table>"
        precondition(InlineResults.parseTable(bibTimes) != nil)
        precondition(InlineResults.parseTable(bibTimes.replacingOccurrences(of:"02:34:00",with:"—"))==nil,"A registration list without recorded times is not a live result")
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent("trailatlas-private-source-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:directory)}
        var data=Persisted()
        data.sessions["owner"]=Session(favorites:["private-favorite"])
        data.findings=[Finding(id:"private",sourceID:"custom",sourceName:"Private custom source",sourceURL:"https://example.org/private",start:"2027-06-25",evidence:"private",inspectedAt:"2026-11-01",ownerID:"owner")]
        data.checks=[SourceCheck(name:"Private custom source",message:"checked",checkedAt:"2026-11-01",ownerID:"owner")]
        try JSONEncoder().encode(data).write(to:directory.appendingPathComponent("state.json"))
        let store=TrailStore(directory:directory.path,sources:[])
        let own=await store.snapshot("owner"),other=await store.snapshot("other")
        precondition(own.findings.count==1 && other.findings.isEmpty && other.checks.isEmpty)
        let export=directory.appendingPathComponent("public.json")
        try await store.exportPublic(to:export)
        let publicData=try JSONDecoder().decode(Persisted.self,from:Data(contentsOf:export))
        precondition(publicData.sessions.isEmpty && publicData.findings.isEmpty && publicData.checks.isEmpty,"Never publish personal sources or favorites")
        var candidateData=Persisted()
        candidateData.findings=[Finding(id:"next-edition",sourceID:source.id,sourceName:source.name,sourceURL:source.url,start:"2027-06-25",evidence:"Official date range",inspectedAt:"2026-11-01",end:"2027-06-27")]
        let nextDir=directory.appendingPathComponent("next-edition")
        try FileManager.default.createDirectory(at:nextDir,withIntermediateDirectories:true)
        try JSONEncoder().encode(candidateData).write(to:nextDir.appendingPathComponent("state.json"))
        let old=Race(id:"previous",name:"Example Mountain Trail",dateLabel:"2026-06-20",start:"2026-06-20",end:nil,country:"🇩🇪",isoCountry:"DE",distance:"25 km",category:"trail",status:"",eliteVerified:false,details:"",sourceURL:source.url,origin:"original")
        let editions=TrailStore(directory:nextDir.path,sources:[source],races:[old])
        await editions.approve("next-edition",sessionID:"owner")
        let approved=await editions.snapshot("owner")
        let calendar=CalendarRaces.materialize([old],snapshot:approved)
        precondition(calendar.count==2 && calendar.contains{$0.id=="previous" && $0.start=="2026-06-20"})
        precondition(calendar.contains{$0.start=="2027-06-25" && $0.end=="2027-06-27"},"Approving a new edition creates its calendar card without changing the previous year")
        print("PASS structured event dates, registration rejection, German/English/Chinese formats, leap years, public HTTPS validation and real result schemas")
    }
}
