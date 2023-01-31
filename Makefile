# Copyright 2015 Google Inc. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

CH_LIB=libcursor_heap.a
CH_PATH=./cursor_heap/build
CURSOR_HEAP_LIB=$(CH_PATH)/$(CH_LIB)

CFLAGS=-std=gnu99 -g -O3 -fomit-frame-pointer -fno-unroll-loops -Wall -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wmissing-declarations -Wnested-externs -Wpointer-arith -W -Wno-unused-parameter -Werror -pthread -Wno-tautological-compare
CFLAGS+= -I ./cursor_heap
CFLAGS+= -DNON_TEMPORAL_WRITE
CFLAGS+= -DCHEAP_DAX_ALIGN_SIXTYFOUR_BYTE
LDFLAGS=-g -O3 -pthread
LDLIBS=-lrt -lm -lpmem
LDLIBS+= -L$(CH_PATH) -l cursor_heap

ARCH ?= $(shell uname -m)

ifeq ($(ARCH),aarch64)
 CAP ?= $(shell cat /proc/cpuinfo | grep atomics | head -1)
 ifneq (,$(findstring atomics,$(CAP)))
  CFLAGS+=-march=armv8.1-a+lse
 endif
endif

#TODO: convert use submodule instead of this stanza
CURSOR_HEAP_URL=https://github.com/jagalactic/cursor_heap.git
cursor_heap:
	git clone $(CURSOR_HEAP_URL)

$(CURSOR_HEAP_LIB):  cursor_heap
	mkdir -p $(CH_PATH)
	cd $(CH_PATH); cmake .. ; make

EXE=multichase multiload fairness pingpong

all: $(CURSOR_HEAP_LIB) $(EXE)

clean:
	rm -f $(EXE) *.o expand.h

.c.s:
	$(CC) $(CFLAGS) -S -c $<

multichase: multichase.o permutation.o arena.o util.o

multiload: multiload.o permutation.o arena.o util.o

fairness: LDLIBS += -lm

expand.h: gen_expand
	./gen_expand 200 >expand.h.tmp
	mv expand.h.tmp expand.h

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

# DO NOT DELETE

arena.o: arena.h
multichase.o: cpu_util.h timer.h expand.h permutation.h arena.h util.h
multiload.o: cpu_util.h timer.h expand.h permutation.h arena.h util.h
permutation.o: permutation.h
util.o: util.h
fairness.o: cpu_util.h expand.h timer.h
pingpong.o: cpu_util.h timer.h
