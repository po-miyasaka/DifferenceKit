//
//  DiffMiyashi.swift
//  Example-iOS
//
//  Created by po_miyasaka on 2020/01/22.
//  Copyright © 2020 Ryo Aoyama. All rights reserved.
//

import Foundation

public struct MovedIndexPath {
    public let before: IndexPath
    public let after: IndexPath
    
    init(_ before: IndexPath, _ after: IndexPath) {
        self.before = before
        self.after = after
    }
}

public typealias ClassifiedIndexPaths = (reloaded: [IndexPath],
    moved: [MovedIndexPath],
    deleted: [IndexPath],
    inserted: [IndexPath])

public struct Diff<T: Diffable> {
    public let old: [T]
    public let new: [T]
    
    public init(old: [T], new: [T]) {
        self.old = old
        self.new = new
    }
    
    public func classifyIndice(section: Int = 0) -> ClassifiedIndexPaths {
        var table: [T.ID: (element: T, newIndex: Int)] = [:]
        
        var reloaded = [IndexPath]()
        var moved = [MovedIndexPath]()
        var deleted = [IndexPath]()
        
        new.enumerated().forEach { (i, element) in
            table[element.id] = (element, i)
        }
        
        old.enumerated().forEach {(i, element) in
            if let tuple = table[element.id] {
                // 新しいArrayにも残った。この時点ではアップデートかムーブ
                if tuple.newIndex == i {
                    // 同じインデックスなので、要素の内容が変わっていたらリロードするが、そうでなければ何もしなくてよい。
                    if tuple.element.expression == element.expression {
                        // 要素の内容が同じだったので何もしない
                    } else {
                        // 要素の内容に変更があるためリロード
                        reloaded.append(IndexPath(row: i, section: section))
                    }
                    
                } else {
                    // 違うインデックスなのでムーブ
                    moved.append(MovedIndexPath(IndexPath(row: i, section: section),
                                                IndexPath(row: tuple.newIndex, section: section)))
                }
                
                // アップデートもしくはムーブ対象のIndexPathが判明したので、Tableから削除しておく。（Tableに残ったものがインサートされたデータ）
                table.removeValue(forKey: element.id)
            } else {
                // newに含まれないエレメント。つまりデリートされた。
                deleted.append(IndexPath.init(row: i, section: section))
            }
        }
        
        let inserted = table.values.map { IndexPath.init(row: $1, section: section) }
        
        return (reloaded: reloaded,
                moved: moved,
                deleted: deleted,
                inserted: inserted)
    }
    
}

public protocol Diffable {
    associatedtype Expression: Equatable
    associatedtype ID: Hashable
    var expression: Expression { get }
    var id: ID { get }
}

public protocol DiffableSection {
    associatedtype Element: Diffable
    var elements: [Element] { get }
}

public struct SectionDiff<T: DiffableSection> {
    public let old: [T]
    public let new: [T]
    
    public func classifyIndice() -> ClassifiedIndexPaths {
        var table: [T.Element.ID: (element: T.Element, newSection: Int, newRow: Int)] = [:]
        
        var reloaded = [IndexPath]()
        var moved = [MovedIndexPath]()
        var deleted = [IndexPath]()
        
        new.enumerated().forEach { (arg) in
            let (i, section) = arg
            section.elements.enumerated().forEach { (arg) in
                let (k, element) = arg
                table[element.id] = (element: element, newSection: i, newRow: k)
            }
        }
        
        old.enumerated().forEach { (arg) in
            let (i, section) = arg
            section.elements.enumerated().forEach {(k, element) in
                if let tuple = table[element.id] {
                    // 新しいArrayにも残った。この時点ではアップデートかムーブ
                    if tuple.newSection == i, tuple.newRow == k {
                        // 同じインデックスなので、要素の内容が変わっていたらリロードするが、そうでなければ何もしなくてよい。
                        if tuple.element.expression == element.expression {
                            // 要素の内容が同じだったので何もしない
                        } else {
                            // 要素の内容に変更があるためリロード
                            reloaded.append(IndexPath(row: k, section: i))
                        }
                        
                    } else {
                        // 違うインデックスなのでムーブ
                        moved.append(MovedIndexPath(IndexPath(row: k, section: i),
                                                    IndexPath(row: tuple.newRow, section: tuple.newSection)))
                    }
                    
                    // アップデートもしくはムーブ対象のIndexPathが判明したので、Tableから削除しておく。（Tableに残ったものがインサートされたデータ）
                    table.removeValue(forKey: element.id)
                } else {
                    // newに含まれないエレメント。つまりデリートされた。
                    deleted.append(IndexPath.init(row: k, section: i))
                }
            }
        }
        
        let inserted = table.values.map { IndexPath(row: $0.newRow, section: $0.newSection) }
        
        return (reloaded: reloaded,
                moved: moved,
                deleted: deleted,
                inserted: inserted)
    }
    
}

