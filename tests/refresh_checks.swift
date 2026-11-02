import Foundation
@main struct RefreshChecks {
 static func main() async throws {
  let root=URL(fileURLWithPath:CommandLine.arguments[1]);let res=root.appendingPathComponent("Resources")
  let races=try JSONDecoder().decode([Race].self,from:Data(contentsOf:res.appendingPathComponent("races.json")))
  let seeds=try JSONDecoder().decode([TrackingLink].self,from:Data(contentsOf:res.appendingPathComponent("tracking_verified.json")))
  precondition(races.count==352 && seeds.count>=4)
  let tmp=URL(fileURLWithPath:"/tmp/trailatlas-live-refresh-"+UUID().uuidString)
  try FileManager.default.createDirectory(at:tmp,withIntermediateDirectories:true)
  defer {try? FileManager.default.removeItem(at:tmp)}
  // Legacy state has no verification property: migration must preserve it.
  let updated=TrackingLink(raceID:seeds[0].raceID,url:"https://grindstone.v3.livetrail.net/en/2026/updated",provider:"LiveTrail",evidence:"verified update",verifiedOn:"2026-11-01")
  let legacy: [String:Any]=["links":[updated.raceID:["raceID":updated.raceID,"url":updated.url,"provider":updated.provider,"evidence":updated.evidence,"verifiedOn":updated.verifiedOn]],"checked":[updated.raceID:"2026-10-01T00:00:00Z"],"lastAttempt":"2026-10-01T00:00:00Z","lastError":"temporary"]
  let data=try JSONSerialization.data(withJSONObject:legacy)
  try data.write(to:tmp.appendingPathComponent("tracking-discovery.json"))
  let tracker=TrackingDiscovery(races:races,seeds:seeds,directory:tmp.path)
  let before=await tracker.snapshot()
  precondition(before.links.count==seeds.count)
  precondition(before.links[updated.raceID]?.url==updated.url,"Do not clobber newer links with original seeds")
  precondition(before.verification.isEmpty,"Legacy state must decode with missing verification")
  let verification=TrackingVerification(checkedAt:"2026-11-01T20:00:00Z",status:"nicht_gefunden",failedChecks:2,httpStatus:404)
  let encoded=try JSONEncoder().encode(verification)
  let decoded=try JSONDecoder().decode(TrackingVerification.self,from:encoded)
  precondition(decoded.failedChecks==2)
  let cn=races.first(where:{$0.name=="HLA POW Beijing Trail Challenge"})!
  let rss="""
  <rss version="2.0"><channel><item><title>2026 HLA POW Beijing Trail Challenge 实时成绩</title><link>https://werun.hk/game/hla-pow-beijing-2026</link></item></channel></rss>
  """
  precondition(TrackingMatcher.matchesRSS(rss,race:cn)?.provider=="WeRun")
  let old=rss.replacingOccurrences(of:"2026",with:"2025")
  precondition(TrackingMatcher.matchesRSS(old,race:cn)==nil,"Reject previous edition")
  precondition(TrackingMatcher.provider("https://private.example/2026")==nil)
  print("PASS legacy migration, seed preservation, status persistence, China/WeRun exact year match")
 }
}
