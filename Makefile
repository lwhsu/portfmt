LIBNAME=	libportfmt

include Makefile.configure

MKDIR?=		mkdir -p
LN?=		ln

CFLAGS+=	-std=gnu99 -I.
LDADD+=		${LIBDL} -lm

OBJS=		array.o compats.o conditional.o diff.o diffutil.o mainutils.o \
		map.o parser.o parser/plugin.o portscanlog.o regexp.o rules.o \
		set.o target.o token.o util.o variable.o
PLUGINS=	parser/plugin.edit.bump-revision.${LIBSUFFIX} \
		parser/plugin.edit.merge.${LIBSUFFIX} \
		parser/plugin.edit.set-version.${LIBSUFFIX} \
		parser/plugin.kakoune.select-object-on-line.${LIBSUFFIX} \
		parser/plugin.lint.clones.${LIBSUFFIX} \
		parser/plugin.lint.order.${LIBSUFFIX} \
		parser/plugin.output.unknown-targets.${LIBSUFFIX} \
		parser/plugin.output.unknown-variables.${LIBSUFFIX} \
		parser/plugin.output.variable-value.${LIBSUFFIX} \
		parser/plugin.refactor.collapse-adjacent-variables.${LIBSUFFIX} \
		parser/plugin.refactor.dedup-tokens.${LIBSUFFIX} \
		parser/plugin.refactor.remove-consecutive-empty-lines.${LIBSUFFIX} \
		parser/plugin.refactor.sanitize-append-modifier.${LIBSUFFIX} \
		parser/plugin.refactor.sanitize-cmake-args.${LIBSUFFIX} \
		parser/plugin.refactor.sanitize-comments.${LIBSUFFIX} \
		parser/plugin.refactor.sanitize-eol-comments.${LIBSUFFIX}

.SUFFIXES: .${LIBSUFFIX}

all: portclippy portedit portfmt portscan ${PLUGINS}

.c.o:
	${CC} ${CPPFLAGS} -fPIC ${CFLAGS} -o $@ -c $<

.o.${LIBSUFFIX}: ${LIBNAME}.${LIBSUFFIX}
	${CC} ${LDFLAGS} ${PLUGIN_LDFLAGS} -o $@ $< ${LIBNAME}.${LIBSUFFIX}

${LIBNAME}.${LIBSUFFIX}: ${OBJS}
	${CC} ${LDFLAGS} ${SHARED_LDFLAGS} -o ${LIBNAME}.${LIBSUFFIX} ${OBJS} \
		${LDADD}

portclippy: ${LIBNAME}.${LIBSUFFIX} portclippy.o
	${CC} ${LDFLAGS} -o portclippy portclippy.o ${LIBNAME}.${LIBSUFFIX}

portedit: ${LIBNAME}.${LIBSUFFIX} portedit.o
	${CC} ${LDFLAGS} -o portedit portedit.o ${LIBNAME}.${LIBSUFFIX}

portfmt: ${LIBNAME}.${LIBSUFFIX} portfmt.o
	${CC} ${LDFLAGS} -o portfmt portfmt.o ${LIBNAME}.${LIBSUFFIX}

portscan: ${LIBNAME}.${LIBSUFFIX} portscan.o
	${CC} ${LDFLAGS} -o portscan portscan.o -lpthread ${LIBNAME}.${LIBSUFFIX}

portclippy.o: portclippy.c config.h mainutils.h parser.h parser/plugin.h
	${CC} ${CPPFLAGS} ${CFLAGS} -o $@ -c $<

portedit.o: portedit.c config.h array.h mainutils.h parser.h parser/plugin.h regexp.h set.h util.h
	${CC} ${CPPFLAGS} ${CFLAGS} -o $@ -c $<

portfmt.o: portfmt.c config.h mainutils.h parser.h parser/plugin.h
	${CC} ${CPPFLAGS} ${CFLAGS} -o $@ -c $<

portscan.o: portscan.c config.h array.h conditional.h diff.h mainutils.h parser.h parser/plugin.h portscanlog.h regexp.h set.h token.h util.h
	${CC} ${CPPFLAGS} ${CFLAGS} -o $@ -c $<

