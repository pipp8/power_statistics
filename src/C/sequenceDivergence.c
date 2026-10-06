#include <stdio.h>
#include <libgen.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <limits.h>


unsigned int hash_string(const char *s) {
    unsigned int h = 5381;
    while (*s) {
        h = ((h << 5) + h) + (unsigned char)*s++;
    }
    return h;
}


unsigned int make_seed(const char *filename, float x) {
    unsigned int h1 = hash_string(filename);
    unsigned int h2 = x * 0xAAA777;

    unsigned int h3 = (unsigned int) (((long) h1 * (long) h2) & 0xFFFFFFFF);

    // printf("h2 = 0x%X, x = %f, h1 = 0x%X, h3 = 0x%X \n", h2, x, h1, h3);

    // return h1 ^ (h2 + 0x9e3779b9u + (h1 << 6) + (h1 >> 2));
    return h3;
}


int main(int argc, char *argv[]) {

  char outFile[1000], *inputFile, ext[100] = "";
  char *dirc, *basec, *bname, *dname;
  double theta;
    
  if (argc != 3) {
    printf("Errore nei parametri:\nUsage: %s InputSequence thetaProbability\n", argv[0]);
    exit(-1);
  }

  inputFile = argv[1];
  theta = atof(argv[2]);

  struct stat sb;
  char buf[PATH_MAX];
  ssize_t nb;


  if (lstat(inputFile, &sb) == -1) {
    perror("lstat");
    return 1;
  }

  if (S_ISLNK(sb.st_mode)) {

    if ((nb = readlink(inputFile, buf, sizeof(buf) - 1)) == -1) {
        perror("readlink");
        return 1;
    }

    buf[nb] = '\0';
    printf("%s is a symbolic link, using %s instead\n", inputFile, buf);
    inputFile = buf;
  }

  dirc = strdup(inputFile);
  basec = strdup(inputFile);
  dname = dirname(dirc);
  bname = basename(basec);
  
  unsigned int seed = make_seed(bname, theta);
  printf("basename: %s, theta: %f, seed: 0x%X\n", bname, theta, seed);
  srandom(seed);


  char * p = rindex(inputFile, '.');
  if (p != NULL)
    strcpy( ext, p);

  printf("ext:%s\n", ext);

  bname[strlen(bname)-strlen(ext)] = '\0';
  printf("basename:%s\n", bname);  
  sprintf(outFile, "%s/%s-T=%.3f%s", dname, bname, theta, ext);

  struct stat stat1, stat2;

  if (stat( inputFile, &stat1) < 0) {
    fprintf(stderr, "Input file %s not available\nExiting.\n", inputFile);
    exit(-1);
  }
  
  if ((stat( outFile, &stat2) == 0) && (stat2.st_size == stat1.st_size)) {
    fprintf(stderr, "Output file %s is already present and has the same size: %lld byte\nSkipping.\n", outFile, stat1.st_size);
    exit(0);
  }

  off_t expectedSize = stat1.st_size;
  
  printf( "*********************************************************\n");
  printf( "Creating sequence: %s from sequence: %s theta: %.3f\n", outFile, bname, theta);
  printf( "*********************************************************\n\n");
    
  long subst = 0, totLen = 0;
  char n, *pi, *po;
  FILE *fo, *fi;
  size_t bufDim = 1048576; // 1 Mb
  int  nr, i;
  
  if ((fo = fopen(outFile, "w")) == NULL) {
    fprintf(stderr, "Opening output file: %s\n", outFile);
    exit(-1);
  }

  if ((fi = fopen(inputFile, "rb")) == NULL) {
    fprintf(stderr, "Opening input file: %s\n", inputFile);
    exit(-1);
  }

  char * bufin = malloc( bufDim);

  if (bufin == NULL) {
    fprintf(stderr, "Errore di allocazione memoria\n");
    exit(-2);
  }

  char * bufout = malloc( bufDim);

  if (bufout == NULL) {
    fprintf(stderr, "Errore di allocazione memoria\n");
    exit(-2);
  }

  int t2 = theta * 1000; // 0.005 -> 5, 0.05 -> 50, 0.5 -> 500
  while((nr = fread(bufin, (size_t) 1, bufDim, fi)) > 0) {
      
      po = bufout;
      for( pi = bufin, i = 0; i < nr; i++, pi++) {
      
	char c = toupper(*pi);
	if ((random() % 1000) < t2) {
	  
	  int j = random() % 3;
	  
	  switch ( c) {
	  case 'A':
	    n = "CGT"[j];
	    break;
	    
       	  case 'C':
	    n = "AGT"[j];
	    break;
	    
	  case 'G':
	    n = "ACT"[j];
	    break;
	    
	  case 'T':
	    n = "ACG"[j];
	    break;
	    
	  default:
	    n = c;  // altri caratteri 'N' o fine linea
	    subst--;
	    break;
	  }
	  subst++;
	}
	else {
	  n = c;  // lascia lo stesso carattere
	}
	*po = n;
	po++;
      } // chiude il for
          
      if (fwrite( bufout, (size_t) 1, nr, fo) == 0) {
	fprintf(stderr, "Errore di scrittura nel file di output\n");
	perror("errore di scrittura");
	exit(-1);
      }
      totLen += nr;
      printf("%ld / %lld\r", totLen, expectedSize);
    } // while !eof

  printf("\n%s -> %'ld/%'ld substitutions\n", outFile, subst, totLen);
}
