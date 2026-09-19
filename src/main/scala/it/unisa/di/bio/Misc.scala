//
// $Id: Misc.scala 1618 2020-03-10 17:01:51Z cattaneo@dia.unisa.it $
//


package it.unisa.di.bio



package object Misc {

  val nucleotideRepr = new Array[Char](4) //char representation of nucleotides
  nucleotideRepr(0) = 'A'
  nucleotideRepr(1) = 'C'
  nucleotideRepr(2) = 'G'
  nucleotideRepr(3) = 'T'

  object nucleotide extends Enumeration
  {
    type nucleotide = Value

    // Assigning values
    val a = Value('A')
    val c = Value('C')
    val g = Value('G')
    val t = Value('T')
  }

  // Generate nucleotides according to a given probaibility distribution
  class randomNumberGenerator() {

    // initialize the random source
    var rng: scala.util.Random = null

    var gValue: Double = 0.0

    // precompute the boundaries for the probabilities (must be 0 <= boundiries < 1.0
    val boundaries: Array[Double] = Array(0.0, 0.0, 0.0, 1.0)

    def this( randomSource: scala.util.Random, probG: Double) {
      this()
      rng =  randomSource
      gValue = probG
    }

    def this (randomSource: scala.util.Random, probabilityDistribution: Array[Double]) = {
      this()
      rng = randomSource
      initRandomSource(probabilityDistribution)
    }

    // non usare altrimenti il generatore viene riinizializzato e compromette la replicabilità del processo.
    private def this (probabilityDistribution: Array[Double]) = {
      this()
      rng =  new scala.util.Random(System.currentTimeMillis / 1000)
      initRandomSource(probabilityDistribution)
    }

    private def initRandomSource(probabilityDistribution: Array[Double]) : Unit = {
      var tot: Double = 0
      for(i <- 0 to 2) {
        tot += probabilityDistribution(i)
        boundaries(i) = tot
      }
    }

    def getNextBase() : Int = {
      val v = rng.nextDouble()  // 0 <= v < 1.0
      if (v < boundaries(0))
        return 0
      else if (v < boundaries(1))
        return 1
      else if (v < boundaries(2))
        return 2
      else
        return 3
    }

    def getNextBernoulliValue() : Boolean = {
      val v = rng.nextDouble()
      return if (v < gValue) true else false
    }
  }

}
