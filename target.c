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

#include <assert.h>
#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"
#include "target.h"

struct Target {
	struct sbuf *name;
	struct sbuf *deps;
};

struct Target *
target_new(struct sbuf *buf) {
	struct Target *target = malloc(sizeof(struct Target));
	if (target == NULL) {
		err(1, "malloc");
	}

	char *after_target = memchr(sbuf_data(buf), ':', sbuf_len(buf));
	if (after_target == NULL || after_target < sbuf_data(buf)) {
		errx(1, "invalid target: %s", sbuf_data(buf));
	}

	target->name = sbuf_dupstr(NULL);
	sbuf_bcpy(target->name, sbuf_data(buf), after_target - sbuf_data(buf));
	sbuf_trim(target->name);
	sbuf_finishx(target->name);

	target->deps = sbuf_dupstr(after_target + 1);
	sbuf_finishx(target->deps);

	return target;
}

struct sbuf *
target_name(struct Target *target)
{
	assert(target != NULL);
	return target->name;
}

