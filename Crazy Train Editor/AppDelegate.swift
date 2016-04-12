import Cocoa


@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    @IBOutlet var deviceButton: NSPopUpButton!
    @IBOutlet var editorView: EditorView!
    @IBOutlet var dataWindow: NSWindow!
    @IBOutlet var dataTextView: NSTextView!
    
    override func awakeFromNib() {
        deviceChanged(deviceButton)
    }
    
    @IBAction func deviceChanged(sender: NSPopUpButton) {
        let deviceString = sender.titleOfSelectedItem!
        var size: NSSize!
        switch deviceString {
        case "iPhone 4/4S":
            size = NSSize(width: 480, height: 320)
        case "iPhone 5/5S":
            size = NSSize(width: 568, height: 320)
        case "iPhone 6/6S":
            size = NSSize(width: 667, height: 375)
        case "iPhone 6+/6S+":
            size = NSSize(width: 736, height: 414)
        default:
            size = NSZeroSize
        }
        editorView.setup(size)
    }
    
    @IBAction func showDataWindow(sender: NSButton) {
        /*saveJsonFile()

        var data = ""
        for var p = 0; p < editorView.paths.count; p = p + 1{
            data += editorView.paths[p].print()
            if p < editorView.paths.count - 1{
                data += "/"
            }
        }
        
        //dataTextView.string = saveJsonFile()
        window.beginSheet(dataWindow) {
        (NSModalResponse) -> Void in
        }*/
        self.dataTextView.string = self.editorView.getData()
        self.window.beginSheet(self.dataWindow) { (NSModalResponse) -> Void in
            
        }
        
    }
    
  
    
    @IBAction func hideDataWindow(sender: NSButton) {
        window.endSheet(dataWindow, returnCode: NSModalResponseOK)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func saveJsonFile() -> String{
        /*do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(editorView.buildData(), options: NSJSONWritingOptions.PrettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            
            Swift.print(jsonString)
            
            let jsonFilePath = ("~/Desktop/test.json" as NSString).stringByExpandingTildeInPath
            
            Swift.print(jsonFilePath)
            
            do {
                try jsonString.writeToFile(jsonFilePath, atomically: true, encoding: NSUTF8StringEncoding)
                Swift.print("JSON data was written to teh file successfully!")
                
            } catch let error as NSError {
                Swift.print("Couldn't write to file: \(error.localizedDescription)")
            }
            return jsonString
        } catch let error as NSError {
            
            Swift.print(error)
            return ""
        }*/
        return ""
    }
}