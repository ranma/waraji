#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <inttypes.h>
#include <fcntl.h>
#include <string.h>

#define HDR_LEN 12

void dieperror(const char *msg)
{
	perror(msg);
	exit(2);
}

int main(int argc, char **argv)
{
	int infd, outfd, tmpfd;
	char *outname = "test.eep";
	uint8_t inbuf[8192-HDR_LEN];
	uint8_t outbuf[8192];
	uint16_t csum = 0;
	uint32_t nin;
	int i;

	memset(inbuf, 0, sizeof(inbuf));
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

	memcpy(&outbuf[HDR_LEN], inbuf, nin);
	/* Signature */
	outbuf[0] = 0x00;
	outbuf[1] = 0x32;
	outbuf[2] = 0x51;
	outbuf[3] = 0x04;
	/* Header size */
	outbuf[4] = HDR_LEN;
	/* Firmware version */
	outbuf[5] = 0x00;
	/* EEPROM type */
	outbuf[6] = 0x0a; /* 24C64 */
	/* Data type */
	outbuf[7] = 0x01; /* Application */
	/* Data size */
	outbuf[8] = nin & 0xff;
	outbuf[9] = nin >> 8;
	/* Data checksum */
	outbuf[10] = csum & 0xff;
	outbuf[11] = csum >> 8;

	int nw = write(outfd, outbuf, nin + HDR_LEN);
	printf("Read %d bytes, wrote %d bytes to %s, sum=%04x\n",
		 nin, nw, outname, csum);

	return 0;
}
