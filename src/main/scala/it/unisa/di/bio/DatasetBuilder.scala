//
// $Id: DatasetBuilder.scala 1716 2020-08-07 15:25:19Z cattaneo@dia.unisa.it $
//


package it.unisa.di.bio

import java.io.{BufferedWriter, File, FileNotFoundException, IOException, OutputStreamWriter}
import java.net.URI
import java.time.LocalDateTime
import java.util.Properties
import java.time.format.DateTimeFormatter

import it.unisa.di.bio.DatasetBuilder.{buildDatasetWithDistribution, getNullModelFilename, motif}
import org.apache.spark.{SparkConf, SparkContext}
import it.unisa.di.bio.Misc._
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileSystem, Path}
import org.apache.spark.rdd.RDD

import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.BufferedSource
import scala.math._
import scala.tools.cmd.Property



object DatasetBuilder {

  var local = true
  val debug = false

  var sc:  SparkContext = null
  val fileExt: String = "fasta"
  var savePath: String = "data/powerstatistics"
  var appProperties: Properties = null

  var numberOfPairs = 0
  var seqLen = 0
  var patternLen = 5
  var motif = Array('A', 'C', 'C', 'C', 'G')

  var gValues: Array[Double] = null
  val uniformDist: Array[Double] = new Array[Double](4)
  val GCReachDist: Array[Double] = new Array[Double](4)
  val mitocondriDist: Array[Double] = new Array[Double](4)
  val shigellaDist: Array[Double] = new Array[Double](4)

  var hadoopConf: org.apache.hadoop.conf.Configuration = null

  var savedTask : Saver.SaveClosure = null




