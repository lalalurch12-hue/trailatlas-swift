import Foundation
@main struct CheckTracking {
 static func main() async throws {
  let root=URL(fileURLWithPath:CommandLine.arguments[1]);let path=root.appendingPathComponent("Resources")
  let races=try JSONDecoder().decode([Race].self,from:Data(contentsOf:path.appendingPathComponent("races.json")))
  let seeds=try JSONDecoder().decode([TrackingLink].self,from:Data(contentsOf:path.appendingPathComponent("tracking_verified.json")))
  let found=Set(races.map(\.id));precondition(seeds.count>=4 && seeds.allSatisfy{found.contains($0.raceID)})
  let tracker=TrackingDiscovery(races:races,seeds:seeds,directory:"/tmp/trailatlas-tracking-"+UUID().uuidString)
  let snap=await tracker.snapshot();precondition(snap.links.count==seeds.count)
  let javelina=races.first{$0.id=="old-0198"}!
  let matching="""
  <rss version="2.0"><channel><item><title>Javelina Jundred 2026 Live Tracking Results</title><link>https://live.aravaiparunning.com/javelina-jundred/2026</link><description>Javelina Jundred 2026 tracking</description></item></channel></rss>
  """
  let m=TrackingMatcher.matchesRSS(matching,race:javelina)
  precondition(m?.provider=="Aravaipa Live", "Correct race/year/provider should match")
  precondition(TrackingMatcher.matchesRSS(matching.replacingOccurrences(of:"2026",with:"2025"),race:javelina)==nil)
  precondition(TrackingMatcher.matchesRSS(matching.replacingOccurrences(of:"aravaiparunning.com",with:"scam.example"),race:javelina)==nil)
  precondition(TrackingMatcher.matchesRSS(matching.replacingOccurrences(of:"javelina-jundred",with:"other-race").replacingOccurrences(of:"Javelina Jundred",with:"Other Race"),race:javelina)==nil)
  precondition(TrackingMatcher.provider("http://live.utmb.world/kullamannen/2026")==nil)
  print("PASS verified seed ids and conservative RSS event/year/provider matching")
 }
}
