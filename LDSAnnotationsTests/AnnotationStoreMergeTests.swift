//
//  AnnotationStoreMergeTests.swift
//  LDSAnnotations
//
//  Created by Nick Shelley on 11/1/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import XCTest
@testable import LDSAnnotations

// swiftlint:disable force_unwrapping

class AnnotationStoreMergeTests: XCTestCase {
    
    private let alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]

    func testMergeNote() {
        let annotationStore = AnnotationStore()!
        try! annotationStore.addAnnotation(docID: "1", docVersion: 1, appSource: "source", device: "device", source: .Local)
        let expected = try! annotationStore.addNote(title: nil, content: "", annotationID: 1, source: .Local)
        
        let otherStore = AnnotationStore()!
        otherStore.addAll(from: annotationStore, appSource: "source", device: "device")
        
        let actual = otherStore.noteWithID(1)
        XCTAssertEqual(actual, expected)
    }
    
    func testMergeBookmark() {
        let annotationStore = AnnotationStore()!
        try! annotationStore.addAnnotation(docID: "1", docVersion: 1, appSource: "source", device: "device", source: .Local)
        try! annotationStore.addBookmark(name: "Test", paragraphAID: nil, displayOrder: 5, annotationID: 1, offset: 0, source: .Local)
        let expected = Bookmark(id: 1, name: "Test", paragraphAID: nil, displayOrder: 5, annotationID: 1, offset: 0)
        
        let otherStore = AnnotationStore()!
        otherStore.addAll(from: annotationStore, appSource: "source", device: "device")
        
        let actual = otherStore.bookmarkWithID(1)
        XCTAssertEqual(actual, expected)
    }
    
    func testMergeLink() {
        let annotationStore = AnnotationStore()!
        try! annotationStore.addAnnotation(docID: "1", docVersion: 1, appSource: "source", device: "device", source: .Local)
        try! annotationStore.addLink(name: "Link", docID: "DocID", docVersion: 1, paragraphAIDs: ["ParagraphID"], annotationID: 1, source: .Local)
        let expected = Link(id: 1, name: "Link", docID: "DocID", docVersion: 1, paragraphAIDs: ["ParagraphID"], annotationID: 1)
        
        let otherStore = AnnotationStore()!
        otherStore.addAll(from: annotationStore, appSource: "source", device: "device")
        
        let actual = otherStore.linkWithID(1)
        XCTAssertEqual(actual, expected)
    }
    
    func testMergeAnnotations() {
        let annotationStore = AnnotationStore()!
        
        let docID = "12345"
        
        let paragraphRanges = [
            ParagraphRange(paragraphAID: "1"),
            ParagraphRange(paragraphAID: "2"),
            ParagraphRange(paragraphAID: "3"),
            ParagraphRange(paragraphAID: "3"),
            ParagraphRange(paragraphAID: "4")
        ]
        
        let highlights = try! annotationStore.addHighlights(docID: docID, docVersion: 1, paragraphRanges: paragraphRanges, colorName: "yellow", style: .Highlight, appSource: "Test", device: "iphone")
        let annotation = annotationStore.annotationWithID(highlights.first!.annotationID)
        
        let otherStore = AnnotationStore()!
        otherStore.addAll(from: annotationStore, appSource: "Test", device: "iphone")
        
        XCTAssertEqual([annotation!], otherStore.annotations(paragraphAIDs: paragraphRanges.map({ $0.paragraphAID })))
        XCTAssertEqual([annotation!], otherStore.annotations(docID: docID, paragraphAIDs: paragraphRanges.map({ $0.paragraphAID })))
    }
    
    func testMergeNotebook() {
        let annotationStore = AnnotationStore()!
        
        let notebook = try! annotationStore.addNotebook(name: "TestNotebook")
        
        var annotationIDs = [Int64]()
        
        for letter in alphabet {
            let note = try! annotationStore.addNote(title: nil, content: letter, appSource: "Test", device: "iphone", notebookID: notebook.id)
            annotationIDs.append(note.annotationID)
        }
        
        let otherStore = AnnotationStore()!
        otherStore.addAll(from: annotationStore, appSource: "Test", device: "iphone")
        
        XCTAssertEqual(alphabet.count, otherStore.annotationIDsForNotebookWithID(notebook.id).count, "Didn't load all annotation IDs")
        
        // Make sure order was preserved
        for (index, annotation) in otherStore.annotationsWithNotebookID(1).enumerate() {
            XCTAssertEqual(otherStore.noteWithAnnotationID(annotation.id)?.content, alphabet[index])
        }
    }
    
    func testMergeTags() {
        let annotationStore = AnnotationStore()!
        
        var annotationIDs = [Int64]()
        var annotationUniqueIDs = [String]()
        var tagNameToAnnotationUniqueIDs = [String: [String]]()
        
        for letter in alphabet {
            let annotation = try! annotationStore.addAnnotation(docID: "13859831", docVersion: 1, appSource: "Test", device: "iphone", source: .Local)
            annotationIDs.append(annotation.id)
            annotationUniqueIDs.append(annotation.uniqueID)
            
            for annotationID in annotationIDs {
                try! annotationStore.addTag(name: letter, annotationID: annotationID)
            }
            
            tagNameToAnnotationUniqueIDs[letter] = annotationUniqueIDs
        }
        
        let otherStore = AnnotationStore()!
        otherStore.addAll(from: annotationStore, appSource: "Test", device: "iphone")
        
        for tagName in tagNameToAnnotationUniqueIDs.keys {
            let tag = otherStore.tagWithName(tagName)!
            let annotationUniqueIDs = tagNameToAnnotationUniqueIDs[tagName]!
            let otherUniqueIDs = otherStore.annotationIDsForTagWithID(tag.id).map { otherStore.annotationWithID($0)!.uniqueID }
            
            XCTAssertTrue(Set(annotationUniqueIDs) == Set(otherUniqueIDs), "Didn't load correct annotations for tagID")
        }
    }
    
}
