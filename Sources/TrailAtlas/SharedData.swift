import Foundation

/// A dedicated data branch holds public source findings. GitHub Actions can
/// refresh it even while a free Render instance sleeps. Personal cookies and
/// sessions are never written to this public snapshot.
actor SharedData {
    let base:String?
    private var last:Date?
    init(base:String?) {
        if let base,let url=PublicHTTP.validURL(base),url.host=="raw.githubusercontent.com" {
            self.base=base.trimmingCharacters(in:CharacterSet(charactersIn:"/"))
        }else{self.base=nil}
    }
    func sync(store:TrailStore,tracking:TrackingDiscovery) async {
        guard let base,last.map({Date().timeIntervalSince($0)>300}) ?? true else{return}
        last=Date()
        if let response=try? await PublicHTTP.fetch(base+"/public-state.json",trusted:true),response.status==200 {
            await store.ingest(response.data)
        }
        if let response=try? await PublicHTTP.fetch(base+"/tracking-discovery.json",trusted:true),response.status==200 {
            await tracking.ingest(response.data)
        }
    }
}
