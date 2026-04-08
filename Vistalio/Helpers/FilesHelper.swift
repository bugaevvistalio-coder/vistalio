//
//  FilesHelper.swift
//  Vistalio
//
//  Created by Julia Konkova on 12.06.2022.
//

import Foundation
import PDFKit

class FilesHelper {
    
    func buildFileUrl(path: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(path)
    }
    
    func saveToFile(data: Data, ext: String = "jpg", directory: String? = nil) -> String? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let df = DateFormatter()
        df.dateFormat = "_dd_MM_yyyy_HH_mm_ss"
        let filename = "\(String.randomString(length: 8))\(df.string(from: Date())).\(ext)"
        let url: URL
        
        if let directory = directory {
            let dir = documentsDirectory.appendingPathComponent(directory)
            try? FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
            url = dir.appendingPathComponent(filename)
        } else {
            url = documentsDirectory.appendingPathComponent(filename)
        }
        
        do {
            try data.write(to: url)
            if let dir = directory {
                return "\(dir)/\(filename)"
            }
            return filename
        } catch {
            print(error)
        }
        
        return nil
    }
    
    func deleteFile(path: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent(path)
        do {
            try FileManager.default.removeItem(at: url)
            print("FILE DELETED! \(url)")
        } catch let error as NSError {
            print("Error removing file: \(error.localizedDescription), \(url)")
        }
    }
    
    func savePdf(document: PDFDocument, directory: String, filename: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = documentsDirectory.appendingPathComponent(directory)
        try? FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
        let url = dir.appendingPathComponent(filename)
        if let data = document.dataRepresentation() {
            try? data.write(to: url)
        }
        return url
    }
    
    func createLinkToFile(atURL fileURL: URL, withName fileName: String) -> URL? {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let linkURL = tempDirectoryURL.appendingPathComponent(fileName)
        do {
            if fileManager.fileExists(atPath: linkURL.path) {
                try fileManager.removeItem(at: linkURL)
            }
            try fileManager.linkItem(at: fileURL, to: linkURL)
            return linkURL
        } catch let error as NSError {
            print("\(error)")
            return nil
        }
    }
    
    func copyFile(at path: String, to dirName: String) -> String {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let src = documentsDirectory.appendingPathComponent(path)
        let dir = documentsDirectory.appendingPathComponent(dirName)
        try? fileManager.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
        let dst = dir.appendingPathComponent(src.lastPathComponent)
        try? fileManager.copyItem(at: src, to: dst)
        return "\(dirName)/\(src.lastPathComponent)"
    }
}
