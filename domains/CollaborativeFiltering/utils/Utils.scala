package collaborativefiltering

import java.io._
import scala.collection.mutable.{ArrayBuffer,HashMap}
import java.util.Random

/**
Handles all the helper functionality around the CollaborativeFiltering task.
 - Inspects, splits, strips collaborative filtering datasets.
 - Evaluates program predictions.
*/
object Utils {
  def foreachLine(path:String, f : String => Any) = {
    try {
      val in = new BufferedReader(new InputStreamReader(new FileInputStream(path)))
      var done = false
      var i = 0
      while (!done) {
        val line = in.readLine()
        i += 1
        if (line == null) done = true
        else try {
          f(line)
        } catch {
          case e => throw new RuntimeException("Invalid format on line "+i+": '" + line + "' because " + e)
        }
      }
      in.close
    } catch {
      case _ => throw new RuntimeException("Unable to open file: " + path)
    }
  }
  def writeLines(path:String, doAll:((String=>Any)=>Any)) = {
    try {
      val out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(path)))
      doAll(out.println(_))
      out.close
    } catch {
      case _ => throw new RuntimeException("Unable to write file: " + path)
    }
  }

  def parseIndex(s:String) = {
    val i = s.toInt
    if (i < 1) throw new IllegalArgumentException("index must be positive, but got " + i)
    i
  }

  case class Datum(i:Int, j:Int, x:Double) {
    override def toString = i + " " + j + " " + x
  }

  def parseLine(line:String) = {
    val tokens = line.split(" ")
    if (tokens.size != 3) throw new IllegalArgumentException("expected 3 tokens, got " + tokens.size)
    val i = parseIndex(tokens(0))
    val j = parseIndex(tokens(1))
    val x = tokens(2).toDouble
    Datum(i, j, x)
  }

  def readLines(path:String) = {
    val lines = new ArrayBuffer[String]
    foreachLine(path, { line:String =>
      lines += line
    })
    lines.toArray
  }
  def readData(path:String) = readLines(path).map(parseLine)

  def writeStatus(pairs:(String,Any)*) = {
    writeLines("status", { puts:(String=>Any) =>
      pairs.foreach { pair =>
        puts(pair._1 + ": " + pair._2)
      }
    })
  }

  def inspect(path:String) = {
    var maxi = 0.0
    var maxj = 0.0
    var minx = Math.MAX_DOUBLE
    var maxx = Math.MIN_DOUBLE
    var n = 0
    readData(path).foreach { d:Datum =>
      maxi = maxi max d.i
      maxj = maxj max d.j
      minx = minx min d.x
      maxx = maxx max d.x
      n += 1
    }
    writeStatus("numExamples" -> n, "numRows" -> maxi, "numCols" -> maxj, "minLabelValue" -> minx, "maxLabelValue" -> maxx)
  }

  val trainFrac = 0.7
  def split(rawPath:String, trainPath:String, testPath:String) = {
    // The complexity of this algorithm comes from the fact that for each point in the test set,
    // there must exist a training point for which either the row or column agrees
    // Algorithm:
    //   - Start out with everything in the training data
    //   - While we want more test data, choose a training point at random
    //     and move it to the test data if possible; if not, mark it as training forever
    val random = new Random(1)
    val data = readData(rawPath)
    // 0            l             t                    u          n
    // train        candidates    target fraction      test
    // Keep a range of data points between l and u as candidates
    var l = 0 // Index of first candidate
    val n = data.size
    var u = n // Index of first test
    val t = (trainFrac * n).ceil.toInt // Target division

    // Invariant: statistics of 0...u
    // u...n are okay as test so long 0...u are train
    val iHits = new HashMap[Int,Int]
    val jHits = new HashMap[Int,Int]
    data.foreach { d =>
      iHits(d.i) = iHits.getOrElse(d.i, 0) + 1
      jHits(d.j) = jHits.getOrElse(d.j, 0) + 1
    }

    def allowTest(d:Datum) = iHits(d.i) > 1 || jHits(d.j) > 1

    def swap(a:Int, b:Int) = {
      val tmp = data(a)
      data(a) = data(b)
      data(b) = tmp
    }

    // While still candidates left and haven't gotten enough test examples...
    while (l < u && t < u) {
      val m = l + random.nextInt(u-l)
      val d = data(m)
      if (allowTest(d)) { // Allow to be test
        //println("ALLOW " + d)
        swap(m, u-1); u -= 1
        iHits(d.i) -= 1
        jHits(d.j) -= 1
      }
      else { // Must be train and always will be train
        swap(m, l); l += 1
      }
    }

    println("n="+n+" total examples, aiming for t="+t+" training, but actually allocated u="+u)
    println("l="+l+" mandatory training examples")

    def dump(path:String, a:Int, b:Int) = {
      writeLines(path, { puts:(String=>Any) =>
        (a to b-1).foreach { c:Int =>
          puts(data(c).toString)
        }
      })
    }

    dump(trainPath, 0, u)
    dump(testPath, u, n)
  }

  def stripLabels(inPath:String, outPath:String) = {
    writeLines(outPath, { puts:(String=>Any) =>
      foreachLine(inPath, { line:String =>
        val tokens = line.split(" ")
        tokens(2) = "0" // Replace with neutral value
        puts(tokens.mkString(" "))
      })
    })
  }

  def evaluate(truePath:String, predPath:String) = {
    var squaredError = 0.0
    var absoluteError = 0.0
    val truexs = readData(truePath).map(_.x)
    val predxs = readLines(predPath).map(_.toDouble).map { x:Double =>
      if (!x.isNaN && !x.isInfinite) x
      else throw new RuntimeException("Your predictions contain an non-valid number: " + x)
    }
    if (truexs.size != predxs.size) throw new RuntimeException("Expected " + truexs.size + " predictions, but got " + predxs.size)
    val n = truexs.size
    (0 to n-1).foreach { k:Int =>
      val e = (truexs(k) - predxs(k)).abs
      squaredError += e*e
      absoluteError += e
    }
    writeStatus("numExamples" -> n, "meanSquaredError" -> squaredError/n,
      "rootMeanSquaredError" -> Math.sqrt(squaredError/n), "meanAbsoluteError" -> absoluteError/n)
  }

  def main(args:Array[String]) = {
    if (args.size < 1) { 
      println("Usage: inspect|split|stripLabels|evaluate <args>")
      exit(1)
    }
    else {
      args(0) match {
        case "inspect" => inspect(args(1))
        case "split" => split(args(1), args(2), args(3))
        case "stripLabels" => stripLabels(args(1), args(2))
        case "evaluate" => evaluate(args(1), args(2))
        case _ =>
      }
    }
  }
}
