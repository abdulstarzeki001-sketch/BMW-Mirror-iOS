import Foundation
import Network
import Darwin

struct LiveHLSServerStatistics {
    let totalRequests: Int
    let playlistRequests: Int
    let mediaRequests: Int
    let externalClientRequests: Int
    let bytesServed: Int
    let lastClientEndpoint: String
    let lastRequestPath: String
}

final class LiveHLSHTTPServer {
    var onReady: ((URL) -> Void)?
    var onError: ((Error) -> Void)?
    var onStatistics: ((LiveHLSServerStatistics) -> Void)?

    private let store: LiveHLSStore
    private let requestedPort: NWEndpoint.Port
    private let queue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.hls-http",
        qos: .userInitiated
    )
    private let statsLock = NSLock()

    private var listener: NWListener?
    private var advertisedHost: String?
    private var totalRequests = 0
    private var playlistRequests = 0
    private var mediaRequests = 0
    private var externalClientRequests = 0
    private var bytesServed = 0
    private var lastClientEndpoint = "—"
    private var lastRequestPath = "—"

    init(
        store: LiveHLSStore,
        port: NWEndpoint.Port = .any
    ) {
        self.store = store
        self.requestedPort = port
    }

    func start() {
        guard listener == nil else { return }

        resetStatistics()

        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true

            let listener = try NWListener(
                using: parameters,
                on: requestedPort
            )
            self.listener = listener

            listener.stateUpdateHandler = { [weak self, weak listener] state in
                guard let self else { return }

                switch state {
                case .ready:
                    guard let port = listener?.port else { return }

                    let host = Self.preferredLocalIPv4Address() ?? "127.0.0.1"
                    self.advertisedHost = host

                    if let url = URL(
                        string: "http://\(host):\(port.rawValue)/master.m3u8"
                    ) {
                        self.onReady?(url)
                    }

                case .failed(let error):
                    self.onError?(error)
                    self.stop()

                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection)
            }

            listener.start(queue: queue)
        } catch {
            onError?(error)
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        advertisedHost = nil
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)

        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 64 * 1024
        ) { [weak self, weak connection] data, _, _, error in
            guard
                let self,
                let connection
            else {
                return
            }

            if let error {
                connection.cancel()
                self.onError?(error)
                return
            }

            guard
                let data,
                let request = String(data: data, encoding: .utf8),
                let requestLine = request.components(separatedBy: "\r\n").first
            else {
                self.sendNotFound(on: connection)
                return
            }

            let parts = requestLine.split(separator: " ")
            guard parts.count >= 2 else {
                self.sendNotFound(on: connection)
                return
            }

            let method = String(parts[0]).uppercased()
            let rawTarget = String(parts[1])
            let path: String

            if let absoluteURL = URL(string: rawTarget),
               absoluteURL.scheme != nil {
                let components = URLComponents(
                    url: absoluteURL,
                    resolvingAgainstBaseURL: false
                )

                path = components?.percentEncodedPath.isEmpty == false
                    ? components!.percentEncodedPath
                    : "/"
            } else {
                path = rawTarget
            }

            let clientEndpoint = String(describing: connection.endpoint)
            let remoteHost = self.remoteHost(from: connection.endpoint)

            guard let response = self.store.response(for: path) else {
                self.recordRequest(
                    path: path,
                    clientEndpoint: clientEndpoint,
                    remoteHost: remoteHost,
                    bytes: 0
                )
                self.sendNotFound(on: connection)
                return
            }

            let rangeHeader = request
                .components(separatedBy: "\r\n")
                .first {
                    $0.lowercased().hasPrefix("range:")
                }

            let fullData = response.data
            let range = rangeHeader.flatMap {
                self.parseByteRange(
                    from: $0,
                    dataCount: fullData.count
                )
            }

            let body: Data
            let status: String
            var extraHeaders = [
                "Accept-Ranges: bytes"
            ]

            if let range {
                body = Data(fullData[range])
                status = "206 Partial Content"
                extraHeaders.append(
                    "Content-Range: bytes \(range.lowerBound)-\(range.upperBound)/\(fullData.count)"
                )
            } else {
                body = fullData
                status = "200 OK"
            }

            self.recordRequest(
                path: path,
                clientEndpoint: clientEndpoint,
                remoteHost: remoteHost,
                bytes: body.count
            )

            self.send(
                status: status,
                contentType: response.contentType,
                body: body,
                extraHeaders: extraHeaders,
                includeBody: method != "HEAD",
                on: connection
            )
        }
    }

    private func recordRequest(
        path: String,
        clientEndpoint: String,
        remoteHost: String?,
        bytes: Int
    ) {
        statsLock.lock()

        totalRequests += 1
        bytesServed += max(bytes, 0)
        lastClientEndpoint = clientEndpoint
        lastRequestPath = path

        if path.contains(".m3u8") {
            playlistRequests += 1
        } else if path.contains(".m4s") || path.contains("init.mp4") {
            mediaRequests += 1
        }

        if let remoteHost, isLikelyExternalClient(host: remoteHost) {
            externalClientRequests += 1
        }

        let snapshot = statisticsLocked()
        statsLock.unlock()

        onStatistics?(snapshot)
    }

    private func isLikelyExternalClient(host: String) -> Bool {
        let normalized = host
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            .lowercased()

        if normalized == "127.0.0.1" || normalized == "::1" || normalized == "localhost" {
            return false
        }

        let localAddresses = Set(Self.allLocalIPv4Addresses())
        if localAddresses.contains(normalized) {
            return false
        }

        if let advertisedHost, normalized == advertisedHost.lowercased() {
            return false
        }

        return true
    }

    private func remoteHost(from endpoint: NWEndpoint) -> String? {
        guard case let .hostPort(host, _) = endpoint else {
            return nil
        }

        return String(describing: host)
    }

    private func sendNotFound(on connection: NWConnection) {
        send(
            status: "404 Not Found",
            contentType: "text/plain; charset=utf-8",
            body: Data("Not Found".utf8),
            extraHeaders: [],
            includeBody: true,
            on: connection
        )
    }

    private func send(
        status: String,
        contentType: String,
        body: Data,
        extraHeaders: [String],
        includeBody: Bool,
        on connection: NWConnection
    ) {
        var headerLines = [
            "HTTP/1.1 \(status)",
            "Content-Type: \(contentType)",
            "Content-Length: \(body.count)",
            "Cache-Control: no-store, no-cache, must-revalidate",
            "Access-Control-Allow-Origin: *",
            "Connection: close"
        ]

        headerLines.append(contentsOf: extraHeaders)

        let header =
            headerLines.joined(separator: "\r\n")
            + "\r\n\r\n"

        var response = Data(header.utf8)

        if includeBody {
            response.append(body)
        }

        connection.send(
            content: response,
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }

    private func parseByteRange(
        from header: String,
        dataCount: Int
    ) -> ClosedRange<Int>? {
        guard dataCount > 0 else { return nil }

        let lower = header.lowercased()
        guard let marker = lower.range(of: "bytes=") else {
            return nil
        }

        let value = lower[marker.upperBound...]
            .trimmingCharacters(in: .whitespaces)

        let parts = value.split(
            separator: "-",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        guard !parts.isEmpty else { return nil }

        let start = Int(parts[0]) ?? 0
        let requestedEnd: Int?

        if parts.count > 1, !parts[1].isEmpty {
            requestedEnd = Int(parts[1])
        } else {
            requestedEnd = nil
        }

        guard start >= 0, start < dataCount else {
            return nil
        }

        let end = min(
            requestedEnd ?? (dataCount - 1),
            dataCount - 1
        )

        guard end >= start else { return nil }
        return start...end
    }

    private func resetStatistics() {
        statsLock.lock()
        totalRequests = 0
        playlistRequests = 0
        mediaRequests = 0
        externalClientRequests = 0
        bytesServed = 0
        lastClientEndpoint = "—"
        lastRequestPath = "—"
        let snapshot = statisticsLocked()
        statsLock.unlock()

        onStatistics?(snapshot)
    }

    private func statisticsLocked() -> LiveHLSServerStatistics {
        LiveHLSServerStatistics(
            totalRequests: totalRequests,
            playlistRequests: playlistRequests,
            mediaRequests: mediaRequests,
            externalClientRequests: externalClientRequests,
            bytesServed: bytesServed,
            lastClientEndpoint: lastClientEndpoint,
            lastRequestPath: lastRequestPath
        )
    }

    static func preferredLocalIPv4Address() -> String? {
        let addresses = localIPv4AddressPairs()

        if let wifi = addresses.first(where: { $0.name == "en0" }) {
            return wifi.address
        }

        return addresses.first?.address
    }

    private static func allLocalIPv4Addresses() -> [String] {
        localIPv4AddressPairs().map(\.address)
    }

    private static func localIPv4AddressPairs() -> [(name: String, address: String)] {
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfacePointer) == 0,
              let firstInterface = interfacePointer else {
            return []
        }

        defer {
            freeifaddrs(interfacePointer)
        }

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstInterface
        var results: [(name: String, address: String)] = []

        while let current = pointer {
            let interface = current.pointee
            pointer = interface.ifa_next

            guard let address = interface.ifa_addr else {
                continue
            }

            guard address.pointee.sa_family == UInt8(AF_INET) else {
                continue
            }

            let name = String(cString: interface.ifa_name)
            guard name != "lo0" else {
                continue
            }

            var hostname = [CChar](
                repeating: 0,
                count: Int(NI_MAXHOST)
            )

            let result = getnameinfo(
                address,
                socklen_t(address.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            guard result == 0 else {
                continue
            }

            results.append(
                (
                    name: name,
                    address: String(cString: hostname)
                )
            )
        }

        return results
    }
}
