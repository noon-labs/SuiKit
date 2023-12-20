//
//  File.swift
//  
//
//  Created by Marcus Arnett on 12/20/23.
//

import Foundation

public struct CheckpointPageInfo {
    public var startCursor: String?
    public var endCursor: String?
    public var hasNextPage: Bool
    public var hasPreviousPage: Bool

    public init(graphql: GetCheckpointsQuery.Data.CheckpointConnection.PageInfo) {
        self.startCursor = graphql.startCursor
        self.endCursor = graphql.endCursor
        self.hasNextPage = graphql.hasNextPage
        self.hasPreviousPage = graphql.hasPreviousPage
    }
}
