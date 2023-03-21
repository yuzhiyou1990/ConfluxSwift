//
//  ConfluxClient.swift
//  
//
//  Created by xgblin on 2023/3/13.
//

import Foundation
import PromiseKit
import BigInt

public class ConfluxClient: ConfluxBaseClient {
    
    public func getEpochNumber() -> Promise<Int> {
        return Promise<Int> { seal in
            sendRPC(method: "cfx_epochNumber").done { (result: String) in
                seal.fulfill(Int(result.lowercased().cfxStripHexPrefix(), radix: 16) ?? 0)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getBalance(address: String) -> Promise<BigInt> {
        return Promise<BigInt> { seal in
            sendRPC(method: "cfx_getBalance", params: [address]).done { (result: String) in
                guard let number = BigInt(result.lowercased().cfxStripHexPrefix(), radix: 16) else {
                    seal.reject(ConfluxError.unknow)
                    return
                }
                seal.fulfill(number)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getTokenBalance(address: String, contractAddress: String) -> Promise<BigInt> {
        return Promise<BigInt> { seal in
            guard let addressHex = Address(string: address)?.hexAddress else {
                seal.reject(ConfluxError.otherError("invalid address"))
                return
            }
            let dataHex = ConfluxToken.ContractFunctions.balanceOf(address: addressHex).data.toHexString().addPrefix("0x")
            call(to: contractAddress, data: dataHex).done { result in
                seal.fulfill(BigInt(result.lowercased().cfxStripHexPrefix(), radix: 16) ?? BigInt.zero)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func getTokenDecimal(contractAddress: String) -> Promise<Int>  {
        let data = ConfluxToken.ContractFunctions.decimals.data.toHexString().addPrefix("0x")
        return Promise<Int> { seal in
            call(to: contractAddress, data: data).done { result in
                seal.fulfill(Int(result.lowercased().cfxStripHexPrefix(), radix: 16) ?? 0)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getNextNonce(address: String) -> Promise<Int64> {
        return Promise<Int64> { seal in
             sendRPC(method: "cfx_getNextNonce", params: [address]).done { (result: String) in
                guard let number = Int64(result.lowercased().cfxStripHexPrefix(), radix: 16) else {
                    seal.reject(ConfluxError.unknow)
                    return
                }
                seal.fulfill(number)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func sendRawTransaction(rawTransaction: String) -> Promise<String> {
       return sendRPC(method: "cfx_sendRawTransaction", params: [rawTransaction])
    }
    
    public func getGasPrice() -> Promise<String> {
        return Promise<String> { seal in
             sendRPC(method: "cfx_gasPrice").done { (result: String) in
                 guard let number = BigInt(result.lowercased().cfxStripHexPrefix(), radix: 16)?.description else {
                    seal.reject(ConfluxError.unknow)
                    return
                }
                seal.fulfill(number)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func estimateGasAndCollateral(rawTransaction: RawTransaction) -> Promise<EstimateGasAndCollateral> {
        return Promise<EstimateGasAndCollateral> { seal in
            var parameters = [
                "from": rawTransaction.from?.address ?? "",
                "to": rawTransaction.to.address,
                "gasPrice": String(rawTransaction.gasPrice, radix: 16).addPrefix("0x"),
                "nonce": String(rawTransaction.nonce, radix: 16).addPrefix("0x"),
                "value": String(rawTransaction.value, radix: 16).addPrefix("0x")
            ] as? [String: Any]
            if rawTransaction.data.count > 0 {
                parameters?["data"] = rawTransaction.data.toHexString().addPrefix("0x")
            }
            sendRPC(method:  "cfx_estimateGasAndCollateral", params: [parameters ?? [String: Any]()]).done { (result: EstimateGasAndCollateral) in
                seal.fulfill(EstimateGasAndCollateral(
                    gasLimit: BigInt(result.gasLimit.cfxStripHexPrefix(), radix: 16)?.description ?? "0",
                    gasUsed: BigInt(result.gasUsed.cfxStripHexPrefix(), radix: 16)?.description ?? "0",
                    storageCollateralized: BigInt(result.storageCollateralized.cfxStripHexPrefix(), radix: 16)?.description ?? "0")
                )
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
