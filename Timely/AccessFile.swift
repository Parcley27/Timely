//
//  AccessFile.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//
//  Does not work, file always not found
//

import Foundation

open class contentDetail {
    
    var names = ["John", "David", "Albert", "Anne", "Olivia", "Bella"]
    
    func compileDetailInfomation(dName: String, dDate: String, dValues: String, dMisc: String) -> [String] {
        let detailInformation = [dName, dDate, dValues, dMisc]
        return detailInformation
    }
    
    //if let filedNames = nameStorage().accessFile(file: "/names", isReading: true, fileLine: 2)
    /*
    func accessFile(file: String, isReading: Bool, fileLine: Int, dataToWrite: String? = nil) -> String? {
        // Get file URL, and throw error if not lost
        guard let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {

            print("Error. File Address Not Found.")
        
            return nil
        }
        
        let fileURL = documentDirectoryURL.appendingPathComponent(file)

        
        // Read from file
        if isReading == true {
            
            // do{} saves sketchy code from because of catch{} as a safety net
            do {
                let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                let lines = fileContents.components(separatedBy: .newlines)
                let totalLines = lines.count
                
                var readData: String? = nil
                
                if fileLine == 0 {
                    readData = lines.last
                    
                } else if fileLine > 0 && fileLine <= totalLines {
                    readData = lines[fileLine - 1]
                    
                } else {
                    print("Error. Wanted line (\(fileLine)) is out of available range.")
                    return nil
                }
                
                // Returns result of found line
                return readData
                
            } catch {
                print("Error. Problem reading from file with \(error)")
                return nil
            }
            
        } else {
            print("Write Requested")
        }
        
        return nil
    }
     */
    
    func oogabooga() -> String? {
        let result = "oogabooga is Working"
        return result

    }
}
