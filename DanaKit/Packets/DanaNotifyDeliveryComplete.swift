//
//  DanaNotifyDeliveryComplete.swift
//  DanaKit
//
//  Created by Bastiaan Verhaar on 13/12/2023.
//  Copyright © 2023 Randall Knutson. All rights reserved.
//

struct PacketNotifyDeliveryComplete {
    var deliveredInsulin: Double
}

let CommandNotifyDeliveryComplete = (DanaPacketType.TYPE_NOTIFY & 0xff << 8) + (DanaPacketType.OPCODE_NOTIFY__DELIVERY_COMPLETE & 0xff)

func parsePacketNotifyDeliveryComplete(data: Data) -> DanaParsePacket<PacketNotifyDeliveryComplete> {
    return DanaParsePacket(
        success: true,
        notifyType: CommandNotifyDeliveryComplete,
        data: PacketNotifyDeliveryComplete(
            deliveredInsulin: Double(data.uint16(at: DataStart)) / 100
        )
    )
}
