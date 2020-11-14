#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <inttypes.h>
#include <fcntl.h>
#include <string.h>

void dieperror(const char *msg)
{
	perror(msg);
	exit(2);
}

int main(int argc, char **argv)
{
	int infd, outfd, tmpfd;
	char *outname = "test.eep";
	uint8_t inbuf[8192-3];
	uint8_t outbuf[8192];
	uint8_t csum = 0;
	uint32_t nin;
	int i;

	memset(outbuf, 0xff, sizeof(outbuf));

	if (argc < 2) {
		printf("Usage: %s infile [outfile]\n", argv[0]);
		exit(1);
	}

	infd = open(argv[1], O_RDONLY);
	if (infd == -1)
		dieperror(argv[1]);

	if (argc > 2)
		outname = argv[2];

	outfd = open(outname, O_WRONLY|O_CREAT, 0644);
	if (outfd == -1)
		dieperror(outname);

	nin = read(infd, inbuf, sizeof(inbuf));

	for (i=0; i<nin; i++)
		csum += inbuf[i];

	memcpy(&outbuf[2], inbuf, nin);
	outbuf[0] = (nin+1) >> 8;
	outbuf[1] = (nin+1);
	outbuf[nin + 2] = 256-csum;

	int nw = write(outfd, outbuf, sizeof(outbuf));
	printf("Read %d bytes, wrote %d bytes to %s, sum=%02x -csum=%02x\n",
		 nin, nw, outname, csum, 256-csum);

	return 0;
}
