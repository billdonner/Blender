import q20kshare

func testBlend () {
  let x1 = Challenge(question: "Why sky blue?", topic: "sky", hint: "not green", answers: ["red","yellow","green"], correct: "green",id:"sky-blue")
  let x2 = Challenge(question: "Why sky yellow?", topic: "sky", hint: "not green", answers: ["red","yellow","green"], correct: "yellow",id:"yellow-belly")
  let y1 = Opinion(id: "sky-blue",  truth: true, explanation: "blee blue,", source: "fakeA")
  let y2 = Opinion(id: "sky-blue",  truth: false, explanation: "blee yellow,", source: "fakeB")
  
  let x = [x1,x2]
  let y = [y1,y2]
  
  let z = blend(x:y,y:x)
  for zz in z {
    print(zz)
  }
  
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

// write a macOS command line program using ArgumentParser to accept a file an array of X, and another with an array of Y and writes a new file containing an array of Z.

import Foundation
import ArgumentParser
enum BlenderError :Error {
  case cantRead
}

struct Converter: ParsableCommand {
  @Argument(help: "File of Challenges")
  var xPath:String
  
  @Argument(help: "File of Opinions")
  var yPath:String
  
  @Option(name:.shortAndLong, help: "New File of expanded Challenges")
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

Converter.main()
