//
//  ViewController.swift
//  SwiftAPIBuilder
//
//  Created by drinking on 16/9/1.
//  Copyright © 2016年 drinking. All rights reserved.
//

import Cocoa

class ViewController: NSViewController ,NSMenuDelegate{
    private var fileWatchers:[String:FileWatcherProtocol] = [:]
    
    
    var listeningDirectory:String? {
        get {
            return UserDefaults.standard.string(forKey: "DKListeningDirectory")
        }
        
        set(newValue) {
            UserDefaults.standard.setValue(newValue!, forKey: "DKListeningDirectory")
        }
    }
    
    var outputDirectory:String? {
        get {
            return UserDefaults.standard.string(forKey: "DKOutputDirectory")
        }
        
        set(newValue) {
            UserDefaults.standard.setValue(newValue!, forKey: "DKOutputDirectory")
        }
    }
    
    @IBOutlet var outputTextView: NSTextView!
    @IBOutlet weak var listeningPathLabel: NSTextField!
    @IBOutlet weak var outputPathLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet weak var convertor:NSMenu!
    
    @IBOutlet var resultTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.outputTextView.isAutomaticQuoteSubstitutionEnabled = false
        self.resultTextView.isAutomaticQuoteSubstitutionEnabled = false
        if let path = listeningDirectory{
            self.listeningPathLabel.attributedStringValue = NSAttributedString(string: path)
        }
        
