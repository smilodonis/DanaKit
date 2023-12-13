//
//  DanaGeneralGetShippingVersion.swift
//  DanaKit
//
//  Created by Bastiaan Verhaar on 13/12/2023.
//  Copyright © 2023 Randall Knutson. All rights reserved.
//

struct PacketGeneralGetShippingVersion {
    var bleModel: String
}

let CommandGeneralGetShippingVersion = (DanaPacketType.TYPE_RESPONSE & 0xff << 8) + (DanaPacketType.OPCODE_GENERAL__GET_SHIPPING_VERSION & 0xff)

func generatePacketGeneralGetShippingVersion() -> DanaGeneratePacket {
    return DanaGeneratePacket(
        opCode: DanaPacketType.OPCODE_GENERAL__GET_SHIPPING_VERSION,
        data: nil
    )
}

func parsePacketGeneralGetShippingVersion(data: Data) -> DanaParsePacket<PacketGeneralGetShippingVersion> {
    return DanaParsePacket(
        success: true,
        data: PacketGeneralGetShippingVersion(
            bleModel: String(data: data.subdata(in: DataStart..<data.count), encoding: .utf8) ?? ""
        )
    )
}
