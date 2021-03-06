//
//  MintLeafViewController.swift
//  MINT
//
//  Created by NemuNeko on 2015/04/19.
//  Copyright (c) 2015年 Taizo A. All rights reserved.
//

import Foundation
import Cocoa

enum type {
    case link
    case ref
    case val
    case proc
    case def
}

// Controller of leaf view
// Manage user actions: Arguments inputs and link.
class MintLeafViewController:NSObject, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSDraggingDestination, MintLeafObserver, MintObserver {
    @IBOutlet weak var opdsPopover:NSPopover!
    @IBOutlet weak var leafview:LeafView!
    @IBOutlet weak var operandList:NSTableView!
    @IBOutlet weak var output:NSTextField!
    
    weak var controller:MintController!
    
    var obs : [MintLinkObserver] = []
    
    var frame : CGRect { get { return leafview.frame } }
    
    var uid : UInt
    var leafType : String = "Test"
    var leafName : String = ""
    
    // Xib Top level objects detain
    var xibObjects : NSArray = NSArray()
    
    //Arguments List
    var opds : [(uid: UInt, param: String, value: String, type: type)] = []
    
    // management of view. commmand receivers
    /// setup leafview with xib file
    init(newID: UInt, pos: NSPoint, xib: NSNib?) {
        uid = newID
        super.init()
        
        if xib?.instantiate(withOwner: self, topLevelObjects: &xibObjects) == nil {
            print("Failed to load xib, leaf view")
        } else {
            // set data source and delegate for NSTableView
            operandList.dataSource = self as NSTableViewDataSource
            operandList.delegate = self as NSTableViewDelegate
            
            // set drag operation mask
            operandList.setDraggingSourceOperationMask(NSDragOperation.link, forLocal: true)
            
        }
        
        leafview.frame.origin = pos
        
        /*_
        if let delegate = NSApplication.sharedApplication().delegate as? AppDelegate {
            controller = delegate.controller
        }
        */
    }
    
    /// remove view from workspace. called after 'removeSelf()' called.
    func removeView() {
        leafview.removeFromSuperview()
    }
    
    /// setting argument value is implemented as observer 'update' protocol
    
    
    // Show popover
    @IBAction func showOpdsPopover(_ sender: AnyObject) {
        
        if let view = sender as? NSView {
            opdsPopover.show(relativeTo: view.bounds, of: view, preferredEdge: NSRectEdge.maxY)
        }
    }
    
    @IBAction func export_stl(_ sender: AnyObject?) {
        
        let command = ExportSTL(uid: uid)
        controller.sendCommand(command)
    }
    
