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
    
    public func ReadBytes(address:UInt, count:Int) -> [UInt8] {
        
        let result = [UInt8](count: count, repeatedValue: 0)
        let pResult = UnsafeMutablePointer<UInt8>(result)
        var outsize: vm_size_t = 0
        
        vm_read_overwrite(_task, address, vm_size_t(count), unsafeBitCast(pResult, vm_address_t.self), &outsize)
        
        return result
        
    }
    
    public func Read<T>(address:UInt) -> T {
        
        let pResult = UnsafeMutablePointer<T>.alloc(1)
        var outsize: vm_size_t = 0
        
        vm_read_overwrite(_task, address, vm_size_t(sizeof(T.Type)), unsafeBitCast(pResult, vm_address_t.self), &outsize)
        
        let result =  pResult.move()
        pResult.dealloc(1)
        return result
        
    }
    
    public func ReadString(address:UInt, maxLength:Int) -> String {
        
        var result = ""
        var outsize: vm_size_t = 0
        var pBuffer:UnsafeMutablePointer<CChar> = UnsafeMutablePointer.alloc(maxLength)
        if (vm_read_overwrite(_task, address, vm_size_t(maxLength), unsafeBitCast(pBuffer, vm_address_t.self), &outsize) == KERN_SUCCESS) {
            if let str = String.fromCString(pBuffer) {
                result = str
            }
        }
        
        pBuffer.destroy()
        pBuffer.dealloc(maxLength)
        return result
        
    }
    
    public func WriteBytes(address:UInt, bytes:[UInt8]) -> Bool {
        
        let pBytes = UnsafePointer<UInt8>(bytes)
        var result = false
        
        if let regionBasicInfo = GetRegionBasicInfo(address) {
            if vm_protect(_task, vm_address_t(address), vm_size_t(bytes.count), boolean_t(0), vm_prot_t(0x7)) == KERN_SUCCESS {
                if vm_write(_task, vm_address_t(address), unsafeBitCast(pBytes, vm_address_t.self), mach_msg_type_number_t(bytes.count)) == KERN_SUCCESS {
                    if vm_protect(_task, vm_address_t(address), vm_size_t(bytes.count), boolean_t(0), vm_prot_t(regionBasicInfo.Protection)) == KERN_SUCCESS {
                        result = true
                    }
                }
            }
        }
        
        return result
        
    }
    
    public func Write<T>(address:UInt, value: T) -> Bool {
        
        let pValue = UnsafeMutablePointer<T>.alloc(1)
        pValue.memory = value
        var result = false
        
        if let regionBasicInfo = GetRegionBasicInfo(address) {
            if vm_protect(_task, vm_address_t(address), vm_size_t(sizeof(T)), boolean_t(0), vm_prot_t(0x7)) == KERN_SUCCESS {
                if vm_write(_task, vm_address_t(address), unsafeBitCast(pValue, vm_address_t.self), mach_msg_type_number_t(sizeof(T))) == KERN_SUCCESS {
                    if vm_protect(_task, vm_address_t(address), vm_size_t(sizeof(T)), boolean_t(0), vm_prot_t(regionBasicInfo.Protection)) == KERN_SUCCESS {
                        result = true
                    }
                }
            }
        }
        
        pValue.destroy()
        pValue.dealloc(1)
        
        return result
        
    }
    
    public func WriteString(address:UInt, value:String, encoding:NSStringEncoding = NSUTF8StringEncoding) -> Bool {
        
        var strArray = value.cStringUsingEncoding(encoding)!
        let pBytes = UnsafePointer<Int8>(strArray)
        var result = false
        
        if let regionBasicInfo = GetRegionBasicInfo(address) {
            if vm_protect(_task, vm_address_t(address), vm_size_t(strArray.count), boolean_t(0), vm_prot_t(0x7)) == KERN_SUCCESS {
                if vm_write(_task, vm_address_t(address), unsafeBitCast(pBytes, vm_address_t.self), mach_msg_type_number_t(strArray.count)) == KERN_SUCCESS {
                    if vm_protect(_task, vm_address_t(address), vm_size_t(strArray.count), boolean_t(0), vm_prot_t(regionBasicInfo.Protection)) == KERN_SUCCESS {
                        result = true
                    }
                }
            }
        }
        
        return result
        
    }
    
    public func GetRegionBasicInfo(address:UInt) -> BsMemoryBasicInfo? {
        
        var sourceAddress = vm_address_t(0);
        var sourceSize = vm_size_t(0);
        var infoSize = mach_msg_type_number_t(sizeof(vm_region_basic_info_data_64_t))
        var pSourceInfo = UnsafeMutablePointer<vm_region_basic_info_data_64_t>.alloc(1)
        var objectName = mach_port_t(0)
        
        if vm_region_64(_task, &sourceAddress, &sourceSize, VM_REGION_BASIC_INFO_64, UnsafeMutablePointer<Int32>(pSourceInfo), &infoSize, &objectName) == KERN_SUCCESS
        {
            let regionBasicInfoData = pSourceInfo.move()
            let result = BsMemoryBasicInfo(address: UInt(sourceAddress), size: Int(sourceSize), basicInfoData: regionBasicInfoData)
            pSourceInfo.dealloc(1)
            return result
        }
        else
        {
            pSourceInfo.destroy()
            pSourceInfo.dealloc(1)
            return nil
        }
        
    }
    
}