//
//  DanaGeneralGetPumpTime.swift
//  DanaKit
//
//  Created by Bastiaan Verhaar on 13/12/2023.
//  Copyright © 2023 Randall Knutson. All rights reserved.
//

struct PacketGeneralGetPumpTime {
    var time: Date
}

let CommandGeneralGetPumpTime = (DanaPacketType.TYPE_RESPONSE & 0xff << 8) + (DanaPacketType.OPCODE_OPTION__GET_PUMP_TIME & 0xff)

func generatePacketGeneralGetPumpTime() -> DanaGeneratePacket {
    return DanaGeneratePacket(
        opCode: DanaPacketType.OPCODE_OPTION__GET_PUMP_TIME,
        data: nil
    )
}

func parsePacketGeneralGetPumpTime(data: Data) -> DanaParsePacket<PacketGeneralGetPumpTime> {
    let time = DateComponents(
        year: 2000 + Int(data[DataStart]),
        month: Int(data[DataStart + 1]),
        day: Int(data[DataStart + 2]),
        hour: Int(data[DataStart + 3]),
        minute: Int(data[DataStart + 4]),
        second: Int(data[DataStart + 5])
    )

    guard let parsedTime = Calendar.current.date(from: time) else {
        // Handle error, if needed
        return DanaParsePacket(success: false, data: nil)
    }

    return DanaParsePacket(
        success: true,
        data: PacketGeneralGetPumpTime(time: parsedTime)
    )
}
