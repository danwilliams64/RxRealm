
import UIKit
import RealmSwift

let formatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .long
    return f
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        //reset the realm on each app launch
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }

        return true
    }
    
}
