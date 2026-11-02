import Foundation
import Crypto
import CZlib

/// Personal state survives a sleeping/recreated free instance. Authenticated,
/// encrypted, HttpOnly cookies are the durable copy; no personal state is public.
struct SessionCodec: Sendable {
    private let material:Data
    private var key:SymmetricKey {SymmetricKey(data:material)}
    static let chunks = 4
    static let chunkSize = 3400
    init(secret: String?) {
        let bytes = secret.map { Data(SHA256.hash(data: Data($0.utf8))) }
            ?? Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        material = bytes
    }
    func csrf(_ sessionID: String) -> String {
        Data(HMAC<SHA256>.authenticationCode(for: Data(("csrf:"+sessionID).utf8), using: key)).base64EncodedString()
    }
    func validCSRF(_ value: String, sessionID: String) -> Bool {
        guard let bytes=Data(base64Encoded:value) else { return false }
        return HMAC<SHA256>.isValidAuthenticationCode(bytes, authenticating:Data(("csrf:"+sessionID).utf8), using:key)
    }
    private func compress(_ data:Data) -> Data? {
        var length=compressBound(uLong(data.count))
        var output=Data(count:Int(length))
        let status=output.withUnsafeMutableBytes { out in data.withUnsafeBytes { input in
            compress2(out.bindMemory(to:Bytef.self).baseAddress, &length,
                      input.bindMemory(to:Bytef.self).baseAddress, uLong(data.count), Z_BEST_SPEED)
        }}
        guard status == Z_OK else { return nil }
        output.count=Int(length); return output
    }
    private func decompress(_ data:Data) -> Data? {
        var length:uLongf=131072
        var output=Data(count:Int(length))
        let status=output.withUnsafeMutableBytes { out in data.withUnsafeBytes { input in
            uncompress(out.bindMemory(to:Bytef.self).baseAddress, &length,
                       input.bindMemory(to:Bytef.self).baseAddress, uLong(data.count))
        }}
        guard status == Z_OK else { return nil }
        output.count=Int(length); return output
    }
    func encode(_ session: Session, id:String) -> [String]? {
        guard let json=try? JSONEncoder().encode(session), let compressed=compress(json),
              let sealed=try? AES.GCM.seal(compressed, using:key, authenticating:Data(id.utf8)),
              let combined=sealed.combined else { return nil }
        let value=combined.base64EncodedString().replacingOccurrences(of:"+",with:"-").replacingOccurrences(of:"/",with:"_")
        guard value.count <= Self.chunks*Self.chunkSize else { return nil }
        return stride(from:0,to:value.count,by:Self.chunkSize).map { offset in
            String(value.dropFirst(offset).prefix(Self.chunkSize))
        }
    }
    func decode(_ cookies:[String:String], id:String) -> Session? {
        let raw=(0..<Self.chunks).map { cookies["trail_state_\($0)"] ?? "" }.joined()
            .replacingOccurrences(of:"-",with:"+").replacingOccurrences(of:"_",with:"/")
        guard raw.count <= Self.chunks*Self.chunkSize, let data=Data(base64Encoded:raw),
              let box=try? AES.GCM.SealedBox(combined:data),
              let compressed=try? AES.GCM.open(box,using:key,authenticating:Data(id.utf8)),
              let json=decompress(compressed) else { return nil }
        return try? JSONDecoder().decode(Session.self,from:json)
    }
}

/// Converts legacy action links into POST forms without changing their CSS.
/// Browsing, refresh, prefetch and crawlers can no longer repeat a mutation.
enum ActionForms {
    static func render(_ html:String, csrf:String) -> String {
        let re=try! NSRegularExpression(pattern:#"<a\b([^>]*?)href="([^"]+)"([^>]*)>(.*?)</a>"#, options:[.dotMatchesLineSeparators,.caseInsensitive])
        var result=html
        let ns=html as NSString
        for m in re.matches(in:html,range:NSRange(location:0,length:ns.length)).reversed() {
            let href=ns.substring(with:m.range(at:2)).replacingOccurrences(of:"&amp;",with:"&")
            guard let u=URLComponents(string:href),u.path=="/",u.queryItems?.contains(where:{$0.name=="action"}) == true else {continue}
            var attrs=ns.substring(with:m.range(at:1))+ns.substring(with:m.range(at:3))
            attrs=attrs.replacingOccurrences(of:#"\s*role="[^"]*""#,with:"",options:.regularExpression)
            let fields=(u.queryItems ?? []).map{"<input type=\"hidden\" name=\"\(esc($0.name))\" value=\"\(esc($0.value ?? ""))\">"}.joined()
            let form="<form method=\"post\" action=\"/\" style=\"display:contents\">\(fields)<input type=\"hidden\" name=\"csrf\" value=\"\(esc(csrf))\"><button type=\"submit\" \(attrs)>\(ns.substring(with:m.range(at:4)))</button></form>"
            result=(result as NSString).replacingCharacters(in:m.range,with:form)
        }
        result=result.replacingOccurrences(of:"@@CSRF@@",with:esc(csrf))
        return result
    }
}
