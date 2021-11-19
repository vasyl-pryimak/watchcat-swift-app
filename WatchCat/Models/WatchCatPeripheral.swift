import UIKit
import CoreBluetooth

class WatchCatPeripheral: NSObject {
    
    ///  services and charcteristics Identifiers
    
    public static let watchCatServiceUUID     = CBUUID.init(string: "FFE0")
    public static let redLEDCharacteristicUUID   = CBUUID.init(string: "FFE1")
    
}
