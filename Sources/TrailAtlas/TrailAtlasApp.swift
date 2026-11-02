import Foundation
import Hummingbird

@main
struct TrailAtlasApp {
    static func cookies(_ request:Request) -> [String:String] {
        var result:[String:String]=[:]
        for part in (request.headers[.cookie] ?? "").split(separator:";") {
            let pair=part.trimmingCharacters(in:.whitespaces).split(separator:"=",maxSplits:1).map(String.init)
            if pair.count==2,result[pair[0]]==nil{result[pair[0]]=pair[1]}
        }
        return result
    }
    static func response(_ text:String,status:HTTPResponse.Status = .ok,mime:String="text/html; charset=utf-8") -> Response {
        var response=Response(status:status,headers:[.contentType:mime,.cacheControl:"private, no-store"],body:.init(byteBuffer:ByteBuffer(string:text)))
        response.headers[.init("Content-Security-Policy")!]="default-src 'self'; script-src 'none'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; frame-src https:; form-action 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'self'"
        response.headers[.init("Referrer-Policy")!]="no-referrer"
        response.headers[.init("X-Content-Type-Options")!]="nosniff"
        return response
    }
    static func filters(_ p:[String:String])->Filters {
        func param(_ name:String)->String{p[name] ?? ""}
        var f=Filters()
        f.q=String(param("q").prefix(200));f.country=String(param("country").prefix(120))
        f.distance=["short","medium","long"].contains(param("distance")) ? param("distance") : "all"
        f.year=["2026","2027"].contains(param("year")) ? param("year") : "all"
        f.month=max(0,min(12,Int(param("month")) ?? 0))
        f.sort=["date-desc","name-asc"].contains(param("sort")) ? param("sort") : "date-asc"
        f.view=param("view")=="grid" ? "grid" : "list"
        f.section=["radar","live"].contains(param("section")) ? param("section") : "calendar"
        f.elite=param("elite")=="1";f.series=param("series")=="1";f.tba=param("tba")=="1"
        f.upcoming=param("upcoming")=="1";f.favs=param("favs")=="1";f.weekendAll=param("weekendAll")=="1"
        f.minKm=Double(param("minKm")).flatMap{$0.isFinite && $0>=0 && $0<=2000 ? $0 : nil}
        f.maxKm=Double(param("maxKm")).flatMap{$0.isFinite && $0>=0 && $0<=2000 ? $0 : nil}
        f.page=max(1,min(25,Int(param("page")) ?? 1));f.detail=String(param("detail").prefix(100));f.liveRace=String(param("race").prefix(100))
        return f
    }
    static func parameters(_ raw:String)->[String:String] {
        var result:[String:String]=[:]
        for item in URLComponents(string:"https://trailatlas.invalid/?"+raw.replacingOccurrences(of:"+",with:"%20"))?.queryItems ?? [] {
            if result[item.name]==nil{result[item.name]=item.value ?? ""}
        }
        return result
    }
    static func main() async throws {
        let env=ProcessInfo.processInfo.environment
        let resources=URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("Resources")
        let races=try JSONDecoder().decode([Race].self,from:Data(contentsOf:resources.appendingPathComponent("races.json")))
        guard races.count==352,Set(races.map(\.id)).count==352 else{throw URLError(.cannotParseResponse)}
        let sources=try JSONDecoder().decode([RaceSource].self,from:Data(contentsOf:resources.appendingPathComponent("sources.json")))
        let template=try String(contentsOf:resources.appendingPathComponent("template.html"),encoding:.utf8)
        let ui=TrailUI(template:template,races:races)
        let storage=env["DATA_DIR"] ?? "/tmp/trailatlas"
        let store=TrailStore(directory:storage,sources:sources,races:races)
        let verified=try JSONDecoder().decode([TrackingLink].self,from:Data(contentsOf:resources.appendingPathComponent("tracking_verified.json")))
        let tracking=TrackingDiscovery(races:races,seeds:verified,directory:storage)
        let shared=SharedData(base:env["SHARED_DATA_BASE_URL"])
        await shared.sync(store:store,tracking:tracking)
        if let index=CommandLine.arguments.firstIndex(of:"--discover"),CommandLine.arguments.count>index+1 {
            let id=CommandLine.arguments[index+1]
            await tracking.discoverIfDue(priorityID:id,force:true)
            let found=await tracking.snapshot()
            if let link=found.links[id] {
                let data=try JSONEncoder().encode(link)
                print(String(decoding:data,as:UTF8.self))
            }else{print("No publicly verifiable source found for "+id+": "+found.lastError)}
            return
        }
        if CommandLine.arguments.contains("--refresh") {
            await store.scanIfDue(force:true,all:CommandLine.arguments.contains("--all-sources"))
            let snapshot=await store.snapshot("")
            await tracking.updateRaces(CalendarRaces.materialize(races,snapshot:snapshot))
            await tracking.discoverIfDue()
            let output=URL(fileURLWithPath:env["PUBLIC_DATA_DIR"] ?? storage,isDirectory:true)
            try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
            try await store.exportPublic(to:output.appendingPathComponent("public-state.json"))
            try await tracking.exportPublic(to:output.appendingPathComponent("tracking-discovery.json"))
            let refreshed=await store.snapshot("");let links=await tracking.snapshot()
            print("TrailAtlas public refresh: \(refreshed.checks.count) sources checked; \(refreshed.automaticDates.count) dates; \(links.links.count) tracking sources; no private sessions exported")
            return
        }
        let codec=SessionCodec(secret:env["SESSION_SECRET"])
        let secure=env["COOKIE_SECURE"]=="1" || env["RENDER"]=="true"
        if env["SESSION_SECRET"]==nil{print("TrailAtlas: SESSION_SECRET missing; personal recovery cookies will not survive a process restart")}
        let resultCache=ResultCache()
        let screenshots=LiveScreenshots(directory:storage)
        let router=Router()
        let handler:@Sendable (Request,BasicRequestContext) async throws -> Response = {request,_ in
            var params=parameters(request.uri.query ?? "")
            if request.method == .post {
                guard (request.headers[.contentType] ?? "").hasPrefix("application/x-www-form-urlencoded") else{return response("Unbekanntes Formularformat",status:.unsupportedMediaType)}
                let body=try await request.body.collect(upTo:32768)
                let posted=parameters(String(buffer:body))
                params.merge(posted){_,new in new}
            }
            let f=filters(params)
            let jar=cookies(request)
            let oldID=jar["trail_session"] ?? ""
            let validID=oldID.count==36 && UUID(uuidString:oldID) != nil
            let sessionID=validID ? oldID : UUID().uuidString
            if validID,let saved=codec.decode(jar,id:sessionID){await store.restore(saved,sessionID:sessionID)}
            func withCookies(_ result:Response,_ session:Session)->Response {
                var result=result
                guard let chunks=codec.encode(session,id:sessionID) else{return response("Persönlicher Speicher ist voll. Bitte eine eigene Quelle entfernen oder einen kürzeren Link verwenden.",status:.contentTooLarge)}
                let suffix="; Path=/; HttpOnly; SameSite=Lax; Max-Age=31536000"+(secure ? "; Secure" : "")
                var values=["trail_session=\(sessionID)"+suffix]
                for i in 0..<SessionCodec.chunks{values.append("trail_state_\(i)=\(i<chunks.count ? chunks[i] : "")"+suffix)}
                result.headers[values:.setCookie]=values
                return result
            }
            if request.method == .post {
                guard codec.validCSRF(params["csrf"] ?? "",sessionID:sessionID) else{return response("Formular abgelaufen. Bitte Seite neu laden.",status:.forbidden)}
                let action=params["action"] ?? ""
                let before=await store.snapshot(sessionID)
                let calendar=CalendarRaces.materialize(races,snapshot:before)
                switch action {
                case "toggle-fav":
                    guard calendar.contains(where:{$0.id==params["id"]}) else{return response("Rennen nicht gefunden",status:.notFound)}
                    await store.toggleFavorite(params["id"]!,sessionID:sessionID)
                case "save-live":
                    guard calendar.contains(where:{$0.id==f.liveRace}),PublicHTTP.validURL(params["url"] ?? "") != nil else{return response("Bitte eine gültige öffentliche HTTPS-Adresse für das gewählte Rennen verwenden.",status:.badRequest)}
                    await store.saveLive(f.liveRace,url:params["url"]!,sessionID:sessionID)
                case "remove-live":await store.removeLive(f.liveRace,sessionID:sessionID)
                case "discover-live":
                    guard calendar.contains(where:{$0.id==f.liveRace}) else{return response("Rennen nicht gefunden",status:.notFound)}
                    Task {await tracking.discoverIfDue(priorityID:f.liveRace,force:true)}
                case "add-source":
                    guard PublicHTTP.validURL(params["sourceUrl"] ?? "") != nil,(params["sourceName"] ?? "").count>2,before.session.customSources.count<40 else{return response("Bitte Rennname und öffentliche HTTPS-Webseite eingeben. Maximal 40 eigene Quellen.",status:.badRequest)}
                    await store.addSource(name:params["sourceName"]!,url:params["sourceUrl"]!,sessionID:sessionID)
                case "remove-source":await store.removeSource(id:params["sourceID"] ?? "",sessionID:sessionID)
                case "approve":await store.approve(params["finding"] ?? "",sessionID:sessionID)
                case "ignore":await store.ignore(params["finding"] ?? "",sessionID:sessionID)
                case "scan":Task {await store.scanIfDue(force:true,sessionID:sessionID)}
                case "stop":await store.stop(sessionID:sessionID)
                default:return response("Unbekannte Aktion",status:.badRequest)
                }
                let after=await store.snapshot(sessionID)
                guard codec.encode(after.session,id:sessionID) != nil else {
                    await store.restore(before.session,sessionID:sessionID)
                    return response("Persönlicher Speicher ist voll; Änderung wurde nicht übernommen.",status:.contentTooLarge)
                }
                var redirect=response("",status:.seeOther)
                let fragment=f.liveRace.isEmpty ? (f.section=="radar" ? "#radar-panel" : "#race-results") : (f.section=="live" ? "#live-panel" : "#details-"+encoded(f.liveRace))
                redirect.headers[.location]=f.link([:],fragment:fragment)
                return withCookies(redirect,after.session)
            }
            if env["DISABLE_BACKGROUND"] != "1" {
                Task {await store.scanIfDue(sessionID:f.section=="radar" ? sessionID : nil)}
                Task {await tracking.discoverIfDue(priorityID:f.liveRace.isEmpty ? nil : f.liveRace)}
            }
            let snapshot=await store.snapshot(sessionID)
            let discovered=await tracking.snapshot()
            let selected=CalendarRaces.materialize(races,snapshot:snapshot).first{$0.id==f.liveRace}
            let autoSource=discovered.verification[f.liveRace]?.status=="andere_ausgabe" ? nil : discovered.links[f.liveRace]?.url
            let source=snapshot.session.liveLinks[f.liveRace] ?? autoSource ?? selected.flatMap{InlineResults.allowed($0.sourceURL) ? $0.sourceURL : nil} ?? ""
            let wants=selected != nil && (f.section=="live" || f.detail==f.liveRace)
            let payload=wants ? await resultCache.fetch(source,year:selected?.year) : nil
            let html=ActionForms.render(ui.page(filters:f,state:snapshot,sessionID:sessionID,autoTracking:discovered,livePayload:payload),csrf:codec.csrf(sessionID))
            return withCookies(response(html),snapshot.session)
        }
        router.get("/",use:handler)
        router.post("/",use:handler)
        router.get("/health") {_,_ -> Response in response("TrailAtlas Hummingbird: OK",mime:"text/plain; charset=utf-8")}
        router.get("/api/races") {_,_ -> Response in
            let snapshot=await store.snapshot("")
            let current=CalendarRaces.materialize(races,snapshot:snapshot)
            let json=try JSONEncoder().encode(current)
            return response(String(decoding:json,as:UTF8.self),mime:"application/json; charset=utf-8")
        }
        router.get("/api/status") {_,_ -> Response in
            let snapshot=await store.snapshot("");let links=await tracking.snapshot()
            let object:[String:Any]=["races":races.count,"automaticDates":snapshot.automaticDates.count,"dateSources":snapshot.sources.count,"lastDateScan":snapshot.lastScan,"dateScanRunning":snapshot.isScanning,"trackingSources":links.links.count,"racesSearched":links.checkedCount,"lastTrackingScan":links.lastAttempt,"trackingScanRunning":links.running,"trackingError":links.lastError,"durablePublicDataConfigured":env["SHARED_DATA_BASE_URL"] != nil,"durablePersonalCookiesConfigured":env["SESSION_SECRET"] != nil,"browserJavaScript":false]
            let data=try JSONSerialization.data(withJSONObject:object,options:[.sortedKeys])
            return response(String(decoding:data,as:UTF8.self),mime:"application/json; charset=utf-8")
        }
        router.get("/live-image") {request,_ -> Response in
            let id=request.uri.queryParameters.get("race",as:String.self) ?? ""
            let links=await tracking.snapshot()
            guard races.contains(where:{$0.id==id}),let url=links.links[id]?.url,
                  let bytes=await screenshots.shot(raceID:id,url:url) else{return response("Momentaufnahme nicht verfügbar",status:.notFound)}
            return Response(status:.ok,headers:[.contentType:"image/png",.cacheControl:"no-store"],body:.init(byteBuffer:ByteBuffer(bytes:bytes)))
        }
        router.get("/export") {request,_ -> Response in
            let jar=cookies(request),id=jar["trail_session"] ?? ""
            if let saved=codec.decode(jar,id:id){await store.restore(saved,sessionID:id)}
            let snapshot=await store.snapshot(id),links=await tracking.snapshot()
            var f=Filters();f.page=25
            let html=ActionForms.render(ui.page(filters:f,state:snapshot,sessionID:id,autoTracking:links),csrf:codec.csrf(id))
            var result=response(html)
            result.headers[.contentDisposition]="attachment; filename=TrailAtlas.html"
            return result
        }
        let port=Int(env["PORT"] ?? "10000") ?? 10000
        let app=Application(router:router,configuration:.init(address:.hostname("0.0.0.0",port:port)))
        let refresher=Task {
            guard env["DISABLE_BACKGROUND"] != "1" else{return}
            while !Task.isCancelled {
                await shared.sync(store:store,tracking:tracking)
                await store.scanIfDue()
                let current=await store.snapshot("")
                await tracking.updateRaces(CalendarRaces.materialize(races,snapshot:current))
                await tracking.discoverIfDue()
                do{try await Task.sleep(for:.seconds(96*60))}catch{break}
            }
        }
        defer{refresher.cancel()}
        try await app.runService()
    }
}