        if let path = outputDirectory {
            self.outputPathLabel.attributedStringValue = NSAttributedString(string: path)
        }
        
    }
    
    @IBAction func convert2Model(sender:NSMenuItem){
     
        if let json = self.outputTextView.textStorage?.string{
            let result = Coolie(JSONString: json).printObjCModelWithName(modelName: "Model")
            self.resultTextView.textStorage?.setAttributedString(NSAttributedString(string: result))
        } else{
            self.resultTextView.textStorage?.setAttributedString(NSAttributedString(string: "Error: Parse failure"))
        }
        
    }
    
    @IBAction func convert2Mappable(sender:NSMenuItem){
        
        if let json = self.outputTextView.textStorage?.string{
            let result = Coolie(JSONString: json).printSwiftMappableModelWithName(modelName: "Model")
            self.resultTextView.textStorage?.setAttributedString(NSAttributedString(string: result))
        } else{
            self.resultTextView.textStorage?.setAttributedString(NSAttributedString(string: "Error: Parse failure"))
        }
    }
    
    @IBAction func convert2APIB(sender:NSMenuItem){
        
        if let json = self.outputTextView.textStorage?.string{
            let result = Coolie(JSONString: json).printApibModelWithName(modelName: "Model")
            self.resultTextView.textStorage?.setAttributedString(NSAttributedString(string: result))
        } else{
            self.resultTextView.textStorage?.setAttributedString(NSAttributedString(string: "Error: Parse failure"))
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func startupDaemon(path:String,outputPath p:String){
        
        let listeningURL = URL(fileURLWithPath: path)
        if let fileURLs = try? FileManager.default.contentsOfDirectory(at: listeningURL, includingPropertiesForKeys:nil, options: .skipsSubdirectoryDescendants){
            
            let tuples = fileURLs.filter({
                return $0.pathExtension == "apib"
            }).map({ (input) -> (URL,URL) in
                let output = input.deletingPathExtension().appendingPathExtension("swift")
                return (input,output)
            })
            
            for tuple in tuples{
                setupDesktopDaemon(filePath: tuple.0,outputPath:tuple.1)
            }
            
            statusLabel.attributedStringValue = NSAttributedString(string: "Listening \(self.fileWatchers.count) files...")
        }
    }
    
    func setupDesktopDaemon(filePath: URL,outputPath p:URL) {
        
        do{
            let watcher = FileWatcher.Local(path: filePath.relativePath)
            try watcher.start(closure: { result in
                switch result {
                case .noChanges:
                    break
                case .updated(let data):
                    let text = String(data: data as Data, encoding: String.Encoding.utf8)
                    if let t = text{
                        if let result = self.parseAPIB2SwiftAPI(text: t){
                            self.outputTextView.textStorage?.setAttributedString(NSAttributedString(string: result))
                            guard let _ = try? result.write(to: p, atomically: true, encoding: String.Encoding.utf8) else{
                                
                                return
                            }
                        }
                    }
                }
            })
            fileWatchers[filePath.lastPathComponent] = watcher
        }catch let e {
            print("Error: \(e) when watching file \(filePath) ")
        }
        
    }
    
    
    func shell(args: String...) -> String {
        let task = Process()
        task.launchPath = "/usr/local/bin/"
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
    
    
    func parseAPIB2SwiftAPI(text:String)->String?{
        
        do {
            try text.write(to: NSURL(fileURLWithPath: "/tmp/text.tmp") as URL, atomically: true, encoding: String.Encoding.utf8)
            return run(bash :"/usr/local/bin/drafter -t refract -f json /tmp/text.tmp").trim2JSONString().parse2Swift()
        } catch let e {
            print(e)
        }
        
        return ""
    }
    
    
    @IBAction func setupListeningPath(_ sender: AnyObject) {
        pickListeningPath{
            self.listeningPathLabel.attributedStringValue = NSAttributedString(string: $0)
            self.listeningDirectory = $0
        }
    }
    
    @IBAction func setupOutputPath(_ sender: AnyObject) {
        pickListeningPath{
            self.outputPathLabel.attributedStringValue = NSAttributedString(string: $0)
            self.outputDirectory = $0
        }
    }
    
    func pickListeningPath(complete:(String)->Void){
        let panel = NSOpenPanel.init()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        
        if (panel.runModal() == NSModalResponseOK) {
            complete(panel.urls.first?.path ?? "")
        }
    }
    
    @IBAction func startListening(_ sender: AnyObject) {
        guard let path = listeningDirectory ,let ouput = outputDirectory else{
            self.statusLabel.attributedStringValue = NSAttributedString(string: "Path Not Found")
            return
        }
        startupDaemon(path: path,outputPath: ouput)
    }
    
    
    
    
}

extension String {
    
    func parse2Swift()->String?{
        let templateURL = Bundle.main.url(forResource: "APITemplate", withExtension: nil)
        guard let template = templateURL else{
            return nil
        }
        
        let render = DKAPIRender(path: template as NSURL)
        let builder = DKAPIBuilder(render: render)
        return builder.parseAST(jsonString: self)
    }
    
    func trim2JSONString()->String {
        
        var startIndex = self.characters.startIndex
        for ch in self.characters{
            if (ch == "{"){
                break
            }
            startIndex = index(after:startIndex)
        }
        
        var endIndex = self.characters.endIndex
        
        for ch in self.characters.reversed() {
            if (ch == "}"){
                break
            }
            endIndex = index(before: endIndex)
        }
        
        return self.substring(with: startIndex..<endIndex)
        
    }
    
    func regex (pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
            let nsstr = self as NSString
            let all = NSRange(location: 0, length: nsstr.length)
            var matches : [String] = [String]()
            regex.enumerateMatches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: all) {
                (result : NSTextCheckingResult?, _, _) in
                if let r = result {
                    let result = nsstr.substring(with: r.range) as String
                    matches.append(result)
                }
            }
            return matches
        } catch {
            return [String]()
        }
    }
    
    func rangesOfPattern(pattern: String) -> [Range<Index>] {
        var ranges : [Range<Index>] = []
        
        if case let pCount = pattern.characters.count,
            case let strCount = self.characters.count
            , strCount >= pCount {
            
            for i in 0...(strCount-pCount) {
                let from = index(self.startIndex, offsetBy: i)
                if let to = index(self.startIndex,offsetBy:pCount,limitedBy:self.endIndex) {
                    if pattern == self[from..<to] {
                        ranges.append(from..<to)
                    }
                }
                
            }
        }
        
        return ranges
    }
    
}
