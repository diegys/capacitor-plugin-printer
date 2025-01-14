import Foundation
import Capacitor
import BRLMPrinterKit

func base64ToURL(base64String: String) -> URL? {
  guard let data = Data(base64Encoded: base64String) else {
    return nil
  }
  
  let tempDirectory = FileManager.default.temporaryDirectory
  let fileName = UUID().uuidString
  let fileURL = tempDirectory.appendingPathComponent(fileName)
  
  do {
    try data.write(to: fileURL)
    return fileURL
  } catch {
    print("Error writing data to file: \(error)")
    return nil
  }
}


func printImageWithBluetooth(base64String : String) -> Optional {
    guard let imageURL = base64ToURL(base64String: base64String) else { return false }
    let channels = BRLMPrinterSearcher.startBluetoothSearch().channels

    if (channels.count >= 1) {
        let channel = channels[0]
        let genRes = BRLMPrinterDriverGenerator.open(channel)
        guard genRes.error.code == BRLMOpenChannelErrorCode.noError,
              let printerDriver = genRes.driver else {
            print("error");
            return false
        }
        defer {
            printerDriver.closeChannel()
        }
        guard
            let printSettings = BRLMQLPrintSettings(defaultPrintSettingsWith: BRLMPrinterModel.QL_820NWB)
        else {
            print("error");
            return false
        }
        printSettings.autoCut = true
        let printError = printerDriver.printImage(with: imageURL, settings: printSettings)
        if (printError.code == .noError) {
            print("error");
            return true
        } else {
            return false
        }
    }
    return false
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
                           if let bluetoothPrint = printImageWithBluetooth(base64String : base64String) {
                                call.resolve([
                                    "message": "success",
                                    "value": content,
                                    "name": jobName
                                ])
                            } else {
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
                        if let bluetoothPrint = printImageWithBluetooth(base64String: base64String) {
                            call.resolve([
                                "message": "success",
                                "value": content,
                                "name": jobName
                            ])
                        } else {
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
