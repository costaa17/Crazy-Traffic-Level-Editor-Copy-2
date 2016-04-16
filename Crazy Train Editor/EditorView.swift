import Cocoa

let COL_COUNT = 20
let ROW_COUNT = 10

let MARGIN = 2


struct Path {
    var type: PathType
    var color: NSColor
    var segments: [PathSegment]
}

struct PathSegment {
    var vertices: [CGPoint]
}

enum PathType: String {
    case Road = "Road"
    case Rail = "Rail"
    case Walk = "Walk"
    case Cross = "Cross"
}

class EditorView: NSView {
    var tileWidth: CGFloat = 0
    var tileHeight: CGFloat = 0
    var trackingArea: NSTrackingArea!
    
    @IBOutlet var backgroundTypePopUp: NSPopUpButton!
    @IBOutlet var pathTypePopUp: NSPopUpButton!
    
    // The total width and height of the editor, including the margins
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    // The vertex the mouse is currently over, set by the mouseMoved function
    var currentVertex: CGPoint = CGPointMake(-1, -1);
    
    // The vertices that make up the new segment
    var newVertices: [CGPoint] = []
    
    var shouldAppendSegment: Bool = false
    
    // All paths that have been added to the editor
    var paths: [Path] = []
    
    // The parts that the mouse was down on, i.e. the path, the segment, and the vertex
    var downParts: (path: Int?, segment: Int?, vertex: Int?)
    
    
    var mouseLocation: CGPoint = CGPointMake(0, 0)
    var mouseDownLocation: CGPoint = CGPointMake(0, 0)
    var isEditing = false
    var downOnExistingPoint = false
    var downOnExistingPath = false
    var selectedPath = -1
    var drag = false
    var addNewCurve = false
    
    var indexOfPathToRemove = -1
    var shouldRemovePathOnClick = false
    
    func setup(size: NSSize) {
        self.tileWidth = size.width / CGFloat(COL_COUNT)
        self.tileHeight = size.height / CGFloat(ROW_COUNT)
        
        self.height = self.tileHeight * CGFloat(ROW_COUNT + 2 * MARGIN)
        self.width = self.tileWidth * CGFloat(COL_COUNT + 2 * MARGIN)
        self.window!.setContentSize(NSSize(width: self.width, height: self.height))
        self.window!.center()
        
        // Set up the tracking area
        if self.trackingArea != nil {
            self.removeTrackingArea(self.trackingArea)
        }
        trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingAreaOptions.ActiveInKeyWindow, NSTrackingAreaOptions.MouseMoved], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
        
