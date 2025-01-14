import Foundation
import Capacitor
import BRLMPrinterKit

func printImageWithBluetooth(image : String) {
    let channels = BRLMPrinterSearcher.startBluetoothSearch().channels

    if (channels.count >= 1) {
        let channel = channels[0]
        let genRes = BRLMPrinterDriverGenerator.open(channel)
        guard genRes.error.code == BRLMOpenChannelErrorCode.noError,
              let printerDriver = genRes.driver else {
            print("error");
            return
        }
        defer {
            printerDriver.closeChannel()
        }
        guard
            let imageData = image
            let printSettings = BRMQLPrintSettings(defaultPrintSettingsWith: channel.printerModel)
        else {
            print("error");
            return
        }
        printSettings.autoCut = true
        printSettings.labeSize = channel.labelSize;
        let printError = printerDriver.printImage(with: imageData, settings: printSettings)
        if (printError.code != .noError) {
            print("error");
            return
        }
    }
}

@objc(PrinterPlugin)
public class PrinterPlugin: CAPPlugin {
    @objc func print(_ call: CAPPluginCall) {
        let content = call.getString("content") ?? ""
        let printController = UIPrintInteractionController.shared
        let jobName = call.getString("name") ?? ""
        let orientation = call.getString("orientation") ?? ""
        if content.starts(with: "base64:") {
            if content.contains("data:") {
                if let base64Index = content.range(of: ",")?.upperBound {
                    let base64String = String(content[base64Index...])
                    
                    if let documentData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
                        DispatchQueue.main.async {
                            let bluetoothPrint = printImageWithBluetooth(documentData);
                            if (printError.code != .noError) {
                                let printInfo = UIPrintInfo(dictionary: nil)
                                printInfo.jobName = jobName
                                printInfo.outputType = .general
                                if orientation == "landscape" {
                                    printInfo.orientation = .landscape
                                } else if orientation == "portrait" {
                                    printInfo.orientation = .portrait
                                }
                                
                                printController.printInfo = printInfo
                                printController.printingItem = documentData
                                printController.present(animated: true, completionHandler: nil)
                                
                                call.resolve([
                                    "message": "success",
                                    "value": content,
                                    "name": jobName
                                ])
                            } else {
                                call.resolve([
                                    "message": "success",
                                    "value": content,
                                    "name": jobName
                                ])
                            }
                        }
                        return
                    } else {
                        call.reject("Invalid dataUri data")
                        return
                    }
                } else {
                    call.reject("Invalid dataUri format")
                    return
                }
            } else {
                let base64String = content.replacingOccurrences(of: "base64:", with: "")

                if let documentData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
                    DispatchQueue.main.async {
                        let bluetoothPrint = printImageWithBluetooth(documentData);
                        if (printError.code != .noError) {
                            let printInfo = UIPrintInfo(dictionary: nil)
                            printInfo.jobName = jobName
                            printInfo.outputType = .general
                            if orientation == "landscape" {
                                printInfo.orientation = .landscape
                            } else if orientation == "portrait" {
                                printInfo.orientation = .portrait
                            }
                            
                            printController.printInfo = printInfo
                            printController.printingItem = documentData
                            printController.present(animated: true, completionHandler: nil)
                            
                            call.resolve([
                                "message": "success",
                                "value": content,
                                "name": jobName
                            ])
                        } else {
                            call.resolve([
                                "message": "success",
                                "value": content,
                                "name": jobName
                            ])
                        }
 
                    }
                    return
                } else {
                    call.reject("Invalid Base64 data")
                    return
                }
            }
        } else {
            call.reject("Invalid content")
            return
        }
    }
}