    // observer protocol implementation
    /// update as observer
    func update(_ leafid: UInt, newopds: [SExpr], newuid: UInt, olduid: UInt) {
        
        if leafid == uid {
            
            // if both of uids are '0', replace all arguments to 'newopds'
            if olduid == 0 && newuid == 0 {
                
                //make [labels] array form opds
                var labels : [String] = []
                
                // remove current opds
                
                opds = []
                
                // ###not working code.
                for a in opds {
                    labels.append(a.param)
                }
                
                init_opds(newopds, labels: labels)
                if let name = newopds.first?.str("", level: 0) {
                    setName(name)
                }
                
            // if only 'olduid' is '0', append new argument to last
            } else if olduid == 0 {
                if let newopd = newopds.last {
                    switch newopd {
                    case let ltrl as Literal:
                        opds.append((uid: ltrl.uid, param: "", value: ltrl.str("", level: 0), type: type.val))
                    case let pair as Pair:
                        opds.append((uid: pair.uid, param: "", value: "link to: \(pair.car.str("", level: 0))", type: type.link))
                    case let def as MDefine:
                        self.opds.append((uid: def.uid, param: "", value: def.str("", level: 0), type: type.def))
                    case let io as Display:
                        self.opds.append((uid: io.uid, param: "", value: io.str("", level: 0), type: type.def))
                    case let form as Form:
                        self.opds.append((uid: form.uid, param: "proc", value: form.str("", level: 0), type: type.proc))
                    case let proc as Procedure:
                        self.opds.append((uid: proc.uid, param: "proc", value: proc.str("", level: 0), type: type.proc))
                    default:
                        opds.append((uid: newopd.uid, param: "", value: newopd.str("", level: 0), type: type.ref))
                    }
                    
                    //:::: if adde opd is head (never run? delete in the case)
                    if opds.count == 1 {
                        setName(newopd.str("", level: 0))
                    }
                }
                
            // if only 'newuid' is '0', remove 'olduid' opd from list
            } else if newuid == 0 {
                for i in stride(from: 0, to: opds.count, by: 1) {
                    if opds[i].uid == olduid {
                        opds.remove(at: i)
                        break
                    }
                }
                
            // if both of uids are not '0', overwrite 'olduid' opd by 'newuid'
            } else {
                for i in stride(from: 0, to: opds.count, by: 1) {
                    if opds[i].uid == olduid {
                        if let newopd = newopds.last {
                            opds[i].uid = newuid
                            
                            switch newopd {
                            case let ltrl as Literal:
                                opds[i].value = ltrl.str("", level: 0)
                                opds[i].type = type.val
                            case let pair as Pair:
                                opds[i].value = "link to: \(pair.car.str("", level: 0))"
                                opds[i].type = type.link
                            case let def as MDefine:
                                opds[i].value = def.str("", level: 0)
                                opds[i].type = type.def
                            case let io as Display:
                                opds[i].value = io.str("", level: 0)
                                opds[i].type = type.def
                            case let form as Form:
                                opds[i].value = form.str("", level: 0)
                                opds[i].type = type.proc
                            default:
                                opds[i].value = newopd.str("", level: 0)
                                if i == 0 {
                                    opds[i].type = type.proc
                                } else {
                                    opds[i].type = type.ref
                                }
                            }
                            
                            if i == 0 {
                                setName(newopd.str("", level: 0))
                            }
                        }
                    }
                }
            }
            print("reload data at leaf(id: \(uid))", terminator:"\n")
            operandList.reloadData()
        }
    }
    
    /// err output
    func update(_ subject: MintSubject, uid: UInt) {
        if self.uid == uid {
            if let errout = subject as? MintErrPort {
                output.stringValue = errout.err
            }
        }
    }
    
    /// init observer's proc and opd value
    func init_opds(_ opds: [SExpr], labels: [String]) {
        
        var labels2 = labels
        
        if opds.count > labels2.count {
            var i = labels2.count
            
            while opds.count > i {
                labels2.append("")
                i += 1
            }
        }
        
        for i in stride(from: 0, to: opds.count, by: 1) {
            switch opds[i] {
            case let ltrl as Literal:
                self.opds.append((uid: ltrl.uid, param: labels2[i], value: ltrl.str("", level: 0), type: type.val))
            case let pair as Pair:
                self.opds.append((uid: pair.uid, param: labels2[i], value: "link to: \(pair.car.str("", level: 0))", type: type.link))
            case let def as MDefine:
                self.opds.append((uid: def.uid, param: labels2[i], value: def.str("", level: 0), type: type.def))
            case let io as Display:
                self.opds.append((uid: io.uid, param: labels2[i], value: io.str("", level: 0), type: type.def))
            case let form as Form:
                self.opds.append((uid: form.uid, param: labels2[i], value: form.str("", level: 0), type: type.proc))
            default:
                if i == 0 {
                    self.opds.append((uid: opds[i].uid, param: labels2[i], value: opds[i].str("", level: 0), type: type.proc))
                } else {
                    self.opds.append((uid: opds[i].uid, param: labels2[i], value: opds[i].str("", level: 0), type: type.ref))
                }
            }
        }
    }
    
    /// init observer's name
    func setName(_ name: String) {
        leafName = name
        leafview.nameTag.stringValue = name
    }
    
    func leaf_moved() {
        controller.mark_edited()
    }
    
    func move_to_outside() {
        
    }
    
    ///////// Mint Command ////////////
    
