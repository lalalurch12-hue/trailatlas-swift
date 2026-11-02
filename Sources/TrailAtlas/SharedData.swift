import Foundation

/// A dedicated data branch holds public source findings. The forge's CI can
/// refresh it even while a free Render instance sleeps. Personal cookies and
/// sessions are never written to this public snapshot.
actor SharedData {
    let base:String?
    private var last:Date?
    init(base:String?) {
        if let base,let url=PublicHTTP.validURL(base),
           ["raw.githubusercontent.com","tangled.org"].contains(url.host ?? "") {
            self.base=base.trimmingCharacters(in:CharacterSet(charactersIn:"/"))
        }else{self.base=nil}
    }
    func sync(store:TrailStore,tracking:TrackingDiscovery) async {
        guard let base,last.map({Date().timeIntervalSince($0)>300}) ?? true else{return}
        last=Date()
        // Tangled's raw URLs redirect to api.tangled.org. Follow only validated
        // public HTTPS redirects, including DNS/IP checks on every target.
        let trusted=URL(string:base)?.host != "tangled.org"
        if let response=try? await PublicHTTP.fetch(base+"/public-state.json",trusted:trusted),response.status==200 {
            await store.ingest(response.data)
        }
        if let response=try? await PublicHTTP.fetch(base+"/tracking-discovery.json",trusted:trusted),response.status==200 {
            await tracking.ingest(response.data)
        }
    }
}
