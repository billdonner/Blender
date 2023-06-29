import q20kshare

// write a macOS command line program using ArgumentParser to accept a file an array of X, and another with an array of Y and writes a new file containing an array of Z.

import Foundation
import ArgumentParser


enum BlenderError :Error {
  case cantRead
  case badInputURL
  case noChallenges
}

//write a function to merge arrays X and Y according to "id"
func blend(opinions:[Opinion], challenges:[Challenge]) -> [Challenge] {
    var mergedArray: [Challenge] = []
    for o in opinions {
        for c in challenges {
            if o.id == c.id {
              let z = Challenge(question: c.question, topic: c.topic, hint: c.hint, answers: c.answers, correct: c.correct ,id: c.id,source:c.aisource, prompt:c.prompt, opinions:[o])
              mergedArray.append(z)
            }
        }
    }
    return mergedArray
}
//

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
    
    var newChallenges = blend(opinions: opinions, challenges: challenges)
    
    print(">Blender: \(newChallenges.count) Merged")

    
    
    //sort by topic
    newChallenges.sort(){ a,b in
      return a.topic < b.topic
    }
    //separate challenges by topic and make an array of GameDatas
    var topicCount = 0
    var gameDatum : [ GameData] = []
    var lastTopic: String? = nil
    var theseChallenges : [Challenge] = []
    for challenge in newChallenges {
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

    //gamedata is good for writing
    if let outputPath = outputPath {
      let encoder = JSONEncoder()
      encoder.outputFormatting = .prettyPrinted
      let data = try encoder.encode(gameDatum)
      try data.write(to:URL(fileURLWithPath: outputPath))
      print(">Blender wrote \(data.count) bytes to \(outputPath)")
    }
    
    
    let elapsed = Date().timeIntervalSince(start_time)
    print(">Blender finished in \(elapsed)secs")
  }
}

Blender.main()
