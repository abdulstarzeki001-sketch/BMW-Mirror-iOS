import Foundation
import Network
import Darwin

final class LiveHLSHTTPServer {
    var onReady: ((URL) -> Void)?
    var onError: ((Error) -> Void)?

    private let store: LiveHLSStore
    private let queue = DispatchQueue(
        label: "com.abdulstar.bmwmirror.hls-http",
        qos: .userInitiated
    )

    private var listener: NWListener?

    init(store: LiveHLSStore) {
        self.store = store
    }

    func start() {
        guard listener == nil else { return }

        do {
            let listener = try NWListener(using: .tcp, on: .any)
            self.listener = listener

            listener.stateUpdateHandler = { [weak self, weak listener] state in
                guard let self else { return }

                switch state {
                case .ready:
                    guard let port = listener?.port else { return }

                    let host = self.localIPv4Address() ?? "127.0.0.1"
                    if let url = URL(
                        string: "http://\(host):\(port.rawValue)/live.m3u8"
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

            let path = String(parts[1])

            guard let response = self.store.response(for: path) else {
                self.sendNotFound(on: connection)
                return
            }

            self.send(
                status: "200 OK",
                contentType: response.contentType,
                body: response.data,
                on: connection
            )
        }
    }

    private func sendNotFound(on connection: NWConnection) {
        send(
            status: "404 Not Found",
            contentType: "text/plain; charset=utf-8",
            body: Data("Not Found".utf8),
            on: connection
        )
    }

    private func send(
        status: String,
        contentType: String,
        body: Data,
        on connection: NWConnection
    ) {
        let header = """
        HTTP/1.1 \(status)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.count)\r
        Cache-Control: no-store, no-cache, must-revalidate\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r
        """

        var response = Data(header.utf8)
        response.append(body)

        connection.send(
            content: response,
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }

    private func localIPv4Address() -> String? {
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfacePointer) == 0,
              let firstInterface = interfacePointer else {
            return nil
        }

        defer {
            freeifaddrs(interfacePointer)
        }

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstInterface
        var fallbackAddress: String?

        while let current = pointer {
            let interface = current.pointee

            defer {
                pointer = interface.ifa_next
            }

            guard let address = interface.ifa_addr else {
                continue
            }

            guard address.pointee.sa_family == UInt8(AF_INET) else {
                continue
            }

            let name = String(cString: interface.ifa_name)

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

            let value = String(cString: hostname)

            if name == "en0" {
                return value
            }

            if name != "lo0", fallbackAddress == nil {
                fallbackAddress = value
            }
        }

        return fallbackAddress
    }
}
