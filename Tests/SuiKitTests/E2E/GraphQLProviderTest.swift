//
//  File.swift
//
//
//  Created by Marcus Arnett on 1/11/24.
//

import Foundation
import XCTest
import SwiftyJSON
@testable import SuiKit

final class GraphQLProviderTest: XCTestCase {
    var toolBox: TestToolbox?
    var packageId: String?
    var parentObjectId: String?

    override func setUp() async throws {
        self.toolBox = try await TestToolbox(true)
    }
    
    private func setUpWithPackage() async throws {
        self.packageId = try await self.fetchToolBox().publishPackage("dynamic-fields").packageId
        
        let ownedObjects = try await self.fetchToolBox()
            .client.getOwnedObjects(
                owner: try self.fetchToolBox().account.publicKey.toSuiAddress(),
                filter: SuiObjectDataFilter.structType(
                    "\(try self.fetchPackageId())::dynamic_fields_test::Test"
                ),
                options: SuiObjectDataOptions(showType: true)
            )
        self.parentObjectId = ownedObjects.data[0].data!.objectId
    }

    private func setUpWithTransaction() async throws {
        let toolBox = try self.fetchToolBox()
        try await toolBox.setup()
        var tx = try TransactionBlock()
        let coin = try tx.splitCoin(
            coin: tx.gas,
            amounts: [tx.pure(value: .number(1))]
        )
        let _ = try tx.transferObject(objects: [coin], address: toolBox.defaultRecipient)
        try tx.setSenderIfNotSet(sender: try toolBox.account.publicKey.toSuiAddress())
        
        let result = try await toolBox.client.signAndExecuteTransactionBlock(
            transactionBlock: &tx,
            signer: toolBox.account
        )
        let _ = try await self.fetchToolBox().client.waitForTransaction(tx: result.digest)
        try await Task.sleep(nanoseconds: 10_000_000_000)  // Buffer for waiting on the Sui Indexer to catch up with the RPC Node
    }

    private func fetchToolBox() throws -> TestToolbox {
        guard let toolBox = self.toolBox else {
            XCTFail("Failed to get Toolbox")
            throw NSError(domain: "Failed to get Toolbox", code: -1)
        }
        return toolBox
    }

    private func fetchPackageId() throws -> String {
        guard let packageId = self.packageId else {
            XCTFail("Failed to get Package ID")
            throw NSError(domain: "Failed to get Package ID", code: -1)
        }
        return packageId
    }

    private func fetchParentObjectId() throws -> String {
        guard let parentObjectId = self.parentObjectId else {
            XCTFail("Failed to get Parent Object ID")
            throw NSError(domain: "Failed to get Parent Object ID", code: -1)
        }
        return parentObjectId
    }

    func testThatGettingCoinsWorksAsIntendedFromGraphQL() async throws {
        try await self.setUpWithTransaction()
        let toolBox = try self.fetchToolBox()
        let rpcCoins = try await toolBox.client.getCoins(account: try toolBox.account.address())
        let graphQLCoins = try await toolBox.graphQLProvider.getCoins(account: try toolBox.account.address())
        XCTAssertEqual(graphQLCoins.data.map { $0.previousTransaction }, rpcCoins.data.map { $0.previousTransaction })
    }

    func testThatGettingAllCoinsWorksAsIntendedFromGraphQL() async throws {
        try await self.setUpWithTransaction()
        let toolBox = try self.fetchToolBox()
        let rpcCoins = try await toolBox.client.getAllCoins(account: toolBox.account.publicKey)
        let graphQLCoins = try await toolBox.graphQLProvider.getAllCoins(account: toolBox.account.publicKey)
        XCTAssertEqual(graphQLCoins.data.map { $0.previousTransaction }, rpcCoins.data.map { $0.previousTransaction })
    }