    /// tell 'controller' when a operand is modified
    func operand(_ uid: UInt ,valueDidEndEditing value: String, atRow: Int) {
        
        // if uid is '0', new opd added.
        if uid == 0 {
            let addOpd = AddOperand(leafid: self.uid, newvalue: value)
            controller.sendCommand(addOpd)
        // if uid is not '0', overwrite current uid.
        } else {
            let setOpd = SetOperand(argid: uid, leafid: self.uid, newvalue: value)
            controller.sendCommand(setOpd)
        }
        
        
        // automatically select next row to comfort editing.
        // back to focus to tableview and select next row.
        operandList.window?.makeFirstResponder(operandList)
        
        if atRow < numberOfRows(in: operandList) {
            operandList.selectRowIndexes(IndexSet(integer: atRow + 1), byExtendingSelection: false)
        }
    }
    
    
    // hand over 'MintCommand' from view to 'MintController'
    /// tell 'controller' to remove a Leaf
    func removeSelf() {
        let command = RemoveLeaf(removeID: uid)
        controller.sendCommand(command)
    }
    
    /// when dragged "argument" dropped in return button, generate link command for controller
    /// called by MintReturnButton
    
    func setLinkFrom(_ leafID: UInt , withArg: UInt) {
        
        if withArg != 0 {
            print("overwrite the argument (id: \(withArg)) of leaf (id: \(leafID)) and make link from leafID: \(uid)")
            let command = LinkOperand(retLeafID: self.uid, argID: withArg, argleafID: leafID)
            controller.sendCommand(command)
        }
    }
    
    // when dragged "return" dropped in arguments button, generate link command for controller
    // called by 'MintOperandCellView' and it's subclasses
    func acceptLinkFrom(_ leafID: UInt, toArg: UInt) {
        
        if toArg != 0 {
            print("overwrite the argument (id: \(toArg)) of leaf (id: \(uid)) and make link from leafID: \(leafID)")
            let command = LinkOperand(retLeafID: leafID, argID: toArg, argleafID: self.uid)
            controller.sendCommand(command)
        } else {
            let command1 = AddOperand(leafid: uid, newvalue: "")
            controller.sendCommand(command1)
            
            if let newopd = opds.last {
                let command2 = LinkOperand(retLeafID: leafID, argID: newopd.uid, argleafID: self.uid)
                controller.sendCommand(command2)
            }
        }
    }
    
    /// when dragged "argument" dropped in return button of "define" special form, generate ref command for controller
    /// called by MintReturnButton
    func setRefFrom(_ leafID: UInt, withArg: UInt) {
        if withArg != 0 {
            let command = SetReference(retLeafID: self.uid, argID: withArg, argleafID: leafID)
            controller.sendCommand(command)
        }
    }
    
    /// when dragged "return" of "define" dropped in arguments button, generate ref command for controller
    /// called by 'MintOperandCellView' and it's subclasses
    func acceptRefFrom(_ leafID: UInt, toArg: UInt) {
        
        if toArg != 0 {
            let command = SetReference(retLeafID: leafID, argID: toArg, argleafID: self.uid)
            controller.sendCommand(command)
        } else {
            let command1 = AddOperand(leafid: uid, newvalue: "")
            controller.sendCommand(command1)
            
            if let newopd = opds.last {
                let command2 = SetReference(retLeafID: leafID, argID: newopd.uid, argleafID: self.uid)
                controller.sendCommand(command2)
            }
        }
    }
    
    
    /// remove argument or link when 'remove' button clicked
    /// called by 'MintOperandCellView' and it's subclasses
    func remove(_ uid: UInt) {
        for opd in opds {
            if opd.uid == uid {
                switch opd.type {
                case .link:
                    let command = RemoveLink(rmArgID: self.uid, argID: uid)
                    controller.sendCommand(command)
                    return
                case .val, .proc:
                    let command = RemoveOperand(argid: uid, ofleafid: self.uid)
                    controller.sendCommand(command)
                    return
                case .ref:
                    let command = RemoveReference(rmArgID: self.uid, argID: uid)
                    controller.sendCommand(command)
                    return
                case .def:
                    return
                }
            }
        }
    }
    
    /// rehape workspace to fit leaves
    func reshapeWorkspace(_ newframe: CGRect) {
        controller.reshape_workspace(newframe)
    }

    
    ///////// Interact with Table View ////////////
    
    // Provide arguments list. NSTableView delegate & data source implementation
    /// Provide number of list
    func numberOfRows(in tableView: NSTableView) -> Int {
        return opds.count + 1 // for adding new argument, plus 1 row.
    }
    
    /// Provide data for NSTableView
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let identifier : String
        
        switch tableColumn!.headerCell.title {
        case "Params":
            identifier = "paramCell"
        case "Values":
            identifier = "valueCell"
        case "Rm":
            identifier = "rmCell"
        default:
            identifier = ""
        }
        
