import AppKit
import Combine
import Foundation

@MainActor
final class WorkspaceActivityMonitor: ObservableObject {
    @Published private(set) var lastActivity: Date
    private var eventMonitor: Any?
    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init, observeEvents: Bool = true) {
        self.now = now
        self.lastActivity = now()
        if observeEvents {
            let mask: NSEvent.EventTypeMask = [
                .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown,
                .mouseMoved, .leftMouseDragged, .rightMouseDragged,
                .scrollWheel, .gesture, .magnify, .swipe,
            ]
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
                MainActor.assumeIsolated { self?.recordActivity() }
                return event
            }
        }
    }

    deinit {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
    }

    func recordActivity() {
        lastActivity = now()
    }

    func hasExceeded(minutes: Int, at date: Date? = nil) -> Bool {
        guard minutes > 0 else { return false }
        return (date ?? now()).timeIntervalSince(lastActivity) >= Double(minutes) * 60
    }
}
