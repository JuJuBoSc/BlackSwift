//
//  BsMemoryBasicInfo.swift
//  BlackSwift
//
//  Created by Julian Bosch on 12/03/2015.
//  Copyright (c) 2015 Julian Bosch. All rights reserved.
//

import Foundation

public class BsMemoryBasicInfo
{
    
    private var _address:UInt
    private var _size:Int
    private var _basicInfoData:vm_region_basic_info_data_64_t

    init (address:UInt, size:Int, basicInfoData:vm_region_basic_info_data_64_t) {
        _address = address
        _size = size
        _basicInfoData = basicInfoData
    }
    
    public var StartAddress:UInt {
        return _address
    }
    
    public var Size:Int {
        return _size
    }
    
    public var Protection:Int32 {
        return _basicInfoData.protection
    }
    
}