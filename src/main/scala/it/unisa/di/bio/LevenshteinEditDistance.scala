package it.unisa.di.bio


import it.unisa.di.bio.DatasetBuilder.{GCReachDist, appProperties, debug, gValues, getDistribution, getNullModelFilename, getSequenceName, hadoopConf, local, mitocondriDist, numberOfPairs, patternLen, patternTransfer, savePath, saveSequence, sc, shigellaDist, uniformDist}
import it.unisa.di.bio.Misc.nucleotideRepr
import org.apache.hadoop.fs.{FileSystem, Path}
import org.apache.spark.{SparkConf, SparkContext}

import java.io.{FileNotFoundException, IOException}
import java.util.Properties
import scala.io.BufferedSource
import it.unimi.dsi.fastutil.longs.Long2IntOpenHashMap



object LevenshteinEditDistance {

  class SparseMatrix(var size: Int) {

    private val map = new Long2IntOpenHashMap( size)

    def get(x: Int, y: Int ): Int = {
      val key : Long = (x.toLong << 32) + y
      val ret = map.getOrDefault(key, -1)
      return ret
    }
    def set(x: Int, y: Int, value: Int ) = {
      val key : Long = (x.toLong << 32) + y
      map.put( key, value)
    }
  }


  def main(args: Array[String]) {

    if (args.length < 2) {
      System.err.println("Errore nei parametri sulla command line")
      System.err.println("Usage:\nit.unisa.di.bio.LevenshteinEditDistance inputDataSet [[local|yarn]")
      throw new IllegalArgumentException(s"illegal number of argouments. ${args.length} should be at least 2")
      return
    }

    val inputPath = args(0)

    if (args.length > 1) {
      local = (args(1) == "local")
    }


    val sparkConf = new SparkConf().setAppName("LevenshteinEditDistance")
      .setMaster(if (local) "local" else "yarn")
    sc = new SparkContext(sparkConf)
    hadoopConf = sc.hadoopConfiguration

    println(s"***App ${this.getClass.getCanonicalName} Started***")

    var reader: BufferedSource = null
    var seq1: String = null
    var seq2: String = null

    try {
      if (local) {
        // legge dal filesystem locale
        reader = scala.io.Source.fromFile(inputPath)
      }
      else {
        // solo questo codice legge dal HDFS Source.fromFile legge solo da file system locali
        // val hdfs = FileSystem.get(new URI("hdfs://master:8020/"), new Configuration())
        val hdfs = FileSystem.get(sc.hadoopConfiguration)
        val path = new Path(inputPath)
        val stream = hdfs.open(path)
        reader = scala.io.Source.fromInputStream(stream)
      }

      var i = 1
      val it : Iterator[String] = reader.getLines()
      // per tutte le sequenze nel file input
      while (it.hasNext) {
        var seqHeader = it.next()
        seq1 = it.next().toString
        seqHeader = it.next();
        seq2 = it.next().toString
        i += 1

        var startTime = System.currentTimeMillis()
        var d = distanceMatrix(seq1, seq2)
        var totTime = System.currentTimeMillis() - startTime
        println (s"The edit distance (matrix) between seq1 and seq2 (len=${seq1.length}) is ${d}, delay:${totTime/1000} sec.")

        startTime = System.currentTimeMillis()
        d = distanceSparse(seq1, seq2)
        totTime = System.currentTimeMillis() - startTime
        println (s"The edit distance (sparse) between seq1 and seq2 (len=${seq2.length}) is ${d}, delay:${totTime/1000} sec.")
      }
    }
    catch {
      case x: FileNotFoundException => {
        println(s"Exception: Input dataset ${inputPath} not found")
      }
      case x: IOException   => {
        println("Input/output Exception")
      }
    }
  }



  def  distanceSparse (word1: String,word2: String) : Int = {

    // val matrix = Array.ofDim[Int](word1.length + 1, word2.length + 1)
    val matrix = new SparseMatrix(word1.length * 10)

    for (i <- 0 to word1.length) {
      // matrix(i)(0) = i
      matrix.set(i, 0, i)
    }
    for (i <- 0 to word2.length) {
      // matrix(0)(i) = i
      matrix.set(0, i, i)
    }

    for (i <- 1 to word1.length) {
      var c1: Char = 0

      c1 = word1.charAt(i - 1)
      for (j <- 1 to word2.length) {
        var c2: Char = 0

        c2 = word2.charAt(j - 1)
        if (c1 == c2) {
          // matrix(i)(j) = matrix(i-1)(j-1)
          matrix.set(i, j, matrix.get(i - 1, j - 1))
        }
        else {
          var delete = 0
          var insert = 0
          var substitute = 0
          var minimum = 0

          // delete = matrix(i-1)(j) + 1
          delete = matrix.get(i - 1, j) + 1
          // insert = matrix(i)(j-1) + 1
          insert = matrix.get(i, j - 1) + 1
          // substitute = matrix(i-1)(j-1) + 1
          substitute = matrix.get(i - 1, j - 1) + 1
          minimum = delete
          if (insert < minimum) {
            minimum = insert
          }
          if (substitute < minimum) {
            minimum = substitute
          }
          // matrix(i)(j) = minimum
          matrix.set(i, j, minimum)
        }
      }
    }
    return matrix.get(word1.length, word2.length)
  }


  def  distanceMatrix (word1: String,word2: String) : Int = {

    val matrix = Array.ofDim[Int](word1.length + 1, word2.length + 1)

    for (i <- 0 to word1.length) {
      matrix(i)(0) = i
    }
    for (i <- 0 to word2.length) {
      matrix(0)(i) = i
    }

    for (i <- 1 to word1.length) {
      var c1: Char = 0

      c1 = word1.charAt(i - 1)
      for (j <- 1 to word2.length) {
        var c2: Char = 0

        c2 = word2.charAt(j - 1)
        if (c1 == c2) {
          matrix(i)(j) = matrix(i-1)(j-1)
        }
        else {
          var delete = 0
          var insert = 0
          var substitute = 0
          var minimum = 0

          delete = matrix(i-1)(j) + 1
          insert = matrix(i)(j-1) + 1
          substitute = matrix(i-1)(j-1) + 1
          minimum = delete
          if (insert < minimum) {
            minimum = insert
          }
          if (substitute < minimum) {
            minimum = substitute
          }
          matrix(i)(j) = minimum
        }
      }
    }
    return matrix(word1.length)(word2.length)
  }
}
