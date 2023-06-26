import q20kshare

// write a macOS command line program using ArgumentParser to accept a file an array of X, and another with an array of Y and writes a new file containing an array of Z.

import Foundation
import ArgumentParser

//func testBlend () {
//  let x1 = Challenge(question: "Why sky blue?", topic: "sky", hint: "not green", answers: ["red","yellow","green"], correct: "green",id:"sky-blue")
//  let x2 = Challenge(question: "Why sky yellow?", topic: "sky", hint: "not green", answers: ["red","yellow","green"], correct: "yellow",id:"yellow-belly")
//  let y1 = Opinion(id: "sky-blue",  truth: true, explanation: "blee blue,", source: "fakeA")
//  let y2 = Opinion(id: "sky-blue",  truth: false, explanation: "blee yellow,", source: "fakeB")
//
//  let x = [x1,x2]
//  let y = [y1,y2]
//
//  let z = blend(x:y,y:x)
//  for zz in z {
//    print(zz)
//  }
//
//}

enum BlenderError :Error {
  case cantRead
  case badInputURL
  case noChallenges
}

//write a function to merge arrays X and Y according to "id"
func blend(x:[Opinion], y:[Challenge]) -> [Challenge] {
    var mergedArray: [Challenge] = []
    for o in x {
        for c in y {
            if o.id == c.id {
              let z = Challenge(question: c.question, topic: c.topic, hint: c.hint, answers: c.answers, correct: c.correct ,id: UUID().uuidString,opinions:[o])
              mergedArray.append(z)
            }
        }
    }
    return mergedArray
}
//sort both arrays before merging
func mergeArrays(x:[Opinion], y:[Challenge]) -> [Challenge]  {
  
  //sort both Arrays
  let sortedX = x.sorted(by:{ $0.id > $1.id })
  let sortedY = y.sorted(by:{ $0.id > $1.id })
  
  // declare the empty output Array
  var mergedArray = [Challenge]()
  
  //track the index of the arrays
  var xIndex = 0
  var yIndex = 0
  
  //loop through both sorted Arrays
  while((xIndex<sortedX.count) && (yIndex<sortedY.count)) {
    
    let xId = sortedX[xIndex].id
    let yId = sortedY[yIndex].id
    
    //check if ID's in each array are equal
    if (xId == yId) {
      let bb = sortedX[xIndex]
      let yy = sortedY[yIndex]
      
      //create Z object
      let z = Challenge(question: yy.question, topic: yy.topic, hint: yy.hint, answers: yy.answers, correct: yy.correct ,id: UUID().uuidString,opinions:[bb])
      mergedArray.append(z)
      
      //increment both indices
      xIndex+=1
      yIndex+=1
    }
    //if xId higher then yId
    else if (xId > yId) {
      yIndex+=1
    }
    //if yId higher then xId
    else {
      xIndex+=1
    }
  }
  return mergedArray
}



fileprivate func fixupJSON(   data: Data, url: String)throws -> [Challenge] {
  // see if missing ] at end and fix it\
  do {
    return try Challenge.decodeArrayFrom(data: data)
  }
  catch {
    print("****Trying to recover from decoding error, \(error)")
    if let s = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
      if !s.hasSuffix("]") {
        if let v = String(s+"]").data(using:.utf8) {
          do {
            let x = try Challenge.decodeArrayFrom(data: v)
            print("****Fixup Succeeded by adding a ]. There is nothing to do")
            return x
          }
          catch {
            print("****Can't read Challenges from \(url), error: \(error)" )
            throw BlenderError.badInputURL
          }
        }
      }
    }
  }
  throw BlenderError.noChallenges
}
fileprivate func writeAsJSON<T:Encodable>(_ data: [T], _ outurl: URL) throws -> Int {
  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted
  var bc = 0
  do {
    let data = try encoder.encode(data)
    let json = String(data:data,encoding: .utf8)
    if let json  {
      bc = json.count
      try json.write(to: outurl, atomically: false, encoding: .utf8)
    }
  }
  return bc
}