    func testThatGettingBalanceWorksAsIntendedFromGraphQL() async throws {
        try await self.setUpWithTransaction()
        let toolBox = try self.fetchToolBox()
        let rpcBalance = try await toolBox.client.getBalance(account: toolBox.account.publicKey)
        let graphQLBalance = try await toolBox.graphQLProvider.getBalance(account: toolBox.account.publicKey)
        XCTAssertEqual(rpcBalance, graphQLBalance)
    }

    func testThatGettingAllBalancesWorksAsIntendedFromGraphQL() async throws {
        try await self.setUpWithTransaction()
        let toolBox = try self.fetchToolBox()
        let rpcBalances = try await toolBox.client.getAllBalances(account: toolBox.account)
        let graphQLBalances = try await toolBox.graphQLProvider.getAllBalances(account: toolBox.account)
        XCTAssertEqual(rpcBalances, graphQLBalances)
    }

    func testThatGettingCoinMetadataWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let rpcMetadata = try await toolBox.client.getCoinMetadata(coinType: "0x2::sui::SUI")
        let graphQLMetadata = try await toolBox.graphQLProvider.getCoinMetadata(coinType: "0x2::sui::SUI")
        XCTAssertEqual(rpcMetadata, graphQLMetadata)
    }

    func testThatGettingTotalSupplyWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let rpcSupply = try await toolBox.client.totalSupply("0x2::sui::SUI")
        let graphQLSupply = try await toolBox.graphQLProvider.totalSupply("0x2::sui::SUI")
        XCTAssertEqual(rpcSupply, graphQLSupply)
    }

    func testThatGettingMoveFunctionArgTypesWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let rpcMoveFunction = try await toolBox.client.getMoveFunctionArgTypes(
            package: "0x2", 
            module: "coin",
            function: "balance"
        )
        let graphQLMoveFunction = try await toolBox.graphQLProvider.getMoveFunctionArgTypes(
            package: "0x2",
            module: "coin",
            function: "balance"
        )
        XCTAssertEqual(rpcMoveFunction, graphQLMoveFunction)
    }

    func testThatGettingMoveFunctionWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let rpcMoveFunction = try await toolBox.client.getNormalizedMoveFunction(
            package: "0x2",
            moduleName: "coin",
            functionName: "balance"
        )
        let graphQLMoveFunction = try await toolBox.graphQLProvider.getNormalizedMoveFunction(
            package: "0x2",
            moduleName: "coin",
            functionName: "balance"
        )
        XCTAssertEqual(rpcMoveFunction, graphQLMoveFunction)
    }

    func testThatGettingNormalizedMoveModulesByPackageWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let rpcMovePackage = try await toolBox.client.getNormalizedMoveModulesByPackage(package: "0x2")
        let graphqlMovePackage = try await toolBox.graphQLProvider.getNormalizedMoveModulesByPackage(package: "0x2")
        XCTAssertEqual(graphqlMovePackage["coin"], rpcMovePackage["coin"])
    }
    
    func testThatGettingNormalizedMoveModuleWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let rpcMoveModule = try await toolBox.client.getNormalizedMoveModule(package: "0x2", module: "coin")
        let graphqlMoveModule  = try await toolBox.graphQLProvider.getNormalizedMoveModule(package: "0x2", module: "coin")
        XCTAssertEqual(graphqlMoveModule, rpcMoveModule)
    }

    func testThatGettingNormalizedMoveStructWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let rpcMoveStruct = try await toolBox.client.getNormalizedMoveStruct(
            package: "0x2",
            module: "coin",
            structure: "Coin"
        )
        let graphqlMoveStruct = try await toolBox.graphQLProvider.getNormalizedMoveStruct(
            package: "0x2",
            module: "coin",
            structure: "Coin"
        )
        XCTAssertEqual(graphqlMoveStruct, rpcMoveStruct)
    }

    func testThatGettingOwnedObjectsWorksAsIntendedFromGraphql() async throws {
        try await self.setUpWithTransaction()
        let toolBox = try self.fetchToolBox()
        let objectOptions = SuiObjectDataOptions(
            showBcs: true,
            showContent: true,
            showDisplay: true,
            showOwner: true,
            showPreviousTransaction: true,
            showStorageRebate: true,
            showType: true
        )
        let rpcObjects = try await toolBox.client.getOwnedObjects(owner: try toolBox.address(), options: objectOptions)
        let graphQLObjects = try await toolBox.graphQLProvider.getOwnedObjects(owner: try toolBox.address(), options: objectOptions)

        XCTAssertEqual(rpcObjects.data.map { $0.data?.owner }, graphQLObjects.data.map { $0.data?.owner })
        XCTAssertEqual(rpcObjects.data.map { $0.data?.digest }, graphQLObjects.data.map { $0.data?.digest })
        XCTAssertEqual(rpcObjects.data.map { $0.data?.previousTransaction }, graphQLObjects.data.map { $0.data?.previousTransaction })
    }

    func testThatGettingObjectWorksAsIntendedFromGraphQL() async throws {
        try await self.setUpWithTransaction()
        let toolBox = try self.fetchToolBox()
        let gasCoin = try await toolBox.getCoins()
        let objectOptions = SuiObjectDataOptions(
            showBcs: true,
            showContent: true,
            showDisplay: true,
            showOwner: true,
            showPreviousTransaction: true,
            showStorageRebate: true,
            showType: true
        )
        
        let rpcObject = try await toolBox.client.getObject(objectId: gasCoin.data[0].coinObjectId, options: objectOptions)
        let graphQLObject = try await toolBox.graphQLProvider.getObject(objectId: gasCoin.data[0].coinObjectId, options: objectOptions)
        
        XCTAssertEqual(rpcObject?.data?.objectId, graphQLObject?.data?.objectId)
        XCTAssertEqual(rpcObject?.data?.digest, graphQLObject?.data?.digest)
        XCTAssertEqual(rpcObject?.data?.previousTransaction, graphQLObject?.data?.previousTransaction)
    }
    
    func testThatGettingProtocolConfigWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let protocolRpc = try await toolBox.client.getProtocolConfig()
        let protocolGraphQL = try await toolBox.graphQLProvider.getProtocolConfig()
        XCTAssertEqual(protocolRpc, protocolGraphQL)
    }
    
    func testThatGettingCheckpointWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let checkpointRpc = try await toolBox.client.getCheckpoint(id: "3")
        let checkpointGraphQL = try await toolBox.graphQLProvider.getCheckpoint(sequenceNumber: 3)
        XCTAssertEqual(checkpointRpc, checkpointGraphQL)
    }
    
    func testThatGettingCheckpointsWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let checkpointsRpc = try await toolBox.client.getCheckpoints(cursor: "0", limit: 5, order: .ascending)
        let checkpointsGraphQL = try await toolBox.graphQLProvider.getCheckpoints(cursor: "MA", limit: 5, order: .ascending)
        XCTAssertEqual(checkpointsRpc.data, checkpointsGraphQL.data)
    }
    
    func testThatGettingTotalTransactionBlocksWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let totalTxBlocksRpc = try await toolBox.client.getTotalTransactionBlocks()
        let totalTxBlocksGraphQL = try await toolBox.graphQLProvider.getTotalTransactionBlocks()
        XCTAssertGreaterThanOrEqual(totalTxBlocksRpc, totalTxBlocksGraphQL)
    }
    
    func testThatGettingReferenceGasPriceWorksAsIntendedFromGraphQL() async throws {
        let toolBox = try self.fetchToolBox()
        let referenceRpc = try await toolBox.client.getReferenceGasPrice()
        let referenceGraphQL = try await toolBox.graphQLProvider.getReferenceGasPrice()
        XCTAssertEqual(referenceRpc, referenceRpc)
    }
}