        // Setup background color popup
        for item in self.backgroundTypePopUp.itemArray {
            let colorSelector = Selector(item.title.lowercaseString + "Color")
            if NSColor.respondsToSelector(colorSelector) {
                let color = NSColor.performSelector(colorSelector).takeUnretainedValue() as! NSColor
                item.image = NSImage.swatchWithColor(color, size: NSSize(width: 16, height: 16))
            }
        }
        setData("/Users/CostaA17/Desktop/test.json", screenSize: size)
    }
    
    func setData(filePath: String, screenSize: NSSize){ // set data from old level editor JSON file
        do {
            let contents = try NSString(contentsOfFile: filePath, usedEncoding: nil) as String
            
            if let data = contents.dataUsingEncoding(NSUTF8StringEncoding) {
                do {
                    let dic = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
                    let pathsArray = dic!["paths"]// array of dictionaries
                    let dataTileWidth = CGFloat(screenSize.width)/((dic!["cols"] as! CGFloat))
                    let dataTileHeight = CGFloat(screenSize.height)/((dic!["rows"] as! CGFloat))
                    
                    for path in pathsArray as! NSArray {
                        var newPath = Path(type: .Road, color: randomColor(), segments: [PathSegment]())
                        let pointsArray = path.valueForKey("points") as! NSArray // array of CGPoint arrays
                        
                        for curve in pointsArray {
                            var points: [CGPoint] = []
                            
                            for p in curve as! NSArray {
                                let point = p as! NSArray
                                let flx = CGFloat(point[0].floatValue)
                                let fly = CGFloat(point[1].floatValue)
                                points.append(vertexFromPoint(CGPointMake(flx * dataTileWidth, fly * dataTileHeight)))
                                
                            }
                            
                            let segment = PathSegment(vertices: points)
                            newPath.segments.append(segment)
                        }
                        
                        let typeString = path.valueForKey("Type")
                        
                        switch typeString as! String {
                        case "road":
                            newPath.type = .Road
                        case "rail":
                            newPath.type = .Rail
                        case "walk":
                            newPath.type = .Walk
                        case "cross":
                            newPath.type = .Cross
                        default:
                            break
                            
                        }
                        paths.append(newPath)
                    }
                    
                } catch {
                    
                }
            }
        } catch let error as NSError {
            Swift.print(error)
            
            // contents could not be loaded
        }

    }
    
    @IBAction func pathTypeDidChange(sender: NSPopUpButton) {
        
    }
    
    @IBAction func backgroundTypeDidChange(sender: NSPopUpButton) {
        self.setNeedsDisplayInRect(self.bounds)
    }
    
    @IBAction func stopEditing(sender: NSButton) {
        endCurrentSegment()
    }
    
    @IBAction func removePath(sender: NSButton) {
        var theEvent: NSEvent!
        var mouseLoc: CGPoint!
        
        NSCursor.crosshairCursor().set()
        whileLoop: while (true) {
            theEvent = self.window?.nextEventMatchingMask(Int(NSEventMask.LeftMouseDownMask.rawValue | NSEventMask.MouseMovedMask.rawValue))
            if theEvent != nil {
                mouseLoc = self.convertPoint(theEvent.locationInWindow, fromView: nil)
                
                switch theEvent.type {
                case NSEventType.MouseMoved:
                    // Highlight current path
                    self.indexOfPathToRemove = -1
                    for i in 0 ..< self.paths.count {
                        let path = generatePathAtIndex(i)
                        let cgPath = path.CGPath(forceClose: false)
                        let clickTargetCGPath = CGPathCreateCopyByStrokingPath(cgPath, nil, path.lineWidth, CGLineCap(rawValue: Int32(path.lineCapStyle.rawValue))!, CGLineJoin(rawValue: Int32(path.lineJoinStyle.rawValue))!, path.miterLimit)
                        if CGPathContainsPoint(clickTargetCGPath, nil, mouseLoc, true) {
                            self.indexOfPathToRemove = i
                        }
                    }
                    
                    self.setNeedsDisplayInRect(self.bounds)
                    
                case NSEventType.LeftMouseDown:
                    self.shouldRemovePathOnClick = true
                    self.mouseDown(theEvent)
                    break whileLoop
                default:
                    break
                }
            }
            
        }
        NSCursor.arrowCursor().set()
    }
    
    @IBAction func addSegment(sender: NSButton) {
        let newSegment = PathSegment(vertices: self.newVertices)
        
        if self.shouldAppendSegment {
            // There is already a path. Append the current vertices as a
            // new segment to the last path
            self.paths[self.paths.count-1].segments.append(newSegment)
        } else {
            // There are not any paths. Create one and add the new segment
            // as its one segment
            let newPath = Path(type: PathType(rawValue: self.pathTypePopUp.titleOfSelectedItem!)!, color: randomColor(), segments: [newSegment])
            self.paths.append(newPath)
        }
        
        // Set the current vertices to contain just the last vertex of the previous segment
        let lastVertex = self.newVertices[1]
        self.newVertices = [lastVertex]
        
        // Used if the user clicks the Stop Editing button to end the current segment.
        // Usually, the Stop Editing button creates a new path with the current vertices
        // but this flag will tell it to append the current vertices to the last path.
        self.shouldAppendSegment = true
        
        self.setNeedsDisplayInRect(self.bounds)
        
    }
    
    func endCurrentSegment() {
        let newSegment = PathSegment(vertices: self.newVertices)
        
        if self.shouldAppendSegment {
            // Add current segment to last path
            self.paths[self.paths.count-1].segments.append(newSegment)
        } else {
            // Add current segment as new path
            let newPath = Path(type: PathType(rawValue: self.pathTypePopUp.titleOfSelectedItem!)!, color: randomColor(), segments: [newSegment])
            self.paths.append(newPath)
        }
        
        self.shouldAppendSegment = false
        
        self.newVertices = []
        
        self.setNeedsDisplayInRect(self.bounds)
    }
    

    
    override func mouseMoved(theEvent: NSEvent) {
        currentVertex = vertexAtMouseLoc(theEvent)
        self.setNeedsDisplayInRect(self.bounds)
    }
    
    func vertexAtLocation(location: CGPoint) -> CGPoint {
        let row = ceil((location.y - 0.5 * self.tileHeight) / self.height * CGFloat(ROW_COUNT + 2 * MARGIN))
        let col = ceil((location.x - 0.5 * self.tileWidth) / self.width * CGFloat(COL_COUNT + 2 * MARGIN))
        return CGPointMake(col, row)
    }
    
    func vertexFromPoint(point: CGPoint) -> CGPoint {
        let relocatedPoint = CGPointMake(point.x + CGFloat(MARGIN) * self.tileWidth, point.y + CGFloat(MARGIN) * self.tileHeight) //adapt to the margin
        return vertexAtLocation(relocatedPoint)
    }
    
    func vertexAtMouseLoc(event: NSEvent) -> CGPoint {
        let mouseLoc: CGPoint = self.convertPoint(event.locationInWindow, fromView: nil)
        return vertexAtLocation(mouseLoc)
    }
    
    func rectAtVertex(vertex: CGPoint) -> CGRect {
        let dim: CGFloat = 20.0
        return CGRect(x: vertex.x * self.tileWidth - 0.5 * dim, y: vertex.y * self.tileHeight - 0.5 * dim, width: dim, height: dim)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if self.shouldRemovePathOnClick {
            
            
            self.shouldRemovePathOnClick = false
            
            // Delete path
            if self.indexOfPathToRemove != -1 {
                self.paths.removeAtIndex(self.indexOfPathToRemove)
                self.indexOfPathToRemove = -1
            }
            
            self.setNeedsDisplayInRect(self.bounds)
            return
        }
        
        let currentVertex = vertexAtMouseLoc(theEvent)
        
        // Check if mouse is down on control point
        self.downParts = (nil, nil, nil)
        for i in 0 ..< self.paths.count {
            let path = self.paths[i]
            for j in 0 ..< path.segments.count {
                let segment = path.segments[j];
                for k in 0 ..< segment.vertices.count {
                    let vertex = segment.vertices[k];
                    if currentVertex.x == vertex.x && currentVertex.y == vertex.y {
                        self.downParts = (i, j, k)
                    }
                }
            }
        }
        
        if self.downParts.path != nil {
            // Down on vertex, start drag
        } else {
            // Down on empty space, append to current path
            
            self.newVertices.append(currentVertex)
            
            
            if (self.newVertices.count == 4) {
                endCurrentSegment()
            }
        }
        
        self.setNeedsDisplayInRect(self.bounds)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        if self.downParts.path != nil {
            self.paths[self.downParts.path!].segments[self.downParts.segment!].vertices[self.downParts.vertex!] = vertexAtMouseLoc(theEvent)
            self.setNeedsDisplayInRect(self.bounds)
        }
    }
    
    func colorForCurrentBackground() -> NSColor {
        let item = self.backgroundTypePopUp.selectedItem!
        let colorSelector = Selector(item.title.lowercaseString + "Color")
        var color: NSColor? = nil
        if NSColor.respondsToSelector(colorSelector) {
            color = NSColor.performSelector(colorSelector).takeUnretainedValue() as? NSColor
        }
        return color!
    }
    
    func getData() -> String {
        var out = "{\n"
        out += "\t\"levelNum\": \(1),\n"
        out += "\t\"levelGoal\": \(20),\n"
        out += "\t\"hasTutorial\": \(true),\n"
        out += "\t\"tutorialText\": \"Touch cars to stop them. Slide cars forward to make them go faster.\",\n"
        out += "\t\"rows\": \(ROW_COUNT),\n"
        out += "\t\"cols\": \(COL_COUNT),\n"
        out += "\t\"backgroundColor\": \"\(colorForCurrentBackground().hexString())\",\n"
        out += "\t\"paths\": ["
        for i in 0 ..< self.paths.count {
            let path = self.paths[i]
            out += "{\n"
            out += "\t\t\"type\": \"\(path.type)\",\n"
            out += "\t\t\"segments\": [\n"
            
            for j in 0 ..< path.segments.count {
                let segment = path.segments[j]
                out += "\t\t\t["
                for k in 0 ..< segment.vertices.count {
                    let vertex = segment.vertices[k]
                    out += "\"{\(Int(vertex.x)-MARGIN),\(Int(vertex.y)-MARGIN)}\""
                    if k < segment.vertices.count - 1 {
                        out += ", "
                    }
                }
                out += "]"
                if j < path.segments.count - 1 {
                    out += ", \n"
                }
            }
            
            out += "\n\t\t]\n"
            
            out += "\t}"
            
            if i < self.paths.count - 1 {
                out += ", "
            }
        }
        out += "]\n"
        out += "}"
        return out
    }
    
    func printData() {
        for path in self.paths {
            Swift.print("\(path.type), R:\(path.color.redComponent), G:\(path.color.greenComponent), B:\(path.color.blueComponent), Segments (\(path.segments.count)): [ ", separator: "", terminator: "")
            for segment in path.segments {
                Swift.print("[", separator: "", terminator: "")
                for vertex in segment.vertices {
                    Swift.print("\(vertex), ", separator: "", terminator: "")
                }
                Swift.print("]", separator: "", terminator: "")
            }
            Swift.print(" ]", separator: "", terminator: "")
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        
    }
    
    func pointForVertex(vertex: CGPoint) -> CGPoint {
        return CGPoint(x: vertex.x * self.tileWidth, y: vertex.y * self.tileHeight)
    }
    
    func generatePathAtIndex(i: Int) -> NSBezierPath {
        let path = self.paths[i]
        
        let bezierPath = NSBezierPath()
        
        switch path.type {
        case .Road:
            bezierPath.lineWidth = 50
        case .Walk:
            bezierPath.lineWidth = 15
        default:
            break
        }
        
        for segment in path.segments {
            if segment.vertices.count == 2 {
                let p0 = pointForVertex(segment.vertices[0])
                let p1 = pointForVertex(segment.vertices[1])
                bezierPath.moveToPoint(p0)
                bezierPath.lineToPoint(p1)
            } else if segment.vertices.count == 3 {
                let p0 = pointForVertex(segment.vertices[0])
                let p1 = pointForVertex(segment.vertices[1])
                let p2 = pointForVertex(segment.vertices[2])
                bezierPath.moveToPoint(p0)
                bezierPath.curveToPoint(p1, controlPoint1: p2, controlPoint2: p2)
            } else if segment.vertices.count == 4 {
                let p0 = pointForVertex(segment.vertices[0])
                let p1 = pointForVertex(segment.vertices[1])
                let p2 = pointForVertex(segment.vertices[2])
                let p3 = pointForVertex(segment.vertices[3])
                bezierPath.moveToPoint(p0)
                bezierPath.curveToPoint(p1, controlPoint1: p2, controlPoint2: p3)
            }
        }
        
        return bezierPath
    }
    
    override func drawRect(dirtyRect: NSRect) {
        colorForCurrentBackground().set()
        NSRectFill(self.bounds)
        
        // Draw grid
        NSColor.lightGrayColor().set()
        for col in 0 ..< COL_COUNT + 2 * MARGIN {
            NSRectFill(NSRect(x: CGFloat(col) * tileWidth, y: 0, width: 1, height: self.bounds.height))
        }
        for row in 0 ..< ROW_COUNT + 2 * MARGIN {
            NSRectFill(NSRect(x: 0, y: CGFloat(row) * tileHeight, width: self.bounds.width, height: 1))
        }
        
        // Draw device limits
        NSColor.redColor().set()
        var deviceRect = NSRect(x: CGFloat(MARGIN) * self.tileWidth, y: CGFloat(MARGIN) * self.tileHeight, width: CGFloat(COL_COUNT) * self.tileWidth, height: CGFloat(ROW_COUNT) * self.tileHeight)
        deviceRect = NSOffsetRect(deviceRect, 0.5, 0.5)
        let path = NSBezierPath(rect: deviceRect)
        path.lineWidth = 3.0
        path.stroke();
        
        // Draw current vertex
        NSColor.grayColor().set()
        let rect = rectAtVertex(self.currentVertex)
        NSBezierPath(ovalInRect: rect).fill()
        
        // Draw paths
        for i in 0 ..< self.paths.count {
            if i == self.indexOfPathToRemove {
                NSColor.infoBlueColor().set()
            } else {
                NSColor.whiteColor().set()
            }
            
            let bezier = self.generatePathAtIndex(i)
            bezier.stroke()
            
            self.paths[i].color.set()
            for segment in self.paths[i].segments {
                for vertex in segment.vertices {
                    NSBezierPath(ovalInRect: rectAtVertex(vertex)).fill()
                }
            }
        }
        
        // Draw current path
        NSColor.whiteColor().set()
        if self.newVertices.count > 0 {
            let bezier = NSBezierPath()
            switch PathType(rawValue: self.pathTypePopUp.titleOfSelectedItem!)! {
            case .Road:
                bezier.lineWidth = 50
            case .Walk:
                bezier.lineWidth = 15
            default:
                break
            }
            
            bezier.lineWidth = 50
            bezier.moveToPoint(pointForVertex(self.newVertices[0]))
            if self.newVertices.count == 2 {
                bezier.lineToPoint(pointForVertex(self.newVertices[1]))
            } else if self.newVertices.count == 3 {
                bezier.curveToPoint(pointForVertex(self.newVertices[1]), controlPoint1: pointForVertex(self.newVertices[2]), controlPoint2: pointForVertex(self.newVertices[2]))
            } else if self.newVertices.count == 4 {
                bezier.curveToPoint(pointForVertex(self.newVertices[1]), controlPoint1: pointForVertex(self.newVertices[2]), controlPoint2: pointForVertex(self.newVertices[3]))
            }
            bezier.stroke()
        }
        for vertex in self.newVertices {
            NSBezierPath(ovalInRect: rectAtVertex(vertex)).fill()
        }
        
    }
}