  def main(args: Array[String]) {

    if (args.length < 2) {
      System.err.println("Errore nei parametri sulla command line")
      System.err.println("Usage:\nit.unisa.di.bio.DatasetBuilder outputDir detailed|synthetic|mitocondri|shigella [[local|yarn] len1 len2 ...]")
      throw new IllegalArgumentException(s"illegal number of argouments. ${args.length} should be at least 2")
      return
    }

    savePath = args(0)
    val datasetType = args(1)
    // gamma = args(4).toDouble
    // motif = getMotif(args(4))

    if (args.length > 2) {
      local = (args(2).compareTo("local") == 0)
    }


    appProperties = new Properties
    appProperties.load(this.getClass.getClassLoader.getResourceAsStream("PowerStatistics.properties"))

    val sparkConf = new SparkConf().setAppName(appProperties.getProperty("powerstatistics.datasetBuilder.appName"))
                                    .setMaster(if (local) "local" else "yarn")
    sc = new SparkContext(sparkConf)
    hadoopConf = sc.hadoopConfiguration

    println(s"***App ${this.getClass.getCanonicalName} Started***")

    numberOfPairs = appProperties.getProperty("powerstatistics.datasetBuilder.numberOfPairs").toInt

    patternLen = appProperties.getProperty("powerstatistics.datasetBuilder.replacePatternLength").toInt

    // Array(0.25, 0.25, 0.25, 0.25) // P(A), P(C), P(G), P(T) probability
    var stVal = appProperties.getProperty("powerstatistics.datasetBuilder.uniformDistribution").split(",")
    for( i <- 0 to 3) {
      uniformDist(i) = stVal(i).toDouble
    }

    // Array(0.166666666666667, 0.333333333333333, 0.333333333333333, 0.166666666666667) // P(A), P(C), P(G), P(T) probability
    stVal = appProperties.getProperty("powerstatistics.datasetBuilder.GCReachDistribution").split(",")
    for( i <- 0 to 3) {
      GCReachDist(i) = stVal(i).toDouble
    }
    stVal = appProperties.getProperty("powerstatistics.datasetBuilder.mitocondriEmpiricalDistribution").split(",")
    for( i <- 0 to 3) {
      mitocondriDist(i) = stVal(i).toDouble
    }
    stVal = appProperties.getProperty("powerstatistics.datasetBuilder.shigellaEmpiricalDistribution").split(",")
    for( i <- 0 to 3) {
      shigellaDist(i) = stVal(i).toDouble
    }

    // Array(0.001, 0.005, 0.01, 0.05, 0.1)
    stVal = appProperties.getProperty("powerstatistics.datasetBuilder.gammaProbabilities").split(",")
    gValues = new Array[Double](stVal.length)
    for( i <- 0 to stVal.length - 1) {
      gValues(i) = stVal(i).toDouble
    }

    motif = appProperties.getProperty("powerstatistics.datasetBuilder.motif").toCharArray

    val bs = appProperties.getProperty("powerstatistics.datasetBuilder.defaultBlockSize").toInt
    hadoopConf.setInt("dfs.blocksize ", bs)

    datasetType match {
      case x if (x.compareTo("detailed") == 0) => datasetDetailed(
        appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"), uniformDist, args)

      case x if (x.compareTo("synthetic") == 0) => dataset2(
        appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"), uniformDist, args)

      case x if (x.compareTo("syntheticMitocondri") == 0) => dataset2(
              appProperties.getProperty("powerstatistics.datasetBuilder.synthMitocondriPrefix"), mitocondriDist, args)

      case x if (x.compareTo("syntheticShigella") == 0) => dataset2(
              appProperties.getProperty("powerstatistics.datasetBuilder.synthShigellaPrefix"), shigellaDist, args)

      case y if (y.compareTo("mitocondri") == 0) => semiSynthetic(
              appProperties.getProperty("powerstatistics.datasetBuilder.syntheticNullModelPrefix.mitocondri"), args)

      case y if (y.compareTo("shigella") == 0) => semiSynthetic(
              appProperties.getProperty("powerstatistics.datasetBuilder.syntheticNullModelPrefix.shigella"), args)

      case z => println(s"${z} must be in: synthetic | syntheticMitocondri | syntheticShigella | Mitocondri | Shigella");
              sc.stop()
    }
//    print(s"${savedTask.closures.length} tasks")
//    // savedTask.closures.foreach(  x => { savedTask.exec( x._1, x._2)})
//    val rdd:RDD[((Seq[Any]) => Unit, Seq[Any])] = sc.parallelize(savedTask.closures)
//
//    println(s"RDD Total Length: ${savedTask.closures.length} / #Partitions: ${rdd.getNumPartitions}")
//    // val mapped = rdd.mapPartitionsWithIndex( processPartition)
//    val mapped = rdd.map( x => {
//      myExec( x._1, x._2)
//    })
//    print( mapped.collect())
  }

//  def myExec(f:(Seq[Any]) => Unit, params: Seq[Any]) : Int = {
//    f( params)
//    return 1
//  }


  def datasetDetailed( nullModelPrefix: String, distribution: Array[Double], lengths: Array[String]) : Unit = {

    var fromLen = 100000
    var maxSeqLen = appProperties.getProperty("powerstatistics.datasetBuilder.maxSequenceLength").toInt
    var step = appProperties.getProperty("powerstatistics.datasetBuilder.lengthStep").toInt

    if (lengths.length > 3) {
      fromLen = lengths(3).toInt
      maxSeqLen = lengths(4).toInt
      step = lengths(5).toInt
    }

    seqLen = fromLen
    while (seqLen <= maxSeqLen ) {
      buildSyntenthicDataset(seqLen, nullModelPrefix, distribution)
      seqLen = seqLen + step;
    }
  }


  def dataset2( nullModelPrefix: String, distribution: Array[Double], lengths: Array[String]) : Unit = {

    if (lengths.length > 3) {
      for( x <- lengths.drop(3)) {
        buildSyntenthicDataset( x.toInt, nullModelPrefix, distribution)
      }
    }
    else {
      val meanValues = Array(10, 25, 50, 75)
      // numberOfPairs viene letto dalla property powerstatistics.datasetBuilder.numberOfPairs
      val maxSeqSize = appProperties.getProperty("powerstatistics.datasetBuilder.maxSequenceLength").toInt
      var bl = 10000
      while (bl <= maxSeqSize * 10) { // l'ultimo sarà il 10% del successore del maxSeqSize

        if (bl >= 1000000)
          hadoopConf.setInt("dfs.blocksize", 67108864)

        for (m <- meanValues) {
          seqLen = bl / 100 * m // prima la divisione altrimenti va in overflow l'integer

          if (seqLen <= maxSeqSize) {
            buildSyntenthicDataset(seqLen, nullModelPrefix, distribution)
          }
        }
        bl = bl * 10;
      }
    }
  }

  def buildSyntenthicDataset( targetLen: Int, nullModelPrefix: String, distribution: Array[Double]) : Unit = {

    val st = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").format(LocalDateTime.now)
    println(s"${st} *** Building Synthetic Dataset (Null Model + Alternate Model) <- ${nullModelPrefix} for len: ${targetLen} ***")

    seqLen = targetLen
    // crea il dataset uniform
    buildDatasetWithDistribution(numberOfPairs, seqLen, distribution, nullModelPrefix)

    // crea un altro dataset uniform per il type 1 check
    buildDatasetWithDistribution(numberOfPairs, seqLen, distribution,
        nullModelPrefix + appProperties.getProperty("powerstatistics.datasetBuilder.Type1CheckSuffix"))

    for (g <- gValues) {

      // generiamo entrambi i dataset dipendenti dal nullModel Uniform
      buildDatasetMotifReplace(seqLen, motif, g, nullModelPrefix,
        appProperties.getProperty("powerstatistics.datasetBuilder.altMotifPrefix"))

      buildDatasetPatternTransfer(seqLen, g, nullModelPrefix,
        appProperties.getProperty("powerstatistics.datasetBuilder.altPatTransfPrefix"))

    }
  }


  def semiSynthetic( nullModelPrefix: String, lengths: Array[String]) : Unit = {

    if (lengths.length > 3) {
      for (x <- lengths.drop(3)) {
        buildAlternateModelsOnly(x.toInt, nullModelPrefix)
      }
    }
    else {
      val meanValues = Array(10, 25, 50, 75)
      // numberOfPairs viene letto dalla property powerstatistics.datasetBuilder.numberOfPairs
      val maxSeqSize = appProperties.getProperty("powerstatistics.datasetBuilder.maxSequenceLength").toInt
      var bl = 10000
      while (bl <= maxSeqSize * 10) { // l'ultimo sarà il 10% del successore del maxSeqSize

        if (bl >= 1000000)
          hadoopConf.setInt("dfs.blocksize", 67108864)

        for (m <- meanValues) {
          seqLen = bl * m / 100

          if (seqLen <= maxSeqSize) {
            buildAlternateModelsOnly(seqLen: Int, nullModelPrefix)
          }
        }
        bl = bl * 10;
      }
    }
  }


  def buildAlternateModelsOnly( targetLen: Int, nullModelPrefix: String) : Unit ={

    val st = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").format(LocalDateTime.now)
    println(s"${st} *** Building Alternate Models <- ${nullModelPrefix} for len: ${targetLen} ***")

    seqLen = targetLen

    for (g <- gValues) {

      // generiamo entrambi i dataset dipendenti dal nullModel (rnd_mitocondri o rnd_shigella)
      buildDatasetMotifReplace(seqLen, motif, g, nullModelPrefix,
        appProperties.getProperty("powerstatistics.datasetBuilder.altMotifPrefix"))

      buildDatasetPatternTransfer(seqLen, g, nullModelPrefix,
        appProperties.getProperty("powerstatistics.datasetBuilder.altPatTransfPrefix"))

    }

  }


  def reinertDataset(): Unit = {

    for (j <- 1 to 8) {

      seqLen = scala.math.pow(2, j).toInt * 100
      // crea il dataset uniform

      println(s"*** Process starting for len: ${seqLen} ***")

      buildDatasetWithDistribution(numberOfPairs, seqLen, uniformDist,
        appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"))

      // genera GCRich Dataset
      buildDatasetWithDistribution(numberOfPairs, seqLen, GCReachDist,
        appProperties.getProperty("powerstatistics.datasetBuilder.GCReachPrefix"))

      for (g <- gValues) {

        buildDatasetMotifReplace(seqLen, motif, g,
          appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"),
          appProperties.getProperty("powerstatistics.datasetBuilder.altMotifPrefix"))

        buildDatasetPatternTransfer(seqLen, g,
          appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"),
          appProperties.getProperty("powerstatistics.datasetBuilder.altPatTransfPrefix"))

        buildDatasetMotifReplace(seqLen, motif, g,
          appProperties.getProperty("powerstatistics.datasetBuilder.GCReachPrefix"),
          appProperties.getProperty("powerstatistics.datasetBuilder.altMotifPrefix"))

        buildDatasetPatternTransfer(seqLen, g,
          appProperties.getProperty("powerstatistics.datasetBuilder.GCReachPrefix"),
          appProperties.getProperty("powerstatistics.datasetBuilder.altPatTransfPrefix"))
      }
    }
  }


  // This function builds the dataset as a sequence of closures evaluation ... to improve parallelism
  // n.b. useless is I/O Bounded
//  def dataset3() : Unit = {
//
//    val oom = Array(1000, 10000, 100000, 1000000, 10000000)
//    // numberOfPairs = 100 // legge dalle properties
//    savedTask = new Saver.SaveClosure()
//
//    for( bl <- oom) {
//      for (j <- -1 to 1) {
//
//        seqLen = bl + (bl * j / 10)
//
//        var p = Seq[Any](numberOfPairs, seqLen, uniformDist, appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"))
//
//        savedTask.save(buildDatasetWithDistributionEx, p)
//      }
//    }
//
//    for( bl <- oom) {
//      for (j <- -1 to 1) {
//
//        seqLen = bl + (bl * j / 10)
//        for (g <- gValues) {
//
//          // generiamo entrambi i dataset dipendenti dal nullModel Uniform
//          var p = Seq[Any]( seqLen, motif, g,
//            appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"),
//            appProperties.getProperty("powerstatistics.datasetBuilder.altMotifPrefix"))
//          savedTask.save(buildDatasetMotifReplaceEx, p)
//
//          p = Seq[Any]( seqLen, g,
//            appProperties.getProperty("powerstatistics.datasetBuilder.uniformPrefix"),
//            appProperties.getProperty("powerstatistics.datasetBuilder.altPatTransfPrefix"))
//          savedTask.save(buildDatasetPatternTransferEx, p)
//        }
//      }
//    }
//  }




  def buildDatasetWithDistribution(numberOfPairs: Int, sequenceLen: Int,
                                   distribution: Array[Double], prefix: String): Unit = {

    val seq1: Array[Char] = new Array[Char](sequenceLen)
    val seq2: Array[Char] = new Array[Char](sequenceLen)
    var st1: Array[Int] = null // Array.fill(4)(0)
    var st2: Array[Int] = null // Array.fill(4)(0)
    var n1 = 0
    var n2 = 0

    val rg = new randomNumberGenerator(distribution)

    val outputPath = getNullModelFilename( prefix, sequenceLen)

    val writer = new BufferedWriter(
      new OutputStreamWriter(FileSystem.get(URI.create(outputPath),
        new Configuration()).create(new Path(outputPath))))

    for( i <- 1 to numberOfPairs) {

      for (c <- 0 to sequenceLen - 1) {
        n1 = rg.getNextBase()
        seq1(c) = nucleotideRepr(n1)

        n2 = rg.getNextBase()
        seq2(c) = nucleotideRepr(n2)
      }

      if (debug) {
        st1 = getDistribution(seq1)
        print(s"SEQ1(${i},${prefix}): ")
        for (c <- 0 to 3)
          printf("%c=%.1f%%, ", nucleotideRepr(c), st1(c) * 100.toDouble / sequenceLen)
        println

        st2 = getDistribution(seq2)
        print(s"SEQ2(${i},${prefix}): ")
        for (c <- 0 to 3)
          printf("%c=%.1f%%, ", nucleotideRepr(c), st1(c) * 100.toDouble / sequenceLen)
        println
      }

      saveSequence( getSequenceName( prefix, i, 0.0, 1), seq1, writer)

      saveSequence( getSequenceName( prefix, i, 0.0, 2), seq2, writer)
    }
    writer.close
  }



  def buildDatasetMotifReplace(sequenceLen: Int, motif: Array[Char], probSubstitution: Double,
                               inPrefix: String, outPrefix: String): Unit = {

    val rg = new randomNumberGenerator(probSubstitution)

    var seq1: Array[Char] = new Array[Char](sequenceLen)
    var seq2: Array[Char] = new Array[Char](sequenceLen)
    var st1: Array[Int] = null // Array.fill(4)(0)
    var st2: Array[Int] = null // Array.fill(4)(0)
    var name: String = ""

    val outputPath = getAltModelFilename( outPrefix, sequenceLen, probSubstitution, inPrefix)

    val writer = new BufferedWriter(
      new OutputStreamWriter(FileSystem.get(URI.create(outputPath),
        new Configuration()).create(new Path(outputPath))))

    // codice per leggere la directory savePath
    // val files = FileSystem.get(sc.hadoopConfiguration).listStatus(new Path(savePath)).map(_.getPath().toString)
    // files.foreach(println)

    var seqHeader : String = ""
    val inputPath = getNullModelFilename(inPrefix, sequenceLen)

    var reader: BufferedSource = null

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
      val motifLen = kValueFromSeqlen(sequenceLen)

      var i = 1
      val it: Iterator[String] = reader.getLines()
      // per tutte le sequenze nel file input
      while (it.hasNext) {
        seqHeader = it.next();
        if (debug) println(s"header: ${seqHeader}")
        it.next().copyToArray(seq1)

        seqHeader = it.next();
        if (debug) println(s"header: ${seqHeader}")
        it.next().copyToArray(seq2)

        val ris = replaceMotif(seq1, seq2, motifLen, motif, rg)

        seq1 = ris._1
        seq2 = ris._2

        if (debug) {
          st1 = getDistribution(seq1)
          print(s"SEQ1(${i},${outPrefix}): ")
          for (c <- 0 to 3)
            printf("%c=%.1f%%, ", nucleotideRepr(c), st1(c) * 100.toDouble / sequenceLen)
          println

          st2 = getDistribution(seq2)
          print(s"SEQ2(${i},${outPrefix}): ")
          for (c <- 0 to 3)
            printf("%c=%.1f%%, ", nucleotideRepr(c), st1(c) * 100.toDouble / sequenceLen)
          println
        }

        saveSequence(getSequenceName(outPrefix, i, probSubstitution, 1), seq1, writer)

        saveSequence(getSequenceName(outPrefix, i, probSubstitution, 2), seq2, writer)
        i = i + 1
      }
    }
    catch {
        // Case statement-1
        case x: FileNotFoundException => {
          println(s"Exception: ${inputPath} File missing")
        }
        case x: IOException   => {
          println("Input/output Exception")
        }
    }
    reader.close
    writer.close
  }


  def replaceMotif( inputSeq1: Array[Char], inputSeq2: Array[Char], motifLen: Int, motif: Array[Char],
                    rg: randomNumberGenerator) : (Array[Char], Array[Char]) = {

    var bd: Boolean = false
    var c: Int = 0
    var cnt: Int = 0
    var k : Char = '\0'

    // Randomly selects a motif from a set of motifs to keep the number of motif replacements
    // equal to the P(gamma) * 25.000 / 5 (Reinert's dataset has MotifLength= 5 e SeqLength= 25.000)
    // val maxNumberOfMotifs : Int =  max( 1, (inputSeq1.length / (5000 * motifLen)).toInt)  // SeqLen 10.000.000 => circa 200
    val maxNumberOfMotifs : Int =  max( 1, (inputSeq1.length / 25000 ).toInt)  // SeqLen 10.000.000 => circa 200
    val motifCnt = Array.fill[Int](maxNumberOfMotifs)(0)
    var motifIndex : Int = 0

    while( c < inputSeq1.length - motifLen) {
      // distribuzione di bernoulli
      bd = rg.getNextBernoulliValue()
      if (bd) {
        // sceglie un motif a caso di lunghezza motifLen dalla sequenza motif
        motifIndex = if (maxNumberOfMotifs <= 1) 0 else rg.rng.nextInt(maxNumberOfMotifs)
        val ndx = motifIndex * motifLen
        motifCnt(motifIndex) = motifCnt(motifIndex) + 1
        // replace the characters specified by motif (c is incremented no overlap)
        for (j <- ndx to ndx + motifLen - 1) {
          k = motif(j)
          inputSeq1(c) = k
          inputSeq2(c) = k
          c = c + 1
        }
        cnt = cnt + 1
      }
      else
        c = c + 1 // jump to next base
    }
    if (debug) {
      println(s"${cnt}/${inputSeq1.length} motif substitutions from ${maxNumberOfMotifs} motifs")
      for( i <- 0 until motifCnt.length)
        println(s"${i} -> ${motifCnt(i)}")
    }

    return (inputSeq1, inputSeq2)
  }



  def buildDatasetPatternTransfer(sequenceLen: Int, probSubstitution: Double,
                                  inPrefix: String, outPrefix: String): Unit = {

    val rg = new randomNumberGenerator(probSubstitution)

    var seq1: Array[Char] = new Array[Char](sequenceLen)
    var seq2: Array[Char] = new Array[Char](sequenceLen)
    var st1: Array[Int] = null // Array.fill(4)(0)
    var st2: Array[Int] = null // Array.fill(4)(0)

    val outputPath = getAltModelFilename( outPrefix, sequenceLen, probSubstitution, inPrefix)

    val writer = new BufferedWriter(
      new OutputStreamWriter(FileSystem.get(URI.create(outputPath),
        new Configuration()).create(new Path(outputPath))))

    var seqHeader : String = ""
    val inputPath = getNullModelFilename(inPrefix, sequenceLen)

    var reader: BufferedSource = null

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

      val patternLen = kValueFromSeqlen( sequenceLen)
      var i = 1
      val it : Iterator[String] = reader.getLines()
      // per tutte le sequenze nel file input
      while (it.hasNext) {
        seqHeader = it.next();
        if (debug)  println(s"header: ${seqHeader}")
        it.next().copyToArray( seq1)

        seqHeader = it.next();
        if (debug)  println(s"header: ${seqHeader}")
        it.next().copyToArray( seq2)

        seq2 = patternTransfer(seq1, seq2, patternLen, rg)

        if (debug) {
          st1 = getDistribution(seq1)
          print(s"SEQ1(${i},${outPrefix}): ")
          for (c <- 0 to 3)
            printf("%c=%.1f%%, ", nucleotideRepr(c), st1(c) * 100.toDouble / sequenceLen)
          println

          st2 = getDistribution(seq2)
          print(s"SEQ2(${i},${outPrefix}): ")
          for (c <- 0 to 3)
            printf("%c=%.1f%%, ", nucleotideRepr(c), st1(c) * 100.toDouble / sequenceLen)
          println
        }
        saveSequence(getSequenceName( outPrefix, i, probSubstitution, 1), seq1, writer)
        saveSequence(getSequenceName( outPrefix, i, probSubstitution, 2), seq2, writer)

        i = i +1
      }
    }
    catch {
      // Case statement-1
      case x: FileNotFoundException => {
        println(s"Exception: ${inputPath} File missing")
      }
      case x: IOException   => {
        println("Input/output Exception")
      }
    }
    reader.close
    writer.close
  }



  def patternTransfer( inputSeq: Array[Char], trgtSeq: Array[Char], patternLen: Int,
                       rg: randomNumberGenerator) : Array[Char] = {

    var bd: Boolean = false
    var c: Int = 0
    var cnt: Int = 0

    while( c < trgtSeq.length - patternLen) {
      // distribuzione di bernoulli
      bd = rg.getNextBernoulliValue()
      if (bd) {
        if (debug) printf("%d, ", c)
        // replace the characters extracted from the inputSeq in the targetSeq (c is incremented no overlap)
        for (k <- 1 to patternLen) {
          trgtSeq(c) = inputSeq(c)
          c = c + 1
        }
        cnt = cnt + 1
      }
      else
        c = c + 1 // jump to next base
    }
    if (debug)  println(s"${cnt}/${trgtSeq.length} substitutions")
    return trgtSeq
  }


  def getDistribution(seq: Array[Char]) : Array[Int] = {
    var dist: Array[Int] = Array.fill(4)(0)

    for( b <- seq) {
      b match {
        case 'A' => dist(0) = dist(0) +1
        case 'C' => dist(1) = dist(1) +1
        case 'G' => dist(2) = dist(2) +1
        case 'T' => dist(3) = dist(3) +1
      }
    }
    return dist
  }



  def readSequences(prefix: String, sequenceLen: Int): ArrayBuffer[ Array[Char]] = {

    var res = ArrayBuffer[ Array[Char]]()

    var seqHeader : String = ""

    val inputPath = getNullModelFilename(prefix, sequenceLen)

    var reader: BufferedSource = null

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
    // reader.getLines.foreach( x => println( x))
    // reader.reset
    val it : Iterator[String] = reader.getLines()

    while (it.hasNext) {
      seqHeader = it.next();
      println(s"header: ${seqHeader}")
      val seq: Array[Char] = new Array[Char](sequenceLen)
      it.next().copyToArray( seq)
      res += seq
    }

    reader.close()
    return res
  }

  def saveSequence(sequenzeName: String, seq: Array[Char], writer: BufferedWriter): Unit = {

    val header = s">${sequenzeName}\n"

    writer.write( header)

    writer.write( seq.mkString)
    writer.newLine()
  }


  def getSequenceName( prefix: String, ndx: Int, g: Double, c: Int) : String = {

    val pair = if (c == 1) 'A' else 'B'
    val pg = if (g > 0) ".G=" + "%.3f".format( g).substring(2) else ""

    val name = "%s.%05d%s-%c".format(prefix, ndx, pg, pair)

    return name
  }


  def getNullModelFilename(dataSetName: String, seqLength: Int) : String = {

    val outputPath = s"${savePath}/${dataSetName}-${numberOfPairs}.${seqLength}.${fileExt}"
    return outputPath
  }

  def  getAltModelFilename(alternateModel: String, seqLength: Int, g: Double, nullModel: String) : String = {

    val pg = ".G=%.3f".format( g).replace(',','.')
    var sfx: String = null

    if (nullModel.charAt(0) == 'U')
      // from Uniform
        sfx = nullModel.substring(0,1)
      else if (nullModel.substring(0, 4).compareTo("rnd_") == 0)
        // rnd_mito e rnd_shigella ...
        sfx = nullModel.substring(4,6)
      else
        // GCReach
        sfx = nullModel.substring(0,2)

    val dataset = alternateModel + "-" + sfx

    val outputPath = s"${savePath}/${dataset}-${numberOfPairs}.${seqLength}${pg}.${fileExt}"
    return outputPath
  }


  def getMotif( motif: String) : Array[Char] = {

    val res = new Array[Char]( motif.length)
    var i = 0
    motif.foreach( c => {
      res(i) = c match {
        case 'A' | 'a' => 'A'
        case 'C' | 'c' => 'C'
        case 'G' | 'g' => 'G'
        case 'T' | 't' => 'T'
        case invChar => System.err.println(s"Wrong motif specification: ${motif} ${invChar}")
                        throw new IllegalArgumentException(s"illegal base in motif specificaton. ${invChar} ")
      }
      i = i + 1
    })
    return res
  }


  def kValueFromSeqlen( seqLen: Int) : Int = {
    //  le n sequenze hanno tutte la stessa lunghezza => somma(seqLen(i)) / n = seqLen
    val k: Int = (log10(seqLen.toDouble) / log10(4.toDouble)).ceil.toInt - 1
    return k
  }
}

object DatasetTypes extends Enumeration
{
  type DatasetType = Value

  val Uniform, GCReach, AlternateMotifReplace, AlternatePatternTransfer = Value
}
