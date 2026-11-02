import Foundation
@main struct ApprovedDateTest {
    static func main() throws {
        let root=URL(fileURLWithPath: CommandLine.arguments[1])
        let resources=root.appendingPathComponent("Resources")
        let races=try JSONDecoder().decode([Race].self,from: Data(contentsOf:resources.appendingPathComponent("races.json")))
        let html=try String(contentsOf:resources.appendingPathComponent("template.html"),encoding:.utf8)
        let ui=TrailUI(template:html,races:races)
        var s=Session()
        s.approved["oberaudorf-otf"]="2027-10-16"
        let snap=Snapshot(session:s,findings:[],checks:[],lastScan:"",isScanning:false,sources:[])
        let tracking=TrackingSnapshot(links:[:],verification:[:],checkedCount:0,lastAttempt:"",lastError:"",running:false)
        var october=Filters();october.month=10;october.year="2027"
        let filtered=ui.page(filters:october,state:snap,sessionID:"test",autoTracking:tracking)
        precondition(filtered.contains("Oberaudorf Trail Festival (OTF) 2027"),"Approved date should enter October filter")
        precondition(filtered.contains("16. Oktober 2027"),"Approved date should appear on updated race card")
        precondition(filtered.contains("Oktober 2027"),"Approved date should change month grouping")
        precondition(!filtered.contains("30. September 2027"),"Original date should disappear from filtered view")
        var september=Filters();september.month=9;september.year="2027"
        let sep=ui.page(filters:september,state:snap,sessionID:"test",autoTracking:tracking)
        precondition(!sep.contains("<h4 class=\"event-name\">Oberaudorf Trail Festival (OTF) 2027</h4>"),"Approved date should leave September filter")
        print("PASS: approved new date replaces calendar card, chronology and month filters")
    }
}
