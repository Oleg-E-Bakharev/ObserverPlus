import XCTest
import ObserverPlus

private protocol Subject {
    var eventVoid: Event<Void> { get }
    var eventInt: Event<Int> { get }
}

private final class Emitter {
    private var voidSender = EventSender<Void>()
    private var intSender = EventSender<Int>()

    @discardableResult
    func sendVoid() -> Bool {
        voidSender.send()
    }

    @discardableResult
    func sendInt(_ value: Int) -> Bool {
        intSender.send(value)
    }
}

extension Emitter: Subject {
    var eventVoid: Event<Void> { voidSender.event }
    var eventInt: Event<Int> { intSender.event }
}

private final class Handler {
    var isHandledVoid = false
    var isHandledInt = false
    func onVoid() {
        isHandledVoid = true
    }
    func onInt(_: Int) {
        isHandledInt = true
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

    func testIntOnQueue() throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        s.eventInt += DispatchObserver(target: h, action: Handler.onInt, queue: .main)
        XCTAssertFalse(h.isHandledVoid)
        e.sendInt(1)
        let exp = expectation(description: "")

        DispatchQueue.main.async {
            XCTAssertTrue(h.isHandledInt)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testVoidWithoutQueue() throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        s.eventVoid += DispatchObserver(target: h, action: Handler.onVoid)
        XCTAssertFalse(h.isHandledVoid)
        e.sendVoid()
        XCTAssertTrue(h.isHandledVoid)
    }

    func testDeadHandlerOnQueue() {
        let e = Emitter()
        let s: Subject = e
        var wh: Handler? = Handler()
        s.eventVoid += DispatchObserver(target: wh, action: Handler.onVoid, queue: .main)
        XCTAssertTrue(e.sendVoid())
        let exp = expectation(description: "")

        DispatchQueue.main.async {
            XCTAssertTrue(wh?.isHandledVoid ?? false)
            wh = nil
            XCTAssertFalse(e.sendVoid())
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }


    func testVoidLinkOnQueue() throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        var link: Any?
        do {
            let l = DispatchObserver.Link(target: h, action: Handler.onVoid, queue: .main)
            s.eventVoid += l
            link = l
        }
        XCTAssertFalse(h.isHandledVoid)
        XCTAssertTrue(e.sendVoid())
        let exp = expectation(description: "")

        DispatchQueue.main.async {
            XCTAssertTrue(h.isHandledVoid)
            link = nil
            XCTAssertFalse(e.sendVoid())
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testIntLinkOnQueue() throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        var link: Any?
        do {
            let l = DispatchObserver.Link(target: h, action: Handler.onInt, queue: .main)
            s.eventInt += l
            link = l
        }
        XCTAssertFalse(h.isHandledInt)
        XCTAssertTrue(e.sendInt(1))
        let exp = expectation(description: "")

        DispatchQueue.main.async {
            XCTAssertTrue(h.isHandledInt)
            link = nil
            XCTAssertFalse(e.sendInt(1))
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testVoidLinkWithoutQueue() throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        var link: Any?
        do {
            let l = DispatchObserver.Link(target: h, action: Handler.onVoid)
            s.eventVoid += l
            link = l
        }

        XCTAssertFalse(h.isHandledVoid)
        XCTAssertTrue(e.sendVoid())
        XCTAssertTrue(h.isHandledVoid)
        link = nil
        XCTAssertFalse(e.sendVoid())
    }

    func testIntLinkVoidWithoutQueue() throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        var link: Any?
        do {
            let l = DispatchObserver.Link(target: h, action: Handler.onInt)
            s.eventInt += l
            link = l
        }
        XCTAssertFalse(h.isHandledVoid)
        XCTAssertTrue(e.sendInt(1))
        XCTAssertTrue(h.isHandledInt)
        link = nil
        XCTAssertFalse(e.sendInt(1))
    }
}
