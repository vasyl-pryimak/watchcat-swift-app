import Gifu
import UIKit
import CoreBluetooth
import UserNotifications

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    private var lastData: Data?;
    
    private var battChar: CBCharacteristic?
    private var catImg:GIFImageView!
    private var cleanCatImg:GIFImageView!
    
    var cnt: CGFloat = 0;
    private var timer: Timer!;
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    override func viewDidAppear(_ animated: Bool) {
        print("View appered")
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded")
        
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "BT_queue"))
        
        catImg = GIFImageView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        catImg.contentMode = .scaleAspectFit
        catImg.center = CGPoint(x:view.frame.size.width  / 2,
                                y:view.frame.size.height / 2);

        catImg.animate(withGIFNamed: "22cat")
        catImg.isHidden = true
        view.addSubview(catImg)
        
        cleanCatImg = GIFImageView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        cleanCatImg.contentMode = .scaleAspectFit
        cleanCatImg.center = CGPoint(x:view.frame.size.width  / 2,
                                y:view.frame.size.height / 2);

        cleanCatImg.animate(withGIFNamed: "22cat_clean")
        cleanCatImg.isHidden = true
        view.addSubview(cleanCatImg)
        
        view.sendSubviewToBack(catImg)
        view.sendSubviewToBack(cleanCatImg)
        
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]){(granted, error) in
            guard granted else {return}
            self.notificationCenter.getNotificationSettings{(setting) in
                    print(setting)
                guard setting.authorizationStatus == .authorized else {return}
            }
            
        }
        
        setLoading(isLoading: true);
    }

    // If we're powered on, start scanning
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for", WatchCatPeripheral.watchCatServiceUUID);
            centralManager.scanForPeripherals(withServices: [WatchCatPeripheral.watchCatServiceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }

    // Handles the result of the scan
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // We've found it so stop scan
        self.centralManager.stopScan()
        
        // Copy the peripheral instance
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        // Connect!
        self.centralManager.connect(self.peripheral, options: nil)
        
    }
    
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your Board")
            peripheral.discoverServices([WatchCatPeripheral.watchCatServiceUUID]);
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            print("Disconnected")
            
            setLoading(isLoading: true);
            isCatHidden();
            
            self.peripheral = nil
            
            // Start scanning again
            print("Central scanning for", WatchCatPeripheral.watchCatServiceUUID);
            centralManager.scanForPeripherals(withServices: [WatchCatPeripheral.watchCatServiceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == WatchCatPeripheral.watchCatServiceUUID {
                    print("Service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics([WatchCatPeripheral.redLEDCharacteristicUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                     didUpdateNotificationStateFor characteristic: CBCharacteristic,
                     error: Error?) {
        print("Enabling notify ", characteristic.uuid)
        
        
        setLoading(isLoading: false);
        isCatHidden();
        
        if error != nil {
            print("Enable notify error")
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                     didUpdateValueFor characteristic: CBCharacteristic,
                     error: Error?) {
        print("Battery:", characteristic.value!)
        
        let contains = characteristic.value!.contains(1)
        if(contains){
            self.lastData = characteristic.value;
            self.blePong()
            self.sendNotification()
            
            DispatchQueue.main.async {
                let today = Date()
                let formatter1 = DateFormatter()
                formatter1.dateFormat = "yyyy-MM-dd HH:mm:ss"
                print(formatter1.string(from: today))
                
                    
                let lblHeight = CGFloat(20);
                let lbly = 10 + self.cnt * lblHeight;
                let dateLbl = UILabel(frame: CGRect(x: 20, y: lbly, width: self.view.frame.size.width, height: lblHeight))
                dateLbl.text = formatter1.string(from: today)
                dateLbl.textColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
                
                self.scrollView.addSubview(dateLbl)
                self.scrollView.autoresizingMask = .flexibleHeight
                self.scrollView.contentSize.height = lbly + lblHeight;
                
                self.cnt += 1;
                
                
                self.isCatHidden();
            }
        }
    }
    
    // Handling discovery of characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print(characteristic.uuid)
                if characteristic.uuid == WatchCatPeripheral.redLEDCharacteristicUUID {
                    print("Red LED characteristic found")
                    
                    // Set the characteristic
                    battChar = characteristic
                    
                    isCatHidden();
                    
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pokakal!"
        content.body = "Nu chtog, nado by ubrat'..."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
        
        notificationCenter.add(request) {(error) in
            print(error?.localizedDescription)
        }
    }

    func blePong() {
        peripheral.writeValue(withUnsafeBytes(of: 2) { Data($0) }, for: battChar!, type: .withoutResponse)
    }
    
    @IBAction func clearLog(_ sender: Any) {
        self.scrollView.subviews.forEach({ $0.removeFromSuperview() })
        self.cnt = 0
        
        isCatHidden();
    }
    
    func isCatHidden(){
        DispatchQueue.main.async {
            let clean = self.cnt == 0;
            self.cleanCatImg.isHidden = !clean;
            self.catImg.isHidden = clean;
        }
    }
    
    func setLoading(isLoading: Bool) {
        DispatchQueue.main.async {
            self.loadingIndicator.isHidden = !isLoading;
        }
    }
}

