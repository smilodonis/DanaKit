//
//  DanaGeneralGetUserOption.swift
//  DanaKit
//
//  Created by Bastiaan Verhaar on 13/12/2023.
//  Copyright © 2023 Randall Knutson. All rights reserved.
//

struct PacketGeneralGetUserOption {
    var isTimeDisplay24H: Bool
    var isButtonScrollOnOff: Bool
    var beepAndAlarm: UInt8
    var lcdOnTimeInSec: UInt8
    var backlightOnTimInSec: UInt8
    var selectedLanguage: UInt8
    var units: UInt8
    var shutdownHour: UInt8
    var lowReservoirRate: UInt8
    var cannulaVolume: UInt16
    var refillAmount: UInt16

    var selectableLanguage1: UInt8
    var selectableLanguage2: UInt8
    var selectableLanguage3: UInt8
    var selectableLanguage4: UInt8
    var selectableLanguage5: UInt8

    /** Only on hw v7+ */
    var targetBg: UInt16?
}

let CommandGeneralGetUserOption = (DanaPacketType.TYPE_RESPONSE & 0xff << 8) + (DanaPacketType.OPCODE_OPTION__GET_USER_OPTION & 0xff)

func generatePacketGeneralGetUserOption() -> DanaGeneratePacket {
    return DanaGeneratePacket(
        opCode: DanaPacketType.OPCODE_OPTION__GET_USER_OPTION,
        data: nil
    )
}

func parsePacketGeneralGetUserOption(data: Data) -> DanaParsePacket<PacketGeneralGetUserOption> {
    return DanaParsePacket(
        success: data[DataStart + 3] >= 5,
        data: PacketGeneralGetUserOption(
            isTimeDisplay24H: data[DataStart] == 0,
            isButtonScrollOnOff: data[DataStart + 1] == 1,
            beepAndAlarm: data[DataStart + 2],
            lcdOnTimeInSec: data[DataStart + 3],
            backlightOnTimInSec: data[DataStart + 4],
            selectedLanguage: data[DataStart + 5],
            units: data[DataStart + 6],
            shutdownHour: data[DataStart + 7],
            lowReservoirRate: data[DataStart + 8],
            cannulaVolume: data.uint16(at: DataStart + 9),
            refillAmount: data.uint16(at: DataStart + 11),
            selectableLanguage1: data[DataStart + 13],
            selectableLanguage2: data[DataStart + 14],
            selectableLanguage3: data[DataStart + 15],
            selectableLanguage4: data[DataStart + 16],
            selectableLanguage5: data[DataStart + 17],
            targetBg: data.count > 22 ? (data.uint16(at: DataStart + 18) / (data[DataStart + 6] == 6 ? 100 : 1)) : nil
        )
    )
}
