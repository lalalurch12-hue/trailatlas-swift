import Foundation
@main struct Check {
 static func main() async throws {
  let root=URL(fileURLWithPath:CommandLine.arguments[1]);let res=root.appendingPathComponent("Resources")
  let races=try JSONDecoder().decode([Race].self,from:Data(contentsOf:res.appendingPathComponent("races.json")))
  let sources=try JSONDecoder().decode([RaceSource].self,from:Data(contentsOf:res.appendingPathComponent("sources.json")))
  precondition(races.count == 352)
  precondition(Set(races.map{$0.countryName}).count == 65)
  precondition(races.filter{$0.category=="elite" || $0.category=="series"}.count==225)
  precondition(sources.count==10)
  var search=Filters();search.q="Oberaudorf"
  precondition(races.filter{search.matches($0,favorites:[])}.count>=1)
  var elite=Filters();elite.elite=true
  precondition(races.filter{elite.matches($0,favorites:[])}.count==225)
  var tba=Filters();tba.tba=true
  precondition(races.filter{tba.matches($0,favorites:[])}.count>=60)
  let hurt=races.first{$0.name=="HURT 100"}!
  precondition(hurt.distancesKM.contains{abs($0-160.9344)<0.01},"German mile units must be converted; elevation is not race distance")
  let vtrail=races.first{$0.name=="V Trail – Vang Vieng"}!
  precondition(Set(vtrail.distancesKM)==Set([10.0,18.0,30.0,50.0]),"A shared km suffix applies to all courses")
  let korea=races.first{$0.name=="Trans Korea 622K"}!
  precondition(korea.distancesKM.contains(622),"Ultras beyond 500 km must remain filterable")
  let moab=races.first{$0.name=="Moab Trail Marathon / USATF Trail-Halbmarathon"}!
  precondition(moab.distancesKM.contains(21.0975) && moab.distancesKM.contains(42.195))
  let tmp="/tmp/trailatlas_test_"+UUID().uuidString
  let store=TrailStore(directory:tmp,sources:sources)
  let session="visitor"
  await store.toggleFavorite(races[0].id,sessionID:session)
  let afterFav = await store.snapshot(session)
  precondition(afterFav.session.favorites.contains(races[0].id))
  await store.saveLive(races[0].id,url:"https://my.raceresult.com/123456/",sessionID:session)
  let afterLive = await store.snapshot(session)
  precondition(afterLive.session.liveLinks[races[0].id] != nil)
  await store.addSource(name:"Custom race",url:"https://example.org/",sessionID:session)
  let afterSource = await store.snapshot(session)
  precondition(afterSource.session.customSources.count==1)
  let recovered=TrailStore(directory:tmp,sources:sources)
  let recoveredState = await recovered.snapshot(session)
  precondition(recoveredState.session.liveLinks[races[0].id] != nil)
  let f=TrailStore.extractDates("<html><p>Race weekend on 2027-06-25 – trail ultra</p></html>",source:sources[0])
  precondition(f.count==1 && f[0].start=="2027-06-25")
  print("PASS 352 races / 65 countries / 225 elite+series / search / filters / persisted favorites and live links / candidate extractor")
  try? FileManager.default.removeItem(atPath:tmp)
 }
}
