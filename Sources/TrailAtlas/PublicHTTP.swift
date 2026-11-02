import Foundation
import FoundationNetworking
import Dispatch
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

struct PublicPage: Sendable {
    let data:Data
    let url:String
    let status:Int
    let contentType:String
}
enum PublicHTTP {
    static func validURL(_ raw:String) -> URL? {
        guard raw.count<=2000, let u=URLComponents(string:raw),u.scheme=="https",
              u.user==nil,u.password==nil,u.port==nil || u.port==443,
              let host=u.host?.lowercased(),host.contains("."),
              host.range(of:#"^[a-z0-9][a-z0-9.-]+[a-z0-9]$"#,options:.regularExpression) != nil,
              !host.hasSuffix(".local"),!host.hasSuffix(".internal"),!host.hasSuffix(".localhost"),
              host != "localhost",host.range(of:#"^[\d.]+$"#,options:.regularExpression)==nil
        else { return nil }
        return u.url
    }
    static func publicAddress(_ raw:String) -> Bool {
        let ip=raw.lowercased()
        if ip.contains(":") {
            if ip=="::" || ip=="::1" || ip.hasPrefix("fc") || ip.hasPrefix("fd") || ip.hasPrefix("fe") || ip.hasPrefix("ff") || ip.hasPrefix("::ffff:") {return false}
            return ip.hasPrefix("2") || ip.hasPrefix("3")
        }
        let p=ip.split(separator:".").compactMap{Int($0)}
        guard p.count==4,p.allSatisfy({0...255 ~= $0}) else{return false}
        if [0,10,127].contains(p[0]) || p[0]>=224{return false}
        if p[0]==169 && p[1]==254 || p[0]==172 && (16...31).contains(p[1]) || p[0]==192 && p[1]==168{return false}
        if p[0]==100 && (64...127).contains(p[1]) || p[0]==198 && [18,19].contains(p[1]) {return false}
        if p[0]==192 && [0,2].contains(p[1]) || p[0]==198 && p[1]==51 || p[0]==203 && p[1]==0 && p[2]==113{return false}
        return true
    }
    static func publicAddresses(_ host:String) -> [String] {
        var hints=addrinfo();hints.ai_family=AF_UNSPEC
        var res:UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host,"443",&hints,&res)==0,let first=res else{return []}
        defer{freeaddrinfo(first)}
        var result=Set<String>();var node:UnsafeMutablePointer<addrinfo>?=first
        while let entry=node {
            var name=[CChar](repeating:0,count:Int(NI_MAXHOST))
            if getnameinfo(entry.pointee.ai_addr,entry.pointee.ai_addrlen,&name,socklen_t(name.count),nil,0,NI_NUMERICHOST)==0 {
                let address=String(cString:name)
                guard publicAddress(address) else{return []}
                result.insert(address)
            }
            node=entry.pointee.ai_next
        }
        return result.sorted{a,b in !a.contains(":") && b.contains(":")}
    }
    /// curl bounds time and response size before buffering. DNS is resolved and
    /// pinned for untrusted custom sources; redirects are validated individually.
    static func fetch(_ raw:String, trusted:Bool=false, maxBytes:Int=2_000_000, headers:[String:String]=[:]) async throws -> PublicPage {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos:.utility).async {
                do {continuation.resume(returning:try fetchBlocking(raw,trusted:trusted,maxBytes:maxBytes,headers:headers))}
                catch {continuation.resume(throwing:error)}
            }
        }
    }
    private static func fetchBlocking(_ raw:String,trusted:Bool,maxBytes:Int,headers:[String:String]) throws -> PublicPage {
            var target=raw
            for _ in 0..<4 {
                guard let url=validURL(target),let host=url.host else{throw URLError(.badURL)}
                let addresses=publicAddresses(host)
                guard trusted || !addresses.isEmpty else{throw URLError(.cannotFindHost)}
                let folder=FileManager.default.temporaryDirectory.appendingPathComponent("trail-http-"+UUID().uuidString)
                try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
                defer{try? FileManager.default.removeItem(at:folder)}
                let body=folder.appendingPathComponent("body"),headerFile=folder.appendingPathComponent("headers")
                let p=Process();p.executableURL=URL(fileURLWithPath:"/usr/bin/curl")
                var args=["--silent","--show-error","--proto","=https","--connect-timeout","5","--max-time","16","--max-filesize",String(maxBytes),"--user-agent","TrailAtlas/2.0 (public event calendar)","--dump-header",headerFile.path,"--output",body.path]
                if let address=addresses.first {args += ["--resolve",host+":443:"+(address.contains(":") ? "["+address+"]" : address)]}
                for (name,value) in headers where !name.contains("\n") && !value.contains("\n") && !value.contains("\r") {args += ["--header",name+": "+value]}
                args += [url.absoluteString]
                p.arguments=args;p.standardOutput=FileHandle.nullDevice;p.standardError=FileHandle.nullDevice
                try p.run();p.waitUntilExit()
                guard p.terminationStatus==0 else{throw URLError(.cannotLoadFromNetwork)}
                let text=try String(contentsOf:headerFile,encoding:.utf8)
                let lines=text.components(separatedBy:.newlines)
                let status=lines.filter{$0.hasPrefix("HTTP/")}.last.flatMap{$0.split(separator:" ").dropFirst().first}.flatMap{Int($0)} ?? 0
                func header(_ key:String)->String {
                    lines.last{$0.lowercased().hasPrefix(key.lowercased()+":")}.map{String($0.dropFirst(key.count+1)).trimmingCharacters(in:.whitespacesAndNewlines)} ?? ""
                }
                if (300..<400).contains(status),let next=URL(string:header("location"),relativeTo:url)?.absoluteURL {
                    guard validURL(next.absoluteString) != nil else{throw URLError(.redirectToNonExistentLocation)}
                    // A trusted provider cannot redirect a server request to an
                    // arbitrary host. Custom sources must pass DNS validation.
                    if trusted && next.host != host && next.host != "www."+host && "www."+(next.host ?? "") != host {throw URLError(.httpTooManyRedirects)}
                    target=next.absoluteString;continue
                }
                let data=try Data(contentsOf:body)
                guard data.count<=maxBytes else{throw URLError(.dataLengthExceedsMaximum)}
                return PublicPage(data:data,url:url.absoluteString,status:status,contentType:header("content-type"))
            }
            throw URLError(.httpTooManyRedirects)
    }
}