        let result: AnyObject? = tableView.make(withIdentifier: identifier , owner: self)
        
        switch identifier {
        case "paramCell":
            if let paramView = result as? MintOperandCellView {
                
                if opds.count > row {
                    paramView.uid = opds[row].uid
                    paramView.textField?.stringValue = opds[row].param
                } else {
                    paramView.uid = 0
                    paramView.textField?.stringValue = "add value"
                }
                
                paramView.textField?.isEditable = false
                paramView.controller = self
            }
        case "valueCell":
            if let valueView = result as? MintOperandCellView {
                if opds.count > row {
                    valueView.uid = opds[row].uid
                    valueView.textField?.stringValue = opds[row].value
                    switch opds[row].type {
                    case .val:
                        valueView.textField?.isEditable = true
                    case .proc:
                        valueView.textField?.isEditable = true
                    case .link:
                        valueView.textField?.isEditable = false
                    case .ref:
                        valueView.textField?.isEditable = true
                    case .def:
                        valueView.textField?.isEditable = false
                    }
                } else {
                    valueView.uid = 0
                    valueView.textField?.stringValue = ""
                    valueView.textField?.isEditable = true
                }
                
                valueView.controller = self
            }
        case "rmCell":
            if let rmView = result as? MintRmOpdCellView { //replace MintRefCellView
                if opds.count > row {
                    rmView.uid = opds[row].uid
                    rmView.rmbutton.isEnabled = true
                } else {
                    rmView.rmbutton.isEnabled = false
                }
                
                rmView.controller = self
            }
        default:
            print("Unknown type cell err")
        }
        
        return result as? NSView
    }
    
    
    //////// 'Link' operations ////////
    
    // Dragging source for tableview
    /// Provide type of return value to NSPasteboard for dragging operation
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        pboard.clearContents()
        pboard.declareTypes(["type", "argLeafID", "argumentID"], owner: self)
        
        if pboard.setString("argumentLink", forType:"type" ) {
            
            if pboard.setString("\(uid)", forType: "argLeafID") {
                if let row = rowIndexes.first {
                    if opds.count > row {
                        if pboard.setString("\(opds[row].uid)", forType: "argumentID") {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    // accept drop from return button
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let pboad = info.draggingPasteboard()
        let pbitems = pboad.readObjects(forClasses: [NSPasteboardItem.self], options: nil)
        
        if let item = pbitems?.last as? NSPasteboardItem {
            // pasteboardItemDataProvider is called when below line excuted.
            // but not reflect to return value. API bug??
            // After excution of the line, returnLeafID become available.
            Swift.print(item.string(forType: "com.mint.mint.returnLeafID") ?? "nil", terminator: "\n")
        }
        
        switch info.draggingSourceOperationMask() {
        case NSDragOperation.link:
            if let leafIDstr = pboad.string(forType: "com.mint.mint.returnLeafID") {
                
                if opds.count > row {
                    let leafID = NSString(string: leafIDstr).intValue
                    acceptLinkFrom(UInt(leafID), toArg: opds[row].uid)
                    return true
                }
                
            } else if let leafIDstr = pboad.string(forType: "com.mint.mint.referenceLeafID") {
                
                if opds.count > row {
                    let leafID = NSString(string: leafIDstr).intValue
                    acceptRefFrom(UInt(leafID), toArg: opds[row].uid)
                    return true
                }
                
            }
        default: //anything else will be failed
            return false
        }
        return false
    }
    
    // when "return" button dragged, generate drag as source
    // called by MintReturnButton
    func beginDraggingReturn() -> (leafID: UInt, type: String) {
        
        return (uid, "")
    }
    
    // when dragged "return" entered in arguments button, show popover
    // called by 'MintOperandCellView' and it's subclasses or 'MintArgumentButton'
    func isLinkReqAcceptable() -> Bool {
        return true
    }
    
    // 'LinkView' observer pattern implementation
    /// register 'Observer' for view
    func registerLinkObserverForView(_ obs: MintLinkObserver) {
        leafview.registerObserver(obs)
    }
    
    /// remove 'Observer' from view
    func removeLinkObserverFromView(_ obs: MintLinkObserver) {
        leafview.removeObserver(obs)
    }
}
