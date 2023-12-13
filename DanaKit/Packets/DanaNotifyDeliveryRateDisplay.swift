//
//  DanaNotifyDeliveryRateDisplay.swift
//  
//
//  Created by Bastiaan Verhaar on 13/12/2023.
//

struct PacketNotifyDeliveryRateDisplay {
    var deliveredInsulin: Double
}

let CommandNotifyDeliveryRateDisplay = (DanaPacketType.TYPE_NOTIFY & 0xff << 8) + (DanaPacketType.OPCODE_NOTIFY__DELIVERY_RATE_DISPLAY & 0xff)

func parsePacketNotifyDeliveryRateDisplay(data: Data) -> DanaParsePacket<PacketNotifyDeliveryRateDisplay> {
    return DanaParsePacket(
        success: true,
        notifyType: CommandNotifyDeliveryRateDisplay,
        data: PacketNotifyDeliveryRateDisplay(
            deliveredInsulin: Double(data.uint16(at: DataStart)) / 100
        )
    )
}
