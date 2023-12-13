//
//  DanaGeneralGetShippingInformation.swift
//  DanaKit
//
//  Created by Bastiaan Verhaar on 13/12/2023.
//  Copyright © 2023 Randall Knutson. All rights reserved.
//

struct PacketGeneralGetShippingInformation {
    var serialNumber: String
    var shippingCountry: String
    var shippingDate: Date
}

let CommandGeneralGetShippingInformation =
    (DanaPacketType.TYPE_RESPONSE & 0xff << 8) + (DanaPacketType.OPCODE_REVIEW__GET_SHIPPING_INFORMATION & 0xff)

func generatePacketGeneralGetShippingInformation() -> DanaGeneratePacket {
    return DanaGeneratePacket(
        opCode: DanaPacketType.OPCODE_REVIEW__GET_SHIPPING_INFORMATION,
        data: nil
    )
}

func parsePacketGeneralGetShippingInformation(data: Data) -> DanaParsePacket<PacketGeneralGetShippingInformation> {
    guard data.count >= 18 else {
        return DanaParsePacket(
            success: false,
            data: PacketGeneralGetShippingInformation(
                serialNumber: "",
                shippingCountry: "",
                shippingDate: Date()
            )
        )
    }

    let serialNumberData = data.subdata(in: DataStart..<DataStart + 10)
    let shippingCountryData = data.subdata(in: DataStart + 10..<DataStart + 13)

    let serialNumber = String(data: serialNumberData, encoding: .utf8) ?? ""
    let shippingCountry = String(data: shippingCountryData, encoding: .utf8) ?? ""

    let shippingDate = DateComponents(
        calendar: .current,
        year: 2000 + Int(data[DataStart + 13]),
        month: Int(data[DataStart + 14]) - 1,
        day: Int(data[DataStart + 15]),
        hour: 0,
        minute: 0,
        second: 0
    )

    guard let parsedDate = Calendar.current.date(from: shippingDate) else {
        // Handle error, if needed
        return DanaParsePacket(success: false, data: nil)
    }

    return DanaParsePacket(
        success: true,
        data: PacketGeneralGetShippingInformation(
            serialNumber: serialNumber,
            shippingCountry: shippingCountry,
            shippingDate: parsedDate
        )
    )
}
