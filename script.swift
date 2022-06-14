#!/usr/bin/env swift

import Foundation

var pathFile: String?
var outDirectory: String?
var id = 1

enum Constants: String {
    case html
    case srt
    
    func description() -> String {
        return self.rawValue
    }
}

enum FileManagerErrors: Error {
    case fileNotSaved
    case numberOfArguments
}

struct Caption {
    var id: Int
    var text: String
    var startTime: Double
}

func createTime(seconds sec: Double) -> (Int, Int, Int) {
    var minutes: Int = Int(sec / 60)
    let seconds = Int(sec) - minutes * 60
    var hour: Int = 0
    
    if minutes > 60 {
        hour = Int(minutes / 60)
        minutes = minutes - hour * 60
    }
    
    return (hour, minutes, seconds)
}

func createDigitStr(digit: Int) -> String {
    return digit < 10 ? "0\(digit)" : String(digit)
}

func createTimeStr(seconds sec: Double) -> (String, String, String) {
    let (hour, minutes, seconds) = createTime(seconds: sec)
    
    let hourStr = createDigitStr(digit: hour)
    let minutesStr = createDigitStr(digit: minutes)
    let secondsStr = createDigitStr(digit: seconds)
    
    return (hourStr, minutesStr, secondsStr)
}

func createOutString(caprion: Caption, nextTime: (String, String, String)) -> String {
    let (hour, minutes, seconds) = createTimeStr(seconds: caprion.startTime)
    
    let idStr = "\(caprion.id)"
    let timeStr = "\(hour):\(minutes):\(seconds),000 --> \(nextTime.0):\(nextTime.1):\(nextTime.2),000"
    
    return idStr + "\n" + timeStr + "\n" + caprion.text + "\n\n"
}

func matches(regex: String?, text: String?) -> [String]? {
    guard let regex = regex, let text = text else {
        return nil
    }
    
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("Invalid regex: \(error.localizedDescription)")
        return nil
    }
}

func parseDataFromHTML(forResource: String?) -> String? {
    guard let forResource = forResource,
          let str = readInputDataFromFile(forResource: forResource) else { return nil }
    
    var findIndex: Int?
    
    let strs = str.components(separatedBy: "\n")
    strs.indices.forEach { index in
        let str = strs[index]
            
        if str.contains("<div class=\"margin-bottom-small download-transcript\"><span id=\"get-transcript\" class=\"icon icon-before icon-downloadcircle") {
            findIndex = index + 1 // element after HTML template
        }
    }

    guard let findIndex = findIndex,
          findIndex < strs.count else { return nil }
    
    var caprions: [Caption] = []
    
    strs[findIndex]
        .components(separatedBy: "class=\"sentence\"")
        .forEach { str in
            // get Time
            var regex: String = "/?time=[0-9]+"
            var matchStr = matches(regex: regex, text: str)?.first
            regex = "[0-9]+"
            var digit: Double?
            if let matchStr = matchStr, let clearStrDigit = matches(regex: regex, text: matchStr)?.first {
                digit = Double(clearStrDigit)
            }
            
            // get Text
            regex = "\">[а-яА-Яa-zA-Z ,.!?0-9]+"
            matchStr = matches(regex: regex, text: str)?.first
            regex = "[а-яА-Яa-zA-Z ,.!?0-9]+"
            matchStr = matches(regex: regex, text: matchStr)?.first
            if let digit = digit, let matchStr = matchStr {
                caprions.append(
                    Caption(id: id,
                            text: matchStr,
                            startTime: digit)
                )
                id += 1
            }
        }
    
    /*
     1097
     01:20:45,138 --> 01:20:48,164
     You'd say anything now
     to get what you want.
     */
    
    guard let lastCaprion = caprions.last else { return nil }
    let newCaprion = Caption(id: id,
                                 text: "",
                                 startTime: lastCaprion.startTime + 1.0)
    caprions.append(newCaprion)
    
    var outStr = ""
    
    for i in 0 ..< caprions.count - 1 {
        let time = createTimeStr(seconds: caprions[i + 1].startTime)
        outStr += createOutString(caprion: caprions[i],
                                  nextTime: time)
    }
    
    return outStr
}

func fetchFileName() -> String? {
    let filename = pathFile?
        .components(separatedBy: "/")
        .last?
        .replacingOccurrences(of: Constants.html.description(),
                              with: Constants.srt.description())
    return filename
}

func readInputDataFromFile(forResource: String) -> String? {
    do {
        return try String(contentsOfFile: forResource, encoding: .utf8)
    } catch let error {
        print(#function, error.localizedDescription)
        return nil
    }
}

func writeOutDataToFile(str: String) throws {
    guard let outDirectory = outDirectory,
          let fileName = fetchFileName(),
          let data = str.data(using: .utf8) else { return }
    
    let isSaved = FileManager.default.createFile(atPath: outDirectory + "/" + fileName, contents: data)
    if !isSaved {
        throw FileManagerErrors.fileNotSaved
    }
}

func readCommandLineArguments() throws {
    if CommandLine.argc != 3 {
        throw FileManagerErrors.numberOfArguments
    }
    
    let arguments = CommandLine.arguments
    pathFile = arguments[1]
    outDirectory = arguments[2]
}

do {
    try readCommandLineArguments()
    
    if let outString = parseDataFromHTML(
        forResource: pathFile
    ) {
        try writeOutDataToFile(str: outString)
        print("Task completed!")
    }
} catch let error {
    print("Error:", error.localizedDescription)
}
