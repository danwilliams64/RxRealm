

//
//  RxRealmRealmTests.swift
//  RxRealm
//
//  Created by Marin Todorov on 5/22/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest

import RxSwift
import RealmSwift
import RxRealm
import RxTests

class RxRealmRealmTests: XCTestCase {
    private func realmInMemory(name: String) -> Realm {
        var conf = Realm.Configuration()
        conf.inMemoryIdentifier = name
        return try! Realm(configuration: conf)
    }
    
    func testRealmDidChangeNotifications() {
        let expectation1 = expectation(description: "Realm notification")
        
        let realm = realmInMemory(name: #function)
        let bag = DisposeBag()
        
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver((Realm, Notification).self)
        
        let realm$ = realm.asObservable().shareReplay(1)
        realm$.scan(0, accumulator: {acc, _ in return acc+1})
            .filter { $0 == 2 }.map {_ in ()}.subscribe(onNext: expectation1.fulfill).addDisposableTo(bag)
        realm$
            .subscribe(observer).addDisposableTo(bag)
        
        //interact with Realm here
        delay(delay: 0.1) {
            try! realm.write {
                realm.add(Message("first"))
            }
        }
        delayInBackground(delay: 0.3) {[unowned self] in
            let realm = self.realmInMemory(name: #function)
            try! realm.write {
                realm.add(Message("second"))
            }
        }
        
        scheduler.start()
        
        waitForExpectations(timeout: 0.5) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(observer.events.count, 2)
            XCTAssertEqual(observer.events[0].value.element!.1, Notification.didChange)
            XCTAssertEqual(observer.events[1].value.element!.1, Notification.didChange)
        }
    }
    
    func testRealmRefreshRequiredNotifications() {
        let expectation1 = expectation(description: "Realm notification")
        
        let realm = realmInMemory(name: #function)
        realm.autorefresh = false
        
        let bag = DisposeBag()
        
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver((Realm, Notification).self)
        
        let realm$ = realm.asObservable().shareReplay(1)
        realm$.scan(0, accumulator: {acc, _ in return acc+1})
            .filter { $0 == 1 }.map {_ in ()}.subscribe(onNext: expectation1.fulfill).addDisposableTo(bag)
        realm$
            .subscribe(observer).addDisposableTo(bag)
        
        //interact with Realm here from background
        delayInBackground(delay: 0.1) {[unowned self] in
            let realm = self.realmInMemory(name: #function)
            try! realm.write {
                realm.add(Message("second"))
            }
        }
        
        scheduler.start()
        
        waitForExpectations(timeout: 0.5) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(observer.events.count, 1)
            XCTAssertEqual(observer.events[0].value.element!.1, Notification.refreshRequired)
        }
    }

}