array.o: config.h array.h diff.h util.h
conditional.o: config.h conditional.h regexp.h rules.h util.h
diff.o: config.h diff.h
diffutil.o: config.h array.h diff.h diffutil.h util.h
mainutils.o: config.h array.h mainutils.h parser.h util.h
map.o: config.h array.h map.h util.h
parser.o: config.h array.h conditional.h diffutil.h parser.h parser/constants.c parser/plugin.h regexp.h rules.h set.h target.h token.h util.h variable.h
parser/plugin.o: config.h parser.h parser/plugin.h util.h
parser/plugin.edit.bump-revision.o: config.h array.h parser.h parser/plugin.h rules.h token.h util.h variable.h
parser/plugin.edit.merge.o: config.h array.h parser.h parser/plugin.h rules.h token.h util.h variable.h
parser/plugin.edit-set-version.o: config.h array.h parser.h parser/plugin.h rules.h token.h util.h variable.h
parser/plugin.kakoune.select-object-on-line.o: config.h array.h parser.h parser/plugin.h token.h util.h
parser/plugin.lint.clones.o: config.h array.h conditional.h parser.h parser/plugin.h set.h token.h util.h variable.h
parser/plugin.lint.order.o: config.h array.h conditional.h diff.h parser.h parser/plugin.h rules.h target.h token.h util.h variable.h
parser/plugin.output.unknown-targets.o: config.h array.h parser.h parser/plugin.h rules.h set.h target.h token.h util.h
parser/plugin.output.unknown-variables.o: config.h array.h parser.h parser/plugin.h rules.h set.h token.h util.h variable.h
parser/plugin.output.variable-value.o: config.h array.h parser.h parser/plugin.h token.h util.h variable.h
parser/plugin.refactor.collapse-adjacent-variables.o: config.h array.h parser.h parser/plugin.h set.h token.h util.h variable.h
parser/plugin.refactor.dedup-tokens.o: config.h array.h parser.h parser/plugin.h set.h token.h util.h variable.h
parser/plugin.refactor.sanitize-append-modifier.o: config.h array.h parser.h parser/plugin.h rules.h set.h token.h variable.h
parser/plugin.refactor.sanitize-cmake-args.o: config.h array.h parser.h parser/plugin.h rules.h token.h util.h variable.h
parser/plugin.refactor.sanitize-comments.o: config.h array.h parser.h parser/plugin.h token.h util.h
parser/plugin.refactor.sanitize-eol-comments.o: config.h array.h parser.h parser/plugin.h rules.h token.h util.h variable.h
portscanlog.o: config.h array.h diff.h portscanlog.h set.h util.h
regexp.o: config.h regexp.h util.h
rules.o: config.h array.h conditional.h parser.h regexp.h rules.h set.h token.h util.h variable.h generated_rules.c
set.o: config.h array.h map.h set.h util.h
target.o: config.h target.h util.h
token.o: config.h conditional.h target.h token.h util.h variable.h
util.o: config.h array.h util.h
variable.o: config.h regexp.h rules.h util.h variable.h

install:
	${MKDIR} ${DESTDIR}${BINDIR} ${DESTDIR}${LIBDIR}/portfmt ${DESTDIR}${MANDIR}/man1
	${INSTALL_MAN} man/*.1 ${DESTDIR}${MANDIR}/man1
	${INSTALL_PROGRAM} portclippy portedit portfmt portscan ${DESTDIR}${BINDIR}
	${INSTALL_LIB} ${LIBNAME}.${LIBSUFFIX} ${DESTDIR}${LIBDIR}
	${INSTALL_LIB} ${PLUGINS} ${DESTDIR}${LIBDIR}/portfmt

install-symlinks:
	@${MAKE} INSTALL_LIB="install -l as" INSTALL_MAN="install -l as" \
		INSTALL_PROGRAM="install -l as" INSTALL_SCRIPT="install -l as" \
		install

regen-rules:
	@/bin/sh generate_rules.sh

clean:
	@rm -f ${OBJS} ${PLUGINS} parser/*.o *.o libportfmt.${LIBSUFFIX} portclippy portedit portfmt \
		portscan config.*.old

debug:
	@${MAKE} CFLAGS="-Wall -std=c99 -O1 -g -fno-omit-frame-pointer" \
		LDFLAGS="-g" portfmt

test: all
	@/bin/sh run-tests.sh

.PHONY: clean debug install install-symlinks regen-rules test