func writeOutputFiles(_ urls:[String], gameFile:String)
{
  var allChallenges:[Challenge] = []
  var topicCount = 0
  var fileCount = 0
  let start_time = Date()
  
  let fj = gameFile + "-gamedata.json"
  let gamedataURL = URL(string:fj)
  guard let gamedataURL = gamedataURL else { return }
  for url in urls {
    // read all the urls again
    guard let u = URL(string:url) else {
      print("Cant read url \(url)")
      continue
    }
    do {
      fileCount += 1
      let data = try Data(contentsOf: u)
      allChallenges =  try fixupJSON(data:data,  url:u.absoluteString)
    }
    catch {
      print("Could not re-read \(u) error:\(error)")
      continue
    }
    print(">Blender reading from \(url)")
    //sort by topic
    allChallenges.sort(){ a,b in
      return a.topic < b.topic
    }
    //separate challenges by topic and make an array of GameDatas
    var gameDatum : [ GameData] = []
    var lastTopic: String? = nil
    var theseChallenges : [Challenge] = []
    for challenge in allChallenges {
      // print(challenge.topic,lastTopic)
      if let last = lastTopic  {
        if challenge.topic != last {
          gameDatum.append( GameData(subject:last,challenges: theseChallenges))
          theseChallenges = []
          topicCount += 1
        }
      }
      // append this challenge and set topic
      theseChallenges += [challenge]
      lastTopic = challenge.topic
      
    }
    if let last = lastTopic {
      topicCount += 1
      gameDatum.append( GameData(subject:last,challenges: theseChallenges)) //include remainders
    }
    // compute truth challenges
    var cha:[TruthQuery] = []
    for gd in gameDatum {
      for ch in gd.challenges {
        cha.append(ch.makeTruthQuery())
      }
    }
    do{
      // write Challenges as JSON to file
      let bc = try writeAsJSON(gameDatum, gamedataURL)
      let elapsed = Date().timeIntervalSince(start_time)
      print(">Wrote \(bc) bytes, \(allChallenges.count) challenges, \(topicCount) topics to \(gamedataURL) in elapsed \(elapsed) secs")
    }
    catch {
      print("Utterly failed to write json file \(gamedataURL)/n \(error)")
    }
  }
}




struct Blender: ParsableCommand {
  
  static let configuration = CommandConfiguration(
    abstract: "Step 4: Blender merges the data from Veracitator with the data from Prepper and prepares a single output file of gamedata - ReadyforIOS.",
    version: "0.2.1",
    subcommands: [],
    defaultSubcommand: nil,
    helpNames: [.long, .short]
  )
  
  @Argument(help: "input file of Challenges (Between_1_2.json)")
  var xPath:String
  
  @Argument(help: "input file of Opinions (Between_3_4.json)")
  var yPath:String
  
  @Option(name:.shortAndLong, help: "New File of Gamedata (ReadyForIOSx.json)")
  var outputPath: String?
  
  fileprivate func fetchChallenges(_ challenges: inout [Challenge]) throws {
    let xData = try Data(contentsOf: URL(fileURLWithPath: xPath))
    do {
      challenges = try JSONDecoder().decode([Challenge].self, from: xData)
    }
    catch {
      print("****Trying to recover from Challenge decoding error, \(error)")
      if let s = String(data: xData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
        if !s.hasSuffix("]") {
          if let v = String(s+"]").data(using:.utf8) {
            do {
              challenges = try JSONDecoder().decode([Challenge].self, from: v)
              print("****Fixed by adding trailing ], there is nothing to do")
            }
            catch {
              print("****Can't decode contents of \(xPath), error: \(error)" )
              throw BlenderError.cantRead
            }
          }
        }
      }
    }
  }
  
  fileprivate func fetchOpinions(_ opinions: inout [Opinion]) throws {
    let yData = try Data(contentsOf: URL(fileURLWithPath: yPath))
    do {
      opinions = try JSONDecoder().decode([Opinion].self, from: yData)
    }
    catch {
      print("****Trying to recover from Opinion decoding error, \(error)")
      if let s = String(data: yData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
        if !s.hasSuffix("]") {
          if let v = String(s+"]").data(using:.utf8) {
            do {
              opinions = try JSONDecoder().decode([Opinion].self, from: v)
              print("****Fixed by adding trailing ], there is nothing to do")
            }
            catch {
              print("****Can't read contents of \(yPath), error: \(error)" )
              throw BlenderError.cantRead
            }
          }
        }
      }
    }
  }
  
  func run() throws {
    
    let start_time = Date()
    print(">Blender Command Line: \(CommandLine.arguments)")
    print(">Blender running at \(Date())")
    
    
    //testBlend()
   
    var challenges:[Challenge] = []
    try fetchChallenges(&challenges)
    print(">Blender: \(challenges.count) Challenges")
    
    var opinions:[Opinion] = []
    try fetchOpinions(&opinions)
    print(">Blender: \(opinions.count) Opinions")
    
    let newOpinions = blend(x: opinions, y: challenges)
    print(">Blender: \(newOpinions.count) Merged")

    let zEncoder = JSONEncoder()
    zEncoder.outputFormatting = .prettyPrinted
    let zData = try zEncoder.encode(newOpinions)
    if let outputPath = outputPath {
      try zData.write(to:URL(fileURLWithPath: outputPath))
    } else {
      print(String(data: zData, encoding: .utf8)!)
    }
    
    let elapsed = Date().timeIntervalSince(start_time)
    print(">Blender finished in \(elapsed)secs")
  }
}

Blender.main()
