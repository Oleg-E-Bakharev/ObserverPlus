//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

import Foundation
@_exported import SwiftObserver

/// Наблюдатель события, доставляющий уведомления методу класса.
/// Если указать queue, доставка осуществится на указанной DispatchQueue
public final class DispatchObserver<Target: AnyObject, Parameter> : EventObserver<Parameter> {
    public typealias Action = (Target) -> (Parameter) -> Void
    public typealias VoidAction = (Target) -> () -> Void

    weak var target: Target?
    let action: Action?
    let voidAction: VoidAction?
    let queue: DispatchQueue?

    public init(target: Target?, action: @escaping Action, queue: DispatchQueue? = nil) {
        self.target = target
        self.action = action
        self.voidAction = nil
        self.queue = queue
    }

    public init(target: Target?, action: @escaping VoidAction, queue: DispatchQueue? = nil) where Parameter == Void {
        self.target = target
        self.action = nil
        self.voidAction = action
        self.queue = queue
    }

    public override func handle(_ value: Parameter) -> Bool {
        guard let target = target else { return false }
        let callBlock = {
            if let action = self.action {
                action(target)(value)
            } else {
                self.voidAction?(target)()
            }
        }

        if let queue = queue {
            queue.async {
                callBlock()
            }
        } else {
            callBlock()
        }
        return true
    }
}

// MARK: -
/// Посредник (Mediator) для создания обнуляемой связи к постоянному объекту.
public extension DispatchObserver {
    final class Link {
        public typealias Action = (Target) -> (Parameter) -> Void
        public typealias VoidAction = (Target) -> () -> Void

        weak var target: Target?
        let action: Action?
        let voidAction: VoidAction?
        let queue: DispatchQueue?

        public init(target: Target?, action: @escaping Action, queue: DispatchQueue? = nil) {
            self.target = target
            self.action = action
            self.voidAction = nil
            self.queue = queue
        }

        public init(target: Target?, action: @escaping VoidAction, queue: DispatchQueue? = nil) where Parameter == Void {
            self.target = target
            self.action = nil
            self.voidAction = action
            self.queue = queue
        }

        func forward(_ value: Parameter) -> Void {
            guard let target = target else { return }
            let callBlock = {
                if let action = self.action {
                    action(target)(value)
                } else {
                    self.voidAction?(target)()
                }
            }

            if let queue = queue {
                queue.async {
                    callBlock()
                }
            } else {
                callBlock()
            }
            return
        }
    }
}

// MARK: -
public extension EventProtocol {
    /// Добавления обнуляемой связи к постоянному объекту. Если link удалится, то связь безопасно порвётся.
    static func +=<Target> (event: Self, link: DispatchObserver<Target, Parameter>.Link) {
        typealias Link = DispatchObserver<Target, Parameter>.Link
        event += Observer(target: link, action: Link.forward)
    }
}
