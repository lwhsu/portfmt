/*-
 * SPDX-License-Identifier: BSD-2-Clause-FreeBSD
 *
 * Copyright (c) 2019 Tobias Kortkamp <tobik@FreeBSD.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "config.h"

#if HAVE_CAPSICUM
# include <sys/capsicum.h>
# include "capsicum_helpers.h"
#endif
#if HAVE_ERR
# include <err.h>
#endif
#include <fcntl.h>
#define _WITH_GETLINE
#include <stdio.h>
#include <stdlib.h>
#include <sysexits.h>

#include "parser.h"

static void usage(void);

static int WRAPCOL = 80;
static int TARGET_COMMAND_FORMAT_WRAPCOL = 65;
static int TARGET_COMMAND_FORMAT_THRESHOLD = 8;

void
usage()
{
	fprintf(stderr, "usage: portfmt [-a] [-i] [-u] [-w wrapcol] [Makefile]\n");
	exit(EX_USAGE);
}

int
main(int argc, char *argv[])
{
	enum ParserBehavior behavior = PARSER_COLLAPSE_ADJACENT_VARIABLES | PARSER_OUTPUT_REFORMAT | PARSER_FORMAT_TARGET_COMMANDS;
	int fd_in = STDIN_FILENO;
	int fd_out = STDOUT_FILENO;
	int dflag = 0;
	int iflag = 0;
	int ch;
	while ((ch = getopt(argc, argv, "adiuw:")) != -1) {
		switch (ch) {
		case 'a':
			behavior |= PARSER_SANITIZE_APPEND;
			break;
		case 'd':
			dflag = 1;
			break;
		case 'i':
			iflag = 1;
			break;
		case 'u':
			behavior |= PARSER_UNSORTED_VARIABLES;
			break;
		case 'w': {
			const char *errstr = NULL;
			WRAPCOL = strtonum(optarg, -1, INT_MAX, &errstr);
			if (errstr != NULL) {
				errx(1, "strtonum: %s", errstr);
			}
			break;
		} default:
			usage();
		}
	}
	argc -= optind;
	argv += optind;

	if (dflag) {
		iflag = 0;
	}

	if (argc > 1 || (iflag && argc == 0)) {
		usage();
	} else if (argc == 1) {
		fd_in = open(argv[0], iflag ? O_RDWR : O_RDONLY);
		if (fd_in < 0) {
			err(1, "open");
		}
		if (iflag) {
			fd_out = fd_in;
			close(STDIN_FILENO);
			close(STDOUT_FILENO);
		}
	}

#if HAVE_CAPSICUM
	if (iflag) {
		if (caph_limit_stream(fd_in, CAPH_READ | CAPH_WRITE | CAPH_FTRUNCATE) < 0) {
			err(1, "caph_limit_stream");
		}
		if (caph_limit_stderr() < 0) {
			err(1, "caph_limit_stderr");
		}
	} else {
		if (caph_limit_stdio() < 0) {
			err(1, "caph_limit_stdio");
		}
	}

	if (caph_enter() < 0) {
		err(1, "caph_enter");
	}
#endif
#if HAVE_PLEDGE
	if (pledge("stdio", NULL) == -1) {
		err(1, "pledge");
	}
#endif

	struct Parser *parser = parser_new(behavior);
	if (parser == NULL) {
		err(1, "calloc");
	}

	ssize_t linelen;
	size_t linecap = 0;
	char *line = NULL;
	FILE *fp = fdopen(fd_in, "r");
	if (fp == NULL) {
		err(1, "fdopen");
	}
	while ((linelen = getline(&line, &linecap, fp)) > 0) {
		line[linelen - 1] = 0;
		parser_read(parser, line);
	}
	parser_read_finish(parser);

	if (dflag) {
		parser_dump_tokens(parser);
	} else {
		parser_output_generate(parser);

		if (iflag) {
			if (lseek(fd_out, 0, SEEK_SET) < 0) {
				err(1, "lseek");
			}
			if (ftruncate(fd_out, 0) < 0) {
				err(1, "ftruncate");
			}
		}
		parser_output_write(parser, fd_out);
	}

	close(fd_out);
	close(fd_in);

	free(line);
	parser_free(parser);

	return 0;
}
