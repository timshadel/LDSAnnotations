//
//  AnnotationStore+Merge.swift
//  LDSAnnotations
//
//  Created by Nick Shelley on 11/1/16.
//  Copyright © 2016 Hilton Campbell. All rights reserved.
//

import Foundation

extension AnnotationStore {
    
    public func addAll(from otherStore: AnnotationStore, appSource: String, device: String) {
        let notebooks = otherStore.notebooks()
        for notebook in notebooks {
            do {
                try addNotebook(uniqueID: notebook.uniqueID, name: notebook.name, description: notebook.description, status: notebook.status, lastModified: notebook.lastModified, source: .Sync)
            } catch {
                NSLog("Unable to add notebook: \(error)")
            }
        }
        
        for annotation in otherStore.annotations() {
            do {
                let newAnnotation = try addAnnotation(uniqueID: annotation.uniqueID, docID: annotation.docID, docVersion: annotation.docVersion, status: annotation.status, created: annotation.created, lastModified: annotation.lastModified, appSource: appSource, device: device, source: .Sync)
                if let note = otherStore.noteWithAnnotationID(annotation.id) {
                    try addNote(title: note.title, content: note.content, annotationID: newAnnotation.id)
                }
                for highlight in otherStore.highlightsWithAnnotationID(annotation.id) {
                    try addHighlight(paragraphRange: highlight.paragraphRange, colorName: highlight.colorName, style: highlight.style, annotationID: newAnnotation.id, source: .Sync)
                }
                for tag in otherStore.tagsWithAnnotationID(annotation.id) {
                    try addTag(name: tag.name, annotationID: newAnnotation.id)
                }
                for link in otherStore.linksWithAnnotationID(annotation.id) {
                    try addLink(name: link.name, toDocID: link.docID, toDocVersion: link.docVersion, toParagraphAIDs: link.paragraphAIDs, annotationID: newAnnotation.id)
                }
                if let bookmark = otherStore.bookmarkWithAnnotationID(annotation.id) {
                    try addBookmark(name: bookmark.name, paragraphAID: bookmark.paragraphAID, displayOrder: bookmark.displayOrder, annotationID: newAnnotation.id, offset: bookmark.offset, source: .Sync)
                }
                for notebook in otherStore.notebooksWithAnnotationID(annotation.id) {
                    if let newNotebook = notebookWithUniqueID(notebook.uniqueID) {
                        try addOrUpdateAnnotationNotebook(annotationID: newAnnotation.id, notebookID: newNotebook.id, displayOrder: 0)
                    }
                }
            } catch {
                NSLog("Unable to add annotation: \(error)")
            }
        }
        
        // Make sure display order is correct
        for notebook in notebooks {
            guard let newNotebook = notebookWithUniqueID(notebook.uniqueID) else { continue }
            
            let annotations = otherStore.annotationsWithNotebookID(notebook.id)
            let newAnnotations = annotationsWithNotebookID(newNotebook.id)
            let sortedAnnotations = newAnnotations.sort { left, right in
                return annotations.indexOf({ $0.uniqueID == left.uniqueID }) < annotations.indexOf({ $0.uniqueID == right.uniqueID })
            }
            do {
                try reorderAnnotationIDs(sortedAnnotations.map { $0.id }, notebookID: newNotebook.id)
            } catch {}
        }
    }
    
}