//
//  BsProcess.swift
//  BlackSwift
//
//  Created by Julian Bosch on 12/03/2015.
//  Copyright (c) 2015 Julian Bosch. All rights reserved.
//

import Foundation

public class BsProcess {
    
    private var _processId = Int32(0)
    private var _task = mach_port_name_t(MACH_PORT_NULL)
    
    public init(processId:Int32) {
        _processId = processId
    }
    
    public func Attach() -> Bool {
        
        if !BsHelper.AcquireTaskportRight() {
            println("Attach failed - Unable to acquire taskport right !")
            return false
        }
        
        let taskForPidResult = task_for_pid(mach_task_self_, _processId, &_task)
        
        if taskForPidResult != KERN_SUCCESS {
            println("Attach failed - task_for_pid returned : \(taskForPidResult.description)")
            println("Make sure your application is signed or running with root privileges !")
            return false
        }
        
        if _task == mach_port_name_t(MACH_PORT_NULL) {
            println("Attach failed - task_for_pid returned invalid task !")
            return false
        }
        
        return true
        
    }
    
    public func Detach() {
        _task = mach_port_name_t(MACH_PORT_NULL)
    }
    
    public func ReadBytes(address:UInt, count:Int) -> [UInt8]
    {
        
        var result = [UInt8](count: count, repeatedValue: 0)
        var pResult = UnsafeMutablePointer<UInt8>(result)
        var outsize: vm_size_t = 0
        
        if (vm_read_overwrite(_task, address, vm_size_t(count), unsafeBitCast(pResult, vm_address_t.self), &outsize) != KERN_SUCCESS)
        {
            #if DEBUG
            println("BsProcess.ReadBytes failed at 0x" + String(address, radix: 16, uppercase: true) + ", count : " + count.description)
            #endif
        }
        
        return result
        
    }
    
}