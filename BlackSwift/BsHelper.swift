//
//  BsHelper.swift
//  BlackSwift
//
//  Created by Julian Bosch on 12/03/2015.
//  Copyright (c) 2015 Julian Bosch. All rights reserved.
//

import Foundation

public class BsHelper {
    
    public class func AcquireTaskportRight() -> Bool
    {
        
        var authRef: AuthorizationRef = nil
        let authFlags = AuthorizationFlags(kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed)
        let item = AuthorizationItem(name: "system.privilege.taskport".cStringUsingEncoding(NSUTF8StringEncoding), valueLength: 0, value: nil, flags: 0)
        var authItem = [item]
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        var osStatus = AuthorizationCreate(nil, nil, authFlags, &authRef)
        
        if osStatus == noErr && authRef != nil {
            osStatus = AuthorizationCopyRights(authRef, &authRights, nil, authFlags, nil)
            if osStatus == noErr {
                return true
            }
        }
        
        return false
        
    }
    
    public class func GetProcessesByName(name:String) -> [NSRunningApplication] {
        
        var result = [NSRunningApplication]()
        
        for item in NSWorkspace.sharedWorkspace().runningApplications {
            if item is NSRunningApplication {
                if let runningApp = item as? NSRunningApplication {
                    if name == runningApp.localizedName {
                        result.append(runningApp)
                    }
                }
            }
        }
        
        return result
        
    }
    
    public class func GetProcessesByBundleIdentifier(name:String) -> [NSRunningApplication] {
        
        var result = [NSRunningApplication]()
        
        for item in NSWorkspace.sharedWorkspace().runningApplications {
            if item is NSRunningApplication {
                if let runningApp = item as? NSRunningApplication {
                    if let bundleIdentifier = runningApp.bundleIdentifier {
                        if name == bundleIdentifier {
                            result.append(runningApp)
                        }
                    }
                }
            }
        }
        
        return result
        
    }
    
}