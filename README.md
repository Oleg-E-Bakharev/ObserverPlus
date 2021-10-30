# ObserverPlus
Шаблон проектирования Наблюдатель.
Расширенные фичи доставки уведомлений.
На данный момент добавлена возможность доставлять уведомление на указанную очередь.
Покрытие тестами 100%

Штатный способ подключения - Swift Package Manager
https://github.com/Oleg-E-Bakharev/ObserverPlus

Использует
https://github.com/Oleg-E-Bakharev/SwiftObserver

# Примеры использования

```swift
import XCTest
import ObserverPlus

private protocol Subject {
    var eventVoid: Event<Void> { get }
}

private final class Emitter: Subject {
    private var voidSender = EventSender<Void>()
    var eventVoid: Event<Void> { voidSender.event }

    func sendVoid() -> Bool {
        voidSender.send()
    }
}

private final class Handler {
    var isHandledVoid = false
    func onVoid() { // or func onVoid(_: Void)
        isHandledVoid = true
    }
}

final class DispatchObserverTests: XCTestCase {
    func testVoidOnQueue() throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        s.eventVoid += DispatchObserver(target: h, action: Handler.onVoid, queue: .main)
        XCTAssertFalse(h.isHandledVoid)
        e.sendVoid()
        let exp = expectation(description: "")

        DispatchQueue.main.async {
            XCTAssertTrue(h.isHandledVoid)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}
```
