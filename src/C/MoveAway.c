
#include <stdio.h>
#include <libgen.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <unistd.h>





int main(int argc, char *argv[]) {

  char outFile[1000], *inputFile, ext[100] = "";
  char *dirc, *basec, *bname, *dname;
  int theta;
    
  if (argc != 3) {
    printf("Errore nei parametri:\nUsage: %s InputSequence thetaProbability", argv[0]);
    exit(-1);
  }
  inputFile = argv[1];
  theta = atoi(argv[2]);

  dirc = strdup(inputFile);
  basec = strdup(inputFile);
  dname = dirname(dirc);
  bname = basename(basec);

  char * p = rindex(inputFile, '.');
  if (p != NULL)
    strcpy( ext, p);

  printf("ext:%s\n", ext);

  bname[strlen(bname)-strlen(ext)] = '\0';
  printf("basename:%s\n", bname);  
  sprintf(outFile, "%s/%s-%02d%s", dname, bname, theta, ext);

  printf( "*********************************************************\n");
  printf( "Creating sequence: %s from sequence: %s theta: %d\n", outFile, bname, theta);
  printf( "*********************************************************\n");
    
  long written = 0, subst = 0, totLen = 0;
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

  while((nr = fread(bufin, (size_t) 1, bufDim, fi)) > 0) {
      
      po = bufout;
      for( pi = bufin, i = 0; i < nr; i++, pi++) {
      
	char c = toupper(*pi);
	if ((random() % 100) < theta) {
	  
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
          
      if (fwrite( bufout, (size_t) 1, nr, fo) < 0) {
	fprintf(stderr, "Errore di scrittura nel file di output\n");
	perror("errore di scrittura");
	exit(-1);
      }
      totLen += nr;
      write(1, ".", 1);                        
    } // while !eof

  printf("\n%s -> %ld/%ld substitutions\n", outFile, subst, totLen);
}
