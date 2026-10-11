from pyspark.sql import SparkSession
from pyspark import SparkFiles
import py_kmc_api

spark = SparkSession.builder \
    .appName("KMCtoHDFS") \
    .getOrCreate()

sc = spark.sparkContext

##############################################
# soluzione scartata ... lentissima e poco efficace
##############################################

# Percorsi
kmc_db_prefix = "/home/cattaneo/kmers/sample_k101"  # senza .kmc_*
hdfs_output = "/data/kmers/sample_k101_spark"

# Distribuisci i file del DB KMC ai worker (se non sono già su FS condiviso)
# Assumiamo che .kmc_pre e .kmc_suf siano nello stesso dir
sc.addFile(kmc_db_prefix + ".kmc_pre")
sc.addFile(kmc_db_prefix + ".kmc_suf")

def iter_kmers(_):
    # Dentro ogni executor
    import py_kmc_api
    import os

    # Nome base del DB (senza path, perché addFile lo mette in working dir)
    db_name = os.path.basename(kmc_db_prefix)

    kmc = py_kmc_api.CKMCFile()
    if not kmc.OpenForReading(db_name, ""):
        raise RuntimeError(f"Cannot open KMC DB {db_name}")

    info = kmc.Info()
    kmc.GetInfo(info)

    # Itera su tutti i k-mer
    kmc_iter = py_kmc_api.CKMCFileIterator()
    kmc.InitIterator(kmc_iter)

    kmer_bytes = bytearray(info.kmer_len)
    count = py_kmc_api.uint64()

    while kmc.Next(kmc_iter, kmer_bytes, count):
        kmer_str = bytes(kmer_bytes).decode("ascii")
        yield (kmer_str, int(count))

    kmc.Close()

# RDD di (kmer, count)
kmers_rdd = sc.mapPartitions(iter_kmers)

# Scrivi su HDFS in formato testo: "ACGT...\t123"
kmers_rdd.map(lambda t: f"{t[0]}\t{t[1]}") \
         .saveAsTextFile(hdfs_output)

spark.stop()
